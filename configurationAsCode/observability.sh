#!/bin/bash
set -e
#Because its to heavy for terraform to perfom these steps. 
#This script is used for AKS provisioning regarding to the observability exercises
AKSNAME="${TF_VAR_labname}aks"
COUNTMAX="${TF_VAR_labNumberParticipants}"

if [ -z "$TF_VAR_labname" ] ;
then
    echo "environmentname is unset" ;
    exit 1;
fi

( 
set -x
#first set aks creds:
az aks get-credentials -g ${TF_VAR_labname} -n $AKSNAME

# in each covered namespace, what should be checked via plain TCP connect (port must be stated!)
BLACKBOX_TCP='
    todoui:8090
    todobackend:8080
    postgresdb:5432
'

# which dashboards should be added to Grafana
declare -A DASHBOARDS
DASHBOARDS['ocelot-self']='https://grafana.com/api/dashboards/10140/revisions/6/download'            # https://grafana.com/grafana/dashboards/10140/revisions
DASHBOARDS['ocelot-jvm']='https://grafana.com/api/dashboards/9598/revisions/4/download'              # https://grafana.com/grafana/dashboards/9598/revisions
DASHBOARDS['ocelot-gc']='https://grafana.com/api/dashboards/12162/revisions/2/download'              # https://grafana.com/grafana/dashboards/12162/revisions
DASHBOARDS['ocelot-http']='https://grafana.com/api/dashboards/10138/revisions/3/download'            # https://grafana.com/grafana/dashboards/10138/revisions
DASHBOARDS['ocelot-service']='https://grafana.com/api/dashboards/10139/revisions/4/download'         # https://grafana.com/grafana/dashboards/10139/revisions
DASHBOARDS['postgres-database']='https://grafana.com/api/dashboards/9628/revisions/5/download'       # https://grafana.com/grafana/dashboards/9628/revisions
DASHBOARDS['alerts-overview']='https://grafana.com/api/dashboards/4181/revisions/2/download'         # https://grafana.com/grafana/dashboards/4181/revisions
DASHBOARDS['alertmanager']='https://grafana.com/api/dashboards/9578/revisions/4/download'            # https://grafana.com/grafana/dashboards/9578/revisions
DASHBOARDS['jaeger']='https://grafana.com/api/dashboards/10001/revisions/2/download'                 # https://grafana.com/grafana/dashboards/10001/revisions
DASHBOARDS['k8s-storage']='https://grafana.com/api/dashboards/11455/revisions/6/download'            # https://grafana.com/grafana/dashboards/11455/revisions
DASHBOARDS['node-exporter-full']='https://grafana.com/api/dashboards/1860/revisions/21/download'     # https://grafana.com/grafana/dashboards/1860/revisions
DASHBOARDS['blackbox']='https://grafana.com/api/dashboards/5345/revisions/3/download'                # https://grafana.com/grafana/dashboards/5345/revisions
# jmx-overview https://grafana.com/grafana/dashboards/3457 # defaults to job='jmx' and metrics as scraped from https://github.com/prometheus/jmx_exporter
# jmx-prometheus-exporter https://grafana.com/grafana/dashboards/7727 # same as above for metrics


# Stuff for prometheus

KUBERNETES_SERVERVERSION="$(kubectl version -o json | jq '.serverVersion')"
MAJOR="$(echo "$KUBERNETES_SERVERVERSION" | jq '.major' | tr -d '"')"
MINOR="$(echo "$KUBERNETES_SERVERVERSION" | jq '.minor' | tr -d '"')"

echo "Comparing cluster to https://github.com/prometheus-operator/kube-prometheus#kubernetes-compatibility-matrix ..."
if [[ "$MAJOR" -eq 1 ]] && [[ "$MINOR" -ge 20 ]] && [[ "$MINOR" -le 21 ]]; then
    echo "Compatible, now continuing ..."
else
    echo "ERROR: cluster version incompatible: $KUBERNETES_SERVERVERSION"
    echo "You first need to adjust the kube-prometheus release and retest, so exiting now."
    exit 1
fi

rm -rf kube-prometheus
# heed https://github.com/prometheus-operator/kube-prometheus#kubernetes-compatibility-matrix
git clone --branch release-0.8 https://github.com/prometheus-operator/kube-prometheus
cd kube-prometheus

# prometheus-operator needs more memory in bigger setups
sed -i -e 's#memory: 200Mi#memory: 800Mi#' -e 's#memory: 100Mi#memory: 400Mi#' manifests/setup/prometheus-operator-deployment.yaml
# uses its own namespace "monitoring", first creating the base structures; --force might be required during upgrades
kubectl apply --force -f manifests/setup/

# wait until CRD are fully in place
until kubectl get servicemonitors --all-namespaces ; do sleep 1; date; done

# ad-hoc limit resource usage at the cost of availability
sed -i -e 's#^  replicas: .*#  replicas: 1#' manifests/prometheus-prometheus.yaml
# default retention is only 24h (set to "h" as alertmanager doesn't know "d")
sed -i -e 's#^  replicas: .*$#\0\n  retention: "336h"#' manifests/alertmanager-alertmanager.yaml manifests/prometheus-prometheus.yaml
# persist storage ad-hoc (alternatively Thanos could be used, as utilizing the PVC requires extended privileges)
sed -i -e 's#^  retention: .*$#\0\n  storage:\n    volumeClaimTemplate:\n      apiVersion: "v1"\n      kind: "PersistentVolumeClaim"\n      spec:\n        accessModes: ["ReadWriteOnce"]\n        resources: { requests: { storage: "20Gi" } }#' manifests/prometheus-prometheus.yaml
sed -i -e 's#^    runAsNonRoot: .*#    runAsNonRoot: false#' -e 's#^    runAsUser: .*#    runAsUser: 0\n    runAsGroup: 0#' manifests/prometheus-prometheus.yaml
# provide additional scrape configuration (later used for blackbox and various statically listed exporters)
sed -i -e 's#^  alerting:$#  additionalScrapeConfigs:\n    key: prometheus-additional.yaml\n    name: additional-scrape-configs\n\0#' manifests/prometheus-prometheus.yaml
# some additional alerting rules
cat ../observability/prometheus-rules.yaml >> manifests/prometheus-rules.yaml
# ad-hoc remove rules that won't make sense in our context
sed -i -e '/^  - name: kubernetes-system-scheduler$/,+23d' manifests/kubernetes-prometheusRule.yaml
# change alert grouping
sed -z -i -e 's#      "group_by":\n      - "namespace"#      "group_by":\n      - "alertname"\n      - "cluster"\n      - "service"#' manifests/alertmanager-secret.yaml
# needs more resources in bigger setups
sed -i -e 's#cpu: ...m#cpu: 500m#' -e 's#cpu: .0m#cpu: 100m#' manifests/node-exporter-daemonset.yaml
# adjust blackbox exporter config
cat <<.EOF > manifests/blackbox-exporter-configuration.yaml.modules
      "kube-api":
        "http":
          "method": "GET"
          "no_follow_redirects": false
          "preferred_ip_protocol": "ip4"
          "tls_config":
            "insecure_skip_verify": false
            "ca_file": "/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
          "bearer_token_file": "/var/run/secrets/kubernetes.io/serviceaccount/token"
          "valid_http_versions":
          - "HTTP/2.0"
          "valid_status_codes": []
        "prober": "http"
        "timeout": "5s"
.EOF
sed -i -e '/^    "modules":$/r manifests/blackbox-exporter-configuration.yaml.modules' manifests/blackbox-exporter-configuration.yaml
# Grafana base config
# ad-hoc ensure all referenced plugins are present, cf. https://github.com/prometheus-operator/kube-prometheus/issues/305, hardcode sdg for now
sed -i -e 's#^        name: grafana$#\0\n        env:\n        - name: GF_INSTALL_PLUGINS\n          value: "grafana-piechart-panel,novatec-sdg-panel 2.3.0"#' manifests/grafana-deployment.yaml
# no information disclosure
sed -i -e 's#^        - name: GF_INSTALL_PLUGINS$#        - name: GF_ANALYTICS_REPORTING_ENABLED\n          value: "false"\n\0#' manifests/grafana-deployment.yaml
# needs more resources in bigger setups
sed -i -e 's#cpu: .00m#cpu: 500m#' -e 's#memory: 200Mi#memory: 400Mi#' -e 's#memory: 100Mi#memory: 200Mi#' manifests/grafana-deployment.yaml

# ad-hoc add some dashboards
for key in "${!DASHBOARDS[@]}"; do
    echo "$key : ${DASHBOARDS[$key]}"
    sed -i \
        -e "s#^        - mountPath: /grafana-dashboard-definitions/0/apiserver\$#        - mountPath: /grafana-dashboard-definitions/0/$key\n          name: grafana-dashboard-$key\n          readOnly: false\n\0#" \
        -e "s#^        name: grafana-dashboard-workload-total\$#\0\n      - configMap:\n          name: grafana-dashboard-$key\n        name: grafana-dashboard-$key#" \
        manifests/grafana-deployment.yaml
    # override some Ocelot dashboards to provide versions that allow filtering by namespace
    FILENAME="../observability/$key.json"
    if ! [ -f "$FILENAME" ]; then
        FILENAME="$key.json"
        curl --silent "${DASHBOARDS[$key]}" | \
            sed \
            -e 's#\${DS_PROMETHEUS}#prometheus#g' \
            -e 's#\${DS_PROMETHEUS-APL}#prometheus#g' \
            -e 's#\${DS_LOCALPROMETHEUS}#prometheus#g' \
            -e 's#\${DS_PRODUCTION-AU}#prometheus#g' \
            > $FILENAME
        # fix panel reference in service dashboard
        [ "$key" = 'ocelot-service' ] && sed -i -e 's#"version": "2.0"#"version": "2.3.0"#' -e 's#"novatec-service-dependency-graph-panel"#"novatec-sdg-panel"#' $FILENAME
    fi
    if [ "$key" = 'node-exporter-full' ] || [ "$key" = 'alertmanager' ]; then
        # The ConfigMap "grafana-dashboard-..." is invalid: metadata.annotations: Too long: must have at most 262144 bytes
        kubectl get configmap --namespace monitoring grafana-dashboard-$key > /dev/null 2>&1 && \
            kubectl create configmap --namespace monitoring grafana-dashboard-$key --from-file=$FILENAME --dry-run=client -o yaml | kubectl replace -f - || \
            kubectl create configmap --namespace monitoring grafana-dashboard-$key --from-file=$FILENAME
    else
        kubectl create configmap --namespace monitoring grafana-dashboard-$key --from-file=$FILENAME --dry-run=client -o yaml | kubectl apply -f -
    fi
done

# now setting up the actual default monitoring; --force might be required during upgrades
kubectl apply --force -f manifests/
cd -


# per-namespace adjustments
for ((i = 0 ; i < ${COUNTMAX} ; i++)); do
    echo "VM#: $i"
    #RBAC: per default only the following namespaces will be enabled for ServiceMonitor usage: default, kube-system, monitoring
    kubectl -n ${TF_VAR_labname}-vm-${i}-ns apply -f observability/rbac.yaml
    # collect the items in this namespace that should be covered by blackbox monitoring
    for item in $BLACKBOX_TCP; do
        BLACKBOX_TCP_FILL+=" $(echo "$item" | sed -e "s#:#.${TF_VAR_labname}-vm-${i}-ns:#")"
    done
done # per-namespace adjustments


#ElasticSearch Stuff

# uses its own namespace "elastic-system"
kubectl apply -f https://download.elastic.co/downloads/eck/1.2.1/all-in-one.yaml
kubectl apply -f observability/elasticsearch.yaml
until kubectl get elasticsearch exercises --namespace logging | grep --quiet Ready ; do sleep 1; date; done

#install kibana
kubectl apply -f observability/kibana.yaml
until kubectl get kibana exercises --namespace logging | grep --quiet green ; do sleep 1; date; done

#install fluentd deamonset:
ELASTICPASSWORD=$(kubectl get secret --namespace logging exercises-es-elastic-user --output go-template='{{.data.elastic | base64decode}}')
sed -e "s#ELASTICPASSWORD#$ELASTICPASSWORD#" observability/fluentd.yaml | kubectl apply -f -

kubectl patch svc exercises-kb-http -p '{"spec": {"ports": [{"port": 5601,"targetPort": 5601,"name": "kibana"}],"type": "LoadBalancer"}}' --namespace logging
until kubectl get svc --namespace logging exercises-kb-http -o jsonpath="{.status.loadBalancer.ingress[0].ip}" | grep -v --silent pending ; do sleep 1; date; done
IP=$(kubectl get svc --namespace logging exercises-kb-http -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
sleep 40
curl --user "elastic:$ELASTICPASSWORD" --insecure "https://$IP:5601/api/saved_objects/index-pattern/exercises" --header 'kbn-xsrf: true' --header 'Content-Type: application/json' --data "@$SYSTEM_DEFAULTWORKINGDIRECTORY/_infrastructure/configurationAsCode/data/indexpattern.json" 


#install jaeger standalone:
kubectl apply -n monitoring -f observability/jaeger.yaml


PROMETHEUS_ADDITIONAL="$(
    {
        cat observability/prometheus-additional.yaml
        cat observability/prometheus-additional-blackbox-tcp.yaml
        for i in $BLACKBOX_TCP_FILL; do
            echo "    - $i"
        done
    } | base64 -w0
)"
cat << EOF | kubectl --namespace=monitoring apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: additional-scrape-configs
type: Opaque
data:
  prometheus-additional.yaml: $PROMETHEUS_ADDITIONAL
EOF


status=$?
    [ $status -eq 0 ] && echo "Provision for observability in AKS run successful" || exit $status
)

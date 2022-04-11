#!/bin/bash
set -e
#Because its to heavy for terraform to perfom these steps. 
#This script is used for AKS provisioning regarding to the servicemeshes exercises
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
sudo curl --silent --location https://github.com/linkerd/linkerd2/releases/download/stable-2.10.2/linkerd2-cli-stable-2.10.2-linux-amd64 --output /usr/local/bin/linkerd
sudo chmod +x /usr/local/bin/linkerd
linkerd version
if linkerd check --pre; then
    linkerd install | kubectl apply -f -
    linkerd check --wait 15m0s
    linkerd viz install | kubectl apply -f -
else
    echo "WARNING: Skipping linkerd install due to failed pre check. This might mean linkerd was already installed in the cluster, or something else, so please investigate by yourself."
fi
linkerd check --wait 15m0s

kubectl get deployments --namespace ingress-nginx -o yaml | linkerd inject --ingress - | kubectl apply -f -
kubectl get deployments --namespace traefik-v2 -o yaml | linkerd inject --ingress - | kubectl apply -f -

#prepare istio in version 1.7.0
 wget https://github.com/istio/istio/releases/download/1.7.0/istioctl-1.7.0-linux-amd64.tar.gz
 tar xzvpf istioctl-1.7.0-linux-amd64.tar.gz 
 sudo mv istioctl /usr/local/bin


istioctl install --set profile=default --set meshConfig.accessLogFile=/dev/stdout
# install add-ons (there may be some timing issues which will be resolved when the command is run again)
kubectl apply -f https://raw.githubusercontent.com/istio/istio/1.7.0/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/1.7.0/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/1.7.0/samples/addons/jaeger.yaml

kubectl apply -f https://raw.githubusercontent.com/istio/istio/1.7.0/samples/addons/kiali.yaml ||:
sleep 60
kubectl apply -f https://raw.githubusercontent.com/istio/istio/1.7.0/samples/addons/kiali.yaml 


#RBAC:
echo "we need to extend perms with cluster-roles of service from all vms"

for ((i = 0 ; i < ${COUNTMAX} ; i++)); do
  echo "VM#: $i"

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ${TF_VAR_labname}-vm-${i}-cluster-role
rules:
- apiGroups: ["", "extensions","apps","autoscaling","batch","apiextensions.k8s.io","acid.zalan.do","elasticsearch.k8s.elastic.co","kibana.k8s.elastic.co","metrics.k8s.io","linkerd.io","tap.linkerd.io","networking.istio.io","security.istio.io","rbac.authorization.k8s.io","admissionregistration.k8s.io","policy","apiregistration.k8s.io","monitoring.coreos.com"]
  resources: ["*"]
  verbs: ["get", "list", "watch","create","patch"]
EOF

done


status=$?
    [ $status -eq 0 ] && echo "Provision for servicemeshes in AKS run successful" || exit $status
)

#!/bin/bash
set -e

# this script requires reading SPIs & other secrets before running
# for example: tenant_id and Azure-Service-Principal can be read from Azure KeyVault
# a read task exposes that secrets as environment variable during the pipeline run
# they are set via "bash task environment variable parameter"
# if you want to run this script locally, please run prepareTerraform.sh

if [ -z "$TF_VAR_labname" ]; then
  echo "environmentname is unset"
  exit 1
fi

(
  set -x

  AKSNAME="${TF_VAR_labname}aks"

  az aks get-credentials -g ${TF_VAR_labname} -n $AKSNAME

  echo "Configure Kubectl in Participant Pods"

  kubectl get pods

  echo "Testing Sysbox-Daemonset"
  until kubectl get daemonsets sysbox-deploy-k8s -n kube-system -o jsonpath="{.status.numberReady}" | grep -v --silent 0; do
    kubectl describe daemonsets sysbox-deploy-k8s -n kube-system
    kubectl get daemonsets sysbox-deploy-k8s -n kube-system

    date
    echo "No Worker-Node with Sysbox-Daemonset ready. Waiting 30s"
    sleep 30
  done
  echo "Testing Sysbox-Daemonset Success"

  echo "Testing Participant-Pod"
  until kubectl get statefulSets $TF_VAR_participantPodName -o jsonpath="{.status.readyReplicas}" | grep -q $TF_VAR_labNumberParticipants; do
    kubectl get statefulSets $TF_VAR_participantPodName -o jsonpath="{.status.readyReplicas}" | grep -v 0
    kubectl get pods

    date
    echo "Not all Participant-Pod are ready. Waiting 10s"
    sleep 10
  done
  echo "Testing Participant-Pod Success"

  echo "Configure Participant-Pod"

  USER_NOVATEC_DIR=home/$TF_VAR_participantPodDockerUser
  USER_ROOT_DIR=/root

  CONTEXT="$(kubectl config current-context)"
  printf "$CONTEXT \n"

  CLUSTER_NAME="$(kubectl config get-contexts "$CONTEXT" | awk '{print $3}' | tail -n 1)"
  printf "$CLUSTER_NAME \n"

  ENDPOINT="$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")"
  printf "$ENDPOINT \n"

  for ((c = 0; c < $TF_VAR_labNumberParticipants; c++)); do
    echo "Iteration: $c"

    printf "\nInnerhalb des Pods '$TF_VAR_participantPodName-$c' das Kubernetes Cluster konfigurieren, sodass der Pod über kubectl darauf zugreifen kann... \n"

    SERVICE_ACCOUNT_NAME=$TF_VAR_participantPodNamespaceName-$c-sa
    printf "$SERVICE_ACCOUNT_NAME \n"

    NAMESPACE=$TF_VAR_participantPodNamespaceName-$c
    printf "$NAMESPACE \n"

    SECRET_NAME="$(kubectl get sa $SERVICE_ACCOUNT_NAME --namespace=$NAMESPACE -o json | jq -r .secrets[].name)"
    printf "$SECRET_NAME \n"

    kubectl get secret --namespace=$NAMESPACE $SECRET_NAME -o json | jq -r '.data["ca.crt"]' | base64 -di > participant-pod/ca$c.crt

    USER_TOKEN="$(kubectl get secret --namespace $NAMESPACE $SECRET_NAME -o json | jq -r '.data["token"]' | base64 -di)"
    printf "$USER_TOKEN \n"


    kubectl cp participant-pod/ca$c.crt $TF_VAR_participantPodName-$c:$USER_ROOT_DIR

    rm participant-pod/ca$c.crt

    kubectl cp participant-pod/example-deployments $TF_VAR_participantPodName-$c:$USER_ROOT_DIR
    kubectl cp participant-pod/configs/.bashrc $TF_VAR_participantPodName-$c:$USER_ROOT_DIR


    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(kubectl config set-cluster "${CLUSTER_NAME}" --server="${ENDPOINT}" --certificate-authority="${USER_ROOT_DIR}/ca${c}".crt --embed-certs=true)"

    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(kubectl config set-credentials "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" --token="${USER_TOKEN}")"

    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(kubectl config set-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" --cluster="${CLUSTER_NAME}" --user="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" --namespace="${NAMESPACE}")"

    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(kubectl config use-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}")"

    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(echo  $'\nKUBECONFIG=${USER_ROOT_DIR}/.kube/config' >> "${USER_ROOT_DIR}"/.bashrc)"

    echo "Configure Novatec-User \n"

    kubectl cp participant-pod/example-deployments $TF_VAR_participantPodName-$c:$USER_NOVATEC_DIR
    kubectl cp participant-pod/configs/.bash_profile $TF_VAR_participantPodName-$c:$USER_NOVATEC_DIR
    kubectl cp participant-pod/configs/.bashrc $TF_VAR_participantPodName-$c:$USER_NOVATEC_DIR


    # Change PW of Novatec-User
    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(echo "${TF_VAR_participantPodDockerUser}:${TF_VAR_sshUserPw}" | chpasswd)"

    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(mkdir -p ${USER_NOVATEC_DIR}/.kube)"
    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(cp -r "${USER_ROOT_DIR}"/.kube/config "${USER_NOVATEC_DIR}"/.kube)"
    # kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(chown -R $TF_VAR_participantPodDockerUser "${USER_NOVATEC_DIR}"/.kube/)"

    kubectl exec -it $TF_VAR_participantPodName-$c -- bash -c "(echo  $'\nKUBECONFIG=${USER_NOVATEC_DIR}/.kube/config' >> "${USER_NOVATEC_DIR}/.bashrc")"

  done

  status=$?
  [ $status -eq 0 ] && echo "Provision run successful" || exit $status
)

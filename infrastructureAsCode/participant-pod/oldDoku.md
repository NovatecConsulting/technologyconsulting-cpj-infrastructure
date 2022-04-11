# Setup AKS Cluster

- Run Release New Pipeline


## Kubeconfig setzen für AKS Cluster für lokalen Zugriff
- `az login`

az aks get-credentials --resource-group dra --name draaks

alias k=kubectl


df -hT

## Sysbox Setup
[Sysbox Setup Guide](https://github.com/nestybox/sysbox/blob/master/docs/user-guide/install-k8s.md)

[PVC Blog](https://blog.nestybox.com/2022/01/03/dink.html#kubernetes-cluster-creation)

- `kubectl get nodes -o wide`

- `kubectl label nodes ($worker-node-name) sysbox-install=yes`
- `kubectl label nodes aks-drapool-17646914-vmss000000 sysbox-install=yes`

- `kubectl apply -f https://github.com/nestybox/sysbox/blob/master/sysbox-k8s-manifests/sysbox-install.yaml`
- `kubectl delete -f https://github.com/nestybox/sysbox/blob/master/sysbox-k8s-manifests/sysbox-install.yaml`

- `k get nodes -o wide`

- `kubectl get daemonsets sysbox-deploy-k8s -n kube-system`

- `kubectl describe daemonsets sysbox-deploy-k8s -n kube-system`

## RBAC konfigurieren und Pods starten
- `./rbac-config.sh`
<!-- - `delete/delete-rbac-config.sh` -->



<!-- ## Checken ob alle Pods laufen 

- `kubectl get nodes -o wide -w`

- `kubectl get pods -o wide -w`

- `kubectl describe pod teilnehmer-pod-statefulset-0`

- `kubectl describe pod teilnehmer-pod-statefulset-1`

- `kubectl get pv`

- `kubectl exec teilnehmer-pod-statefulset-0 -- ps`

- `kubectl exec teilnehmer-pod-statefulset-0 -- docker ps`

- `kubectl exec teilnehmer-pod-statefulset-0 -- cat /proc/self/uid_map`

- `kubectl exec teilnehmer-pod-statefulset-1 -- ps`

- `kubectl exec teilnehmer-pod-statefulset-1 -- docker ps`

- `kubectl exec teilnehmer-pod-statefulset-1 -- cat /proc/self/uid_map`

- `kubectl get svc -o wide -w` -->

<!-- - `kubectl exec -it teilnehmer-pod-statefulset-0 -- passwd` -->




## Pods Konfigurieren
- `./loop-pod-config.sh`
## Pods Testen
- `./loop-pod-test.sh`


## Connect to pod
- `ssh root@20.103.102.98`

## Troubleshooting
- `kubectl delete pvc docker-cache-teilnehmer-pod-statefulset-0`
- `kubectl delete pvc docker-cache-teilnehmer-pod-statefulset-1`

k delete pvc pod-storage-participant-pod-statefulset-0 && k delete pvc pod-storage-participant-pod-statefulset-1 &&  k delete pvc pod-storage-participant-pod-statefulset-2 &&  k delete pvc pod-storage-participant-pod-statefulset-3

helm delete sysbox 
helm install sysbox sysbox/


k exec -it  sysbox-deploy-k8s-mb9bg --namespace kube-system -- bash -c "df -H"

helm delete participantpod 

helm install participantpod helm/participantPod/ --set statefulSet.replicas=4

helm install participantpod helm/participantPod/ --set statefulSet.replicas=2

k exec -it participant-pod-statefulset-0 -- bash 

cd ~/.kube/config


${HOME}/.kube/config
KUBECONFIG=${HOME}/.kube/config



k exec -it participant-pod-statefulset-0 -- bash -c "echo "KUBECONFIG=/root/.kube/config" >> .bashrc"
k exec -it participant-pod-statefulset-1 -- bash -c "echo "alias k=kubectl" >> /root/.bashrc"

kubectl exec -it participant-pod-statefulset-1 -- bash -c "(echo "KUBECONFIG=/root/.kube/config" >> "/root/.bashrc")"
kubectl exec -it participant-pod-statefulset-1 -- bash -c "(echo "alias k=kubectl" >> "/root/.bashrc")"


k exec -it participant-pod-statefulset-0 -- bash 

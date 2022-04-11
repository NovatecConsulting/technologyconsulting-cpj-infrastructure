


az aks get-credentials --resource-group dra --name draaks

alias k=kubectl 

kubectl get daemonsets sysbox-deploy-k8s -n kube-system
kubectl describe daemonsets sysbox-deploy-k8s -n kube-system



k describe pod participant-pod-statefulset-0
k describe pvc pod-storage-participant-pod-statefulset-0


helm install sysbox helm/sysbox
helm delete sysbox

helm install participants helm/participants
helm delete participants


k get pods 
k get svc 
k get pvc

k delete pvc --all 
k delete pods --all 
k delete svc --all 

ssh novatec@20.103.103.246

echo "test" > /root/test.txt

cat /root/test.txt

echo "test" > /mnt/azure/test.txt

cat /mnt/azure/test.txt

k exec -it participant-pod-statefulset-0 -- bash

k exec -it participant-pod-statefulset-0 -- bash -c "(docker ps)"
k exec -it participant-pod-statefulset-0 -- bash -c "(docker run nginx -d)"

k exec -it participant-pod-statefulset-0 -- bash -c "(cat /root/example-deployments)"


kubectl cp participant-pod/example-deployments participant-pod-statefulset-0:/root


kubectl exec -it participant-pod-statefulset-0 -- cat /proc/self/uid_map

kubectl exec -it participant-pod-statefulset-0 -- docker ps 



k exec -it participant-pod-statefulset-0 -- bash -c "(echo 'Hallo' > /root/test.txt)"
k exec -it participant-pod-statefulset-0 -- bash -c "(echo 'Hallo' > /home/novatec/test.txt)"
k exec -it participant-pod-statefulset-0 -- bash -c "(echo 'Hallo' > /var/lib/docker/test.txt)"

k exec -it participant-pod-statefulset-0 -- bash -c "(cat /root/test.txt)"
k exec -it participant-pod-statefulset-0 -- bash -c "(cat /home/novatec/test.txt)"
k exec -it participant-pod-statefulset-0 -- bash -c "(cat /var/lib/docker/test.txt)"

k exec -it nginx -- sh -c "(echo 'Hallo' > /mnt/azure/test.txt)"
k exec -it nginx -- sh -c "(cat /mnt/azure/test.txt)"



kubectl debug node/aks-drapool-68534607-vmss000000 -it --image=mcr.microsoft.com/dotnet/runtime-deps:6.0

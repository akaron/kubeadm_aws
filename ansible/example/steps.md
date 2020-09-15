Replace the `k8s.apicat.xyz` to your own domain (also check the yaml files before you run)
# nginx ingress controller
(already done in ansible script)
```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-0.32.0/deploy/static/provider/aws/deploy.yaml
```

# rancher
```
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo add jetstack https://charts.jetstack.io
helm repo update

kubectl create namespace cert-manager
kubectl apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.crds.yaml
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v0.15.0
kubectl get pods --namespace cert-manager

kubectl create namespace cattle-system
helm install rancher rancher-stable/rancher --namespace cattle-system --set hostname=rancher.k8s.apicat.xyz

kubectl -n cattle-system rollout status deploy/rancher
```

note: still need to manually add a route 53 record

# hello-world example

## use nodePort
```
kubectl create deployment hello --image=rancher/hello-world
kubectl expose deployment hello --type=NodePort --port 80
```
make sure the corresponding port is open in EC2 security group for nodes.

## use ingress
Alternatively, use `kubectl apply -f hello.yml` which include an ingress rule. Need to manually add
route53 record for `hello.k8s.apicat.xyz` (alias to the NLB bound to ingress-nginx-controller).

# jenkins (auto-provision storage in EBS)
(haven't try the persistent storage part, should use EFS instead)
```
helm install myjenkins -f ./jenkins-values.yml --set persistence.storageClass=kops-ssd-1-17 stable/jenkins
```
or, create storageClass, PVC, then
```
helm install myjenkins -f ./jenkins-values.yml --set persistence.existingClaim=PVC_NAME stable/jenkins
```


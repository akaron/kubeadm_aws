Here I use the hosted domain name `k8s.apicat.xyz`, change it to your own domain (in yaml
files and also in the commands or descriptions below).

Add helm repo and update repo if not yet
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo update
```

# Deploy Prometheus (with storage in LocalPath of VM)
```
kubectl create -f prometheus-pvc.yaml
helm install prometheus stable/prometheus --version 11.12.0 -f prometheus-values.yaml
kubectl create -f prometheus-ingress.yml
```

For test purpose, can also use prometheus without persistent storage:
- skip the step to create the PVC
- turn off `persistentVolumes` in the `prometheus-values.yaml`

After deploy the `ingress` resource, need go to aws route 53 console, add a record for
`prometheus.k8s.apicat.xyz`, alias to the NLB of the ingress-nginx-controller.


# Install Grafana
```
kubectl create -f grafana-configmaps.yaml
kubectl create -f grafana-deployment.yaml
kubectl create -f grafana-ingress.yml
```

Again, similar to prometheus, need to manually add an aws route 53 record in the hosted
zone. The record is `grafana.k8s.apicat.xyz`. Open the address in browser. The default
user/password is `admin/admin`.  In grafana, there should have a data source point to
prometheus-server and a simple dash-board.

# clean up
```
kubectl delete -f prometheus-ingress.yml
helm uninstall prometheus
# kubectl delete -f prometheus-pvc.yaml
kubectl delete -f grafana-configmaps.yaml
kubectl delete -f grafana-deployment.yaml
kubectl delete -f grafana-ingress.yml
```

If you want to keep the prometheus data, don't remove the PVC as shown above.
Both route53 records also need to remove manually.


# notes
* an alternative way to install prometheus: https://github.com/prometheus-operator/kube-prometheus
* The helm chart
  - the default values for the helm chart is in
    https://github.com/helm/charts/blob/master/stable/prometheus/values.yaml .

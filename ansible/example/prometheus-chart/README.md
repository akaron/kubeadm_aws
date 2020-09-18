Here I use the hosted domain name `apicat.xyz`, change it to your own domain (in yaml
files and also in the commands or descriptions below).

Add helm repo and update repo if not yet
```
helm repo add stable https://kubernetes-charts.storage.googleapis.com
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

# Deploy Prometheus with persistentStorage and TLS/HTTPS
```
sh ./gen_cert.sh
kubectl create -f prometheus-pvc.yaml
helm install prometheus prometheus-community/prometheus -f /vagrant/ansible/example/prometheus-chart/prometheus-values.yaml
kubectl create -f prometheus-ingress.yml
```

For test purpose, can also use prometheus without persistent storage:
- skip the step to create the PVC
- turn off `persistentVolumes` in the `prometheus-values.yaml`

After deploy the `ingress` resource, need go to aws route 53 console, add a record for
`prometheus.apicat.xyz`, alias to the NLB of the ingress-nginx-controller.

Open the address in browser. And should able to use prometheus, for instance, to check
the cpu usage of each node, one may use something like:
`100 - (avg by (instance)(rate(node_cpu_seconds_total{mode="idle"}[5m])))*100`



# Install Grafana
```
kubectl create -f grafana-configmaps.yaml
kubectl create -f grafana-deployment.yaml
kubectl create -f grafana-ingress.yml
```

Again, similar to prometheus, need to manually add an aws route 53 record in the hosted
zone. The record is `grafana.apicat.xyz`. Open the address in browser. The default
user/password is `admin/admin`.  In grafana, there should have a data source point to
prometheus-server and a simple dash-board.

# clean up
```
kubectl delete -f grafana-ingress.yml
kubectl delete -f grafana-deployment.yaml
kubectl delete -f grafana-configmaps.yaml
kubectl delete -f prometheus-ingress.yml
helm uninstall prometheus
# kubectl delete -f prometheus-pvc.yaml
```

If you want to remove the prometheus data in the persistent storage, uncomment the last
line above. Both route53 records also need to remove manually.


# notes
* an alternative way to install prometheus: https://github.com/prometheus-operator/kube-prometheus
* The helm chart
  - the default values for the helm chart is in
    https://github.com/helm/charts/blob/master/stable/prometheus/values.yaml .
* Not sure if which is a better way to check pending deployments/pods:
  - `avg by (deployment)(kube_deployment_status_condition{status="false"} == 1)`
  - `kube_pod_status_unschedulable`
  - To test, create a deployment which cannot be scheduled. For instance, add a
    `nodeSelector` in `../hello.yml` (same depth as container)
```
      nodeSelector:
        iops: five
```

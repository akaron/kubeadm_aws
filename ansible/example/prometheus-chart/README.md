# Prerequisites
* deploy `cert-manager` as shown in `../cert-manager/steps.md`
  - assume the cert-manager is deployed with the Issuer `letsencrypt-staging`

Note that I use the hosted domain name `apicat.xyz` while deploying the cert-manager and
in this tutorial, change it to your domain (in yaml files and also in the commands or
descriptions below).

# Prepare
Add helm repo and update repo if not yet
```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
```

# Deploy Prometheus with persistentStorage and TLS/HTTPS
```
kubectl create -f prometheus-pvc.yaml
helm install prometheus prometheus-community/prometheus -f /vagrant/ansible/example/prometheus-chart/prometheus-values.yaml
```

For test purpose, can also use prometheus without persistent storage:
- skip the step to create the PVC
- turn off `persistentVolumes` in the `prometheus-values.yaml`

> NOTE: this will expose prometheus.apicat.xyz to public which is not a good idea in production environment.
> You can skip this part and use grafana (password protected) instead. Or `kubectl proxy ...`.

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

## without cert-manager
Note that if don't use cert-manager and want to generate and use self-signed cert,
need to generate a secret use a script like below
```
export KEY_FILE=my-prometheus.key
export CERT_FILE=my-prometheus.cert
export CERT_NAME=prometheus-tls
export HOST=prometheus.apicat.xyz
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout ${KEY_FILE} -out ${CERT_FILE} -subj "/CN=${HOST}/O=${HOST}"
kubectl create secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE}
```
and remove following line in `prometheus-values.yml` (in `annotations`)
```
      cert-manager.io/issuer: "letsencrypt-staging"
```

For Grafana it's similar. Remove the `issuer` annotation in the kind `Ingress` and upload
or reuse a certification.


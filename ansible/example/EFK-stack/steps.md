Mainly follow https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes

With these updates/differences:
* change image versions (as of 2020 Sep 21) and `storageClass`
* Since here I manage the k8s cluster inside a VM managed by Vagrant, sometimes need to
  port-forward again in order for host browser to see the apps.

# Elasticsearch
```
kubectl create -f kube-logging.yml
kubectl create -f elasticsearch_svc.yml
kubectl create -f elasticsearch_statefulset.yml
kubectl rollout status sts/es-cluster -n kube-logging
```

To see if it works, port-forward then check the service
```
kubectl port-forward es-cluster-0 9200:9200 --namespace=kube-logging &
curl localhost:9200
```
Remember to kill the background job.

## Kibana
```
kubectl create -f kibana.yml
kubectl rollout status deployment/kibana --namespace=kube-logging
```

To test, port-forward remote 5601 to local 5601 (listen to local), then to localhost 9090
which listen to all

```
export kibana_pod=$(kubectl get pods -n kube-logging -l 'app=kibana' -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward ${kibana_pod} 5601:5601 --namespace=kube-logging &
socat TCP4-LISTEN:9090,fork TCP4:localhost:5601 &
```

Then in the browser of host, open `http://localhost:9090`. At this point should see a
'Welcome page'.  Still need to add `fluentd` to collect data. After finish, can keep this
port-forwardings open.

Note that the local port `5601` and `9090` are our choice. Port `9090` is the port opened
from VM (provisioned by Vagrant) to host machine. It is defined in `Vagrantfile`.

# fluentd
```
kubectl create -f fluentd.yml
```
To test, port-forward kibana pod (again).

# Test
In the Kibana app, roughly follow these steps: open left panel, `Discover`,
`Create Index Pattern`, input `logstash-*`, select `@timestamp`, hit `Create Index Pattern`

# TLS support
Assume the cert-manager is deployed with the Issuer "letsencrypt-staging" (see `../cert-manager`).
Update the host/hosts in `kibana-ingress.yml`, then run
```
kubectl create -f kibana-ingress.yml
```
And in aws route53 console, add the corrsponding record which points to the NLB.

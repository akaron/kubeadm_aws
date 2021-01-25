# Install metrics server

> Alternatively, install metrics server using helm chart https://artifacthub.io/packages/helm/metrics-server/metrics-server
> If you install promethus by helm (as shown in `ansible/example/prometheus-chart/README.md`)
> then the metrics-server is already installed through helm.

See https://github.com/kubernetes-sigs/metrics-server

```
wget https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.4.1/components.yaml
```

Add one line in the `components.yaml` in the `Deployment` block, in `spec.template.spec.containers.args`, add this line:
```
        - --kubelet-insecure-tls
```

Then
```
kubectl apply -f components.yaml
```

And wait until the metrics server is ready
```
watch kubectl get pods -n kube-system $(kubectl get pods -l k8s-app=metrics-server -n kube-system  -o jsonpath='{.items[0].metadata.name}')
```

# Test Horizontal Pod Autoscaling (HPA)
Follow instructions here https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

```
kubectl apply -f https://k8s.io/examples/application/php-apache.yaml
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

Open a new terminal and watch the status
```
watch kubectl get hpa,pods
```

Back to previous terminal and increase load
```
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"
```

Wait a few minutes and should able to see the load is increasing to over 50% and new pods
are generated.  Press `CTRL-C` to stop the loading. After 5 minutes of no loading (the
default grace period), the pods are terminated by hpa.

## Autoscaling on multiple metrics and custom metrics
See https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/#autoscaling-on-multiple-metrics-and-custom-metrics

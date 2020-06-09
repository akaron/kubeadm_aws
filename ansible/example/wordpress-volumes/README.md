First need to update the mount point of EFS in wordpress-web.yml.
(will use terraform or ansible template to do that)

Them, roughly follow this order 
```
kubectl create -f pv-claim.yml
kubectl create -f wordpress-secrets.yml
kubectl create -f wordpress-db.yml
kubectl create -f wordpress-db-service.yml 
kubectl create -f wordpress-web.yml
kubectl create -f wordpress-web-service.yml
kubectl create -f ingress.yml
```

then in aws route 53 console, add an record for `wp.k8s.optract.space`, alias to the NLB
of the ingress-nginx-controller.


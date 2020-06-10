First need to generate aws EFS.

Copy the `efs.tf` to `../../../terraform`, then run `terraform apply` there.  The output
of the script include the EFS mount point (the dns name). The name also export to
`../../vars/wp.yml`. Replace the value to the nsf server in `wordpress-web.yml` (in the
last few lines).

Then, roughly follow this order to deploy in k8s cluster:
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


Steps mainly from https://cert-manager.io/docs/installation/kubernetes/ and https://cert-manager.io/docs/tutorials/acme/ingress/

Since we already install ingress-nginx-controller, we only need these steps to
install cert-manager:

```
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.0.1 \
  --set installCRDs=true
```

# create letsencrypt issuers
Next step is to create two issuers for letsencrypt staging and letsencrypt production. For
test purpose can deploy the issuer for staging. 

Need to replace the email `user@example.com` to your email address. To edit and deploy in
one line:

```
kubectl create --edit -f issuer-staging.yml
kubectl create --edit -f issuer-prod.yml
```


# Example to deploy an app

The Ingress of an app should look like:
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "nginx"
    cert-manager.io/issuer: "letsencrypt-staging"

spec:
  tls:
  - hosts:
    - example.example.com
    secretName: quickstart-example-tls
  rules:
  - host: example.example.com
    http:
      paths:
      - path: /
        backend:
          serviceName: kuard
          servicePort: 80
```

In the fields:
* `cert-manager.io/issuer: "letsencrypt-staging"` is the name of `issuer`
* update the `hosts` for your app
* choose a name for the certificate (here use `quickstart-example-tls`).

Once applied, to check the status using
```
kubectl get secret,certificate,order,challenge
```
And `kubectl describe` to check the status

# use production environment (of letsencrypt issuer)
(haven't try)
If nothing's wrong:
* In Ingress, change the issuser from `letsencrypt-staging` to `letsencrypt-prod` and
  apply again
* delete the secret: `kubectl delete secret quickstart-example-tls`
  - The cert-manager is watching the secret, once it's removed, it will reprocess the
    request with the updated issuer.

# notes

## DNS SERVFAIL error

At first time I use something like `k8s.example.com` in the aws route 53 hosted zone.
Somehow letsencrypt complaines (from `kubectl describe challenge ...`):

```
cert-manager DNS problem: SERVFAIL looking up CAA for ...
```

Looks like its a mistake about DNS but I don't know how to fix it (I use a domain name
from namecheap.com). In the end I simply replace `k8s.example.com` to `example.com` then
avoid this issue.

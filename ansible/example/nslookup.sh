# can also try external hosts, such as www.google.com
kubectl run -it busybox --image=busybox:1.28 --rm --restart=Never -- nslookup kubernetes.default

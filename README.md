This is a test to deploy kubernetes (k8s) cluster in aws using kubeadm.

It utilize **terraform** to deploy infrastructures in aws, then use **ansible** to run
configurations scripts for the first controlplane (master node), the other controlplanes,
worker nodes, local machine, and deploy essential components for the k8s cluster.


# Prerequisites
* aws account, aws credentials in local machine, and a hosted zone in aws route53
  - such as add `k8s.example.com` to route53, if you own `example.com`; the API server
    of the k8s cluster will be `api.k8s.example.com` (point to a Load Balancer)
  - remember to add the aws NS records back to the domain name register
* terraform (`>0.12`) and ansible installed


# Steps
1. use terraform to build the infrastructure in aws (VPC, auto-scaling group, Load
   Balancer, ...)
2. use ansible scripts to bootstrap the first controlplane node, the other controlplane
   nodes if any, and then the worker nodes

## Terraform
Steps:
```
cd terraform
cp terraform.tfvars.ex terraform.tfvars
# fill in all items and change default values in tettaform.tfvars
terraform init
terraform plan
terraform apply
```

Note that need to fill in all fields in `terraform.tfvars`.

It usually take a few minutes for `terrafor apply` to finish.  An inventory file is
exported to the `ansible` directory, which include all the public ip address of instances.


## Ansible
The EC2 instances are initialized with bootstrap scripts (see `terraform/cloudinit.tf`).
But it require more settings for k8s cluster.

First cd into the `ansible` directory, install required pacages, and add the ssh
fingerprints of these hosts to local machine

```
cd ../ansible
ansible-playbook -i inventory 00-local-ssh-keyscan.yml
ansible-playbook -i inventory 10-local-packages.yml
```

Then make sure the nodes are deployed successfully:
```
ansible-playbook -i inventory 10-all-verify-cloudinit-result.yml
```

If no problem, create the cluster
```
ansible-playbook -i inventory 20-cp1-kubeadm_init-playbook.yml
ansible-playbook -i inventory 25-local-cni-storageClass-ingress.yml
ansible-playbook -i inventory 25-cp-kubeadm_join-playbook.yml
ansible-playbook -i inventory 30-worker-join-playbook.yml
export KUBECONFIG=`pwd`/kubeconfig.yml
```

* playbook `20-cp1-kubeadm_init-playbook.yml` creates `kubeadm init` on the first
  controlplane and copy token, cert, and kubeconfig to local machine
* playbook `25-local-cni-storageClass-ingress.yml` creates container network interface
  (cni), `storageClass`, and `nginx-ingress` controller. This step creates a Network
  Load Balancer in AWS.
* playbook `25-cp-kubeadm_join-playbook.yml` joins the second and third controlplanes to
  the cluster
* playbook `30-worker-join-playbook.yml` joins the worker nodes to the cluster
* set the environment variable to tell local kubectl to connect to that cluster

Note that by default there's only one node for controlplane and thus there's no need to
run the `25-cp-kubeadm_join-playbook.yml`. It won't do anything if there's no other
controlplanes. In practice one should use 3 or more controlplane nodes. See more in
"reduce cost" and "autoscaling group" later.

At this point, wait a few minutes until everything is running and ready:
```
watch kubectl get nodes,pods -A
```

## reduce cost
If only plan to run a few simple tests and want to reduce cost in aws, one may:

* In `terraform.tfvars`: use `t3.small` or `t3a.small` for instances
* In `asg-controlplane.tf` and `asg-worker.tf`: reduce the `max_size` and `min_size` to
  smaller values
  - also need to modify the template file `inventory.tmpl`, basically just increase or
    decrease lines for each increaed/decreased node in the `controlplane` block or the
    `worker` block
  - note: by default there's only one controlplane

## examples
See detail in `ansible/example/steps.md`, here show a couple examples to test the cluster.

First make sure the internal network and dns works, which contain only one line (see
`nslookup.sh`):
```
kubectl run -it busybox --image=busybox:1.28 --rm --restart=Never -- nslookup kubernetes.default
```

The `hello.yml` uses the ingress controller. You need to modify the dns name in the file
before deploy. Once deployed `hello.yml`, you also need to add a route 53 record in aws
console (such as `hello.k8s.example.com`). The record point the dns name to the load
balancer controled by ingress controller. Usually after a few minutes, you can access to
the dns name from your own browser.


## Autoscaling group
At this deployment, there are two aws autoscaling group (asg), one for controlplane nodes
and the other for worker nodes.

To improve the HA, a good starting point for HA is to have 3 nodes for each asg group. One
reason is that `etcd` need odd number of nodes to avoid `split brain`. The other reason is
that in most case there are 3-4 available zones (AZs) in each aws region, and asg spreads
nodes to different AZ.

If a node is down, asg should able to automatically brought up another one.  But the new
node cannot join the cluster automatically, need to do these manually (note: one can use
aws SNS to receive notifications via email)

To re-join a worker node (say, `worker2` in the inventory file is replaced by a new one),
run:
```
cd terraform; terraform plan; terraform apply
cd ../ansible
ansible-playbook -i inventory 30-worker-join-playbook --limit worker2
```
The `--limit worker2` is optional. The `worker2` is the new node and should change to
appropriate value.

For controlplane group, need to update the certificate (use the script in the task "Get
the certificate for other controlplane..." in `20-cp1-kubeadm_init-playbook.yml`, and copy
the result to `ansible/join-cert`). Once done, run

```
cd terraform; terraform plan; terraform apply
cd ../ansible
ansible-playbook -i inventory 25-cp-kubeadm_join-playbook.yml --limit cp3
```
Again, assume the `cp3` is the new node (in the inventory file).


# destroy the cluster

In the ansible directory:
```
ansible-playbook -i inventory 90-local-k8s-cleaup.yml
ansible-playbook -i inventory 99-all-reset-playbook.yml
ansible-playbook -i inventory 99-local-ssh-remove-fingerprint.yml
```

Then go to terraform directory
```
cd ../terraform
terraform destroy
```

After `terraform destroy`, no matter it success or not, it would be better to use aws
console and verify that all resources are deleted (especially route 53 records and Load
Balancers).  If `terraform destroy` fails, you may need to use aws console to remove a few
things (for instance, manually created resources are not managed by terraform, if these
resources depend on the terraform-created resources, terraform destroy is likely to fail)
. Then run `terraform destroy` again until it success.

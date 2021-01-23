# Purpose
Deploy a kubernetes (k8s) cluster in aws use vagrant, terraform, ansible, and kubeadm.

A bit more detail: use vagrant to deploy a VM which contain terraform and ansible; use
terraform to deploy the required resources in aws; use ansible to prepare EC2 instances
and use kubeadm to deploy a k8s cluster. In the end there is k8s cluster with:
* one controlplane (master) node and three worker nodes
* network load balancers (NLB) for k8s api cluster and nginx ingress controller
* a aws ebs volume provisioner (the StorageClass `standard`)

By default it costs more than 5 US dollars per day. For test purpose, in the beginning you
can use smaller machines (such as `t3a.small`), use only 1 worker node (see the
`Auto Scaling groups` section below), and destroy the infrastructure when you don't need it
(it takes about 10 minutes to start if no need to update the configurations).

Tested on MacOS 10.15.x and Ubuntu 18.04.


# Prerequisites
* Vagrant and virtualbox installed
* A domain name, such as `example.com` (from domain name register such as namecheap or godaddy)
  - your k8s apiserver will be at `api.example.com`
* An aws account. And in aws console:
  - Add a route53 hosted zone for that domain name. Once done, you should see a NS record with about 
    4 values, the values looks like `ns-1234.awsdns-56.[org.,co.uk.,com.,net.]`.
    Note that it costs $0.5/month, so probably only need to do it once.
  - In domain name register, add these NS record to custom DNS
      - see https://www.digitalocean.com/community/tutorials/how-to-point-to-digitalocean-nameservers-from-common-domain-registrars,
        change the `nsx.digitalocean.com` to `ns-xxx.awsdns-xx.org`
      - the DNS propagation could take sometime, so if you encounter problem to find the host
        in later steps, just wait a bit.
  - Create an IAM user and get the credential, see https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html

Create a file `~/tmp/.aws/credentials` which looks like
```
[default]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

If you use aws cli before in your machine and you want to use the same credential, by
default you can simply copy the existing one: 
```
cp -r ~/.aws ~/tmp/.aws
```


# Steps
First use Vagrant to create a virtual machine which has terraform and ansible installed.

```
# it may take several minutes
vagrant up

# login to virtual machine
vagrant ssh
```

From now on all steps are in this VM.

## terraform
```
# generate a key to login to EC2 instances
ssh-keygen -t rsa -f /vagrant/mykey

cd /vagrant/terraform
cp terraform.tfvars.ex terraform.tfvars
# then fill in values or change the default values in terraform.tfvars
terraform init
terraform plan
terraform apply
```
Usually it take several minutes until everything are ready.

## ansible
> Note: if you want to update inventory file, a better approach is to update `terraform/inventory.tmpl`
> and perhaps also `terraform/local_file.tf`. Then run `terraform plan && terraform apply`

Now, the EC2 instances are initialized (by `terraform/cloudinit.tf`).
Need further configurations for k8s cluster.

First go into the `ansible` directory, install helm and kubectl, and add the ssh
fingerprints of these hosts to local machine:
```
cd /vagrant/ansible
ansible-playbook -i inventory 00-prepare.yml
ansible-playbook -i inventory 10-local.yml
```

Then make sure the nodes are deployed successfully:
```
ansible-playbook -i inventory 10-verify.yml
```

You may need to wait a bit and try again if there are problems. If everything is okay,
create the k8s cluster:
```
ansible-playbook -i inventory 20-master1.yml
ansible-playbook -i inventory 25-k8s.yml
ansible-playbook -i inventory 25-masterAll.yml
ansible-playbook -i inventory 30-workerAll.yml
```

* playbook `20-master1.yml` creates `kubeadm init` on the first controlplane and copy
  token, cert, and kubeconfig to local machine
* playbook `25-k8s.yml` creates container network interface (cni), `storageClass`,
  `nginx-ingress` controller.
* playbook `25-masterall.yml` joins other controlplanes to the cluster (by default
  there's none)
* playbook `30-workerAll.yml` joins the worker nodes to the cluster

Now can run `kubectl get nodes,pods -A` and wait until all nodes and pods are ready.

### (optional) Install rook-ceph
Usually one should simply use the `default` StorageClass which use aws-ebs provisioner,
which is deployed in `25-k8s.yml` ansible playbook. Install rook-ceph is for test only.

First use aws console to create 3 EBS volumes (10GB, for instance) for each worker node
and attach those volumes to EC2 instances (has to be in same AZ as the instance). Then run
```
ansible-playbook -i inventory 35-rook-prepare.yml
ansible-playbook -i inventory 40-rook-ceph.yml
```
Note that the `40-rook-ceph.yml` playbook clones https://github.com/rook/rook.git.
Once done, you can use the StorageClass `rook-ceph-block` in k8s cluster.


# k8s examples
See detail in `ansible/example/steps.md` (some may be outdated).
Here show a couple examples to test the cluster.

First make sure the internal network and dns works:
```
kubectl run -it busybox --image=busybox:1.28 --rm --restart=Never -- nslookup kubernetes.default
```

Next is to test the ingress controller. In `ansible/example/hello.yml`:
* modify the dns name (change the value `hello.apicat.xyz` to, for instance, `hello.example.com`).
* `kubectl apply -f hello.yml`
* add a route 53 record in aws for `hello.example.com`
  - it's an `Alias` to the NLB of ingress controller
  - there should have 2 NLB, choose the one NOT start with `tf-lb`, that is generated by terraform

Usually after a few minutes, you can access to the `hello.example.com` from your own browser.


# Notes
## Auto Scaling Groups (asg)
At this deployment, there are two aws autoscaling group (asg), one for controlplane nodes
and the other for worker nodes. By default there's one master node and three worker nodes.

### use more (or less) master or worker nodes
To improve the availability, a good starting point for is to have 3 worker nodes instead
of one. Three is a good number since `etcd` need odd number of nodes to avoid `split
brain`. Also, in most case there are 3-4 available zones (AZs) in each aws region, and asg
by default spreads nodes to different AZs.

To change the number of nodes, need to edit `terraform/asg-controlplane.tf` and/or
`terraform/asg-worker.tf`, update the `max_size` and `min_size`.

## Replace nodes
If a node is down, asg should able to automatically brought up another one (the default
grace period is 300 seconds).  But the new node cannot join the cluster automatically,
need to do these manually (note: consider use aws SNS to notify via email).

To re-join a worker node, run:
```
cd /vagrant/terraform; terraform plan
terraform apply
cd ../ansible
ansible-playbook -i inventory 30-workerAll.yml --limit worker2
```
Change the `worker2` to appropriate value (while `terraform apply` you should able to see
which node's ip address has beed updated, that should be the new EC2 instance).

**NOTE: haven't test the following part for newer version of k8s cluster**

To re-join a controlplane require also update the certificate. Assume the node `cp1` is
still the original one:
```
cd /vagrant/ansible
ansible -i inventory --become -m command -a 'kubeadm init phase upload-certs --upload-certs' cp1
```

Then copy the cert key (64 characters) to `ansible/join-cert`. Once done, run
```
cd /vagrant/terraform; terraform plan; terraform apply
cd ../ansible
ansible-playbook -i inventory 25-masterAll.yml --limit cp3
```
Again, assume the `cp3` is the newly spawned node by aws autoscaling group (check the
updates of the inventory file to find out the new nodes).


# Destroy the cluster
```
cd /vagrant/ansible
ansible-playbook -i inventory 90-local-k8s-cleaup.yml
ansible-playbook -i inventory 99-all-reset-playbook.yml
ansible-playbook -i inventory 99-local-ssh-remove-fingerprint.yml
cd ../terraform
terraform destroy
```

It should take a few minutes. Occasionally `terraform destroy` took more than 10 minutes
to delete some resources. In such case need to use aws console to check, probably other
resource depend on that one and somehow failed to remove. Delete those resources and run
`terraform destroy` again.

You should make sure aws resources are destroyed from aws console, especially:
* route 53 A-records
* In EC2 console:
  - EBS
  - EFS
  - NLB


# Issues
* Sometimes the time in the VM drift a lot (`> 10 mins`) and the AWS reject the api calls.
  This happened to me while I put my mac to sleep over night. Usually just wait a bit until
  the ntp in the VM synced. Force the ntp service to restart may help (`systemctl restart ntp`).
  The error message (while run `terraform plan` or `apply`) looks like:
```
Error: error configuring Terraform AWS Provider: error validating provider credentials: error calling sts:GetCallerIdentity: SignatureDoesNotMatch: Signature expired: 20210123T002705Z is now earlier than 20210123T003035Z (20210123T004535Z - 15 min.)
	status code: 403, request id: 3dcc16d0-c61d-419a-a8a1-a782da89cfee
```
 

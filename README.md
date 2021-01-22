# Purpose
Deploy a kubernetes (k8s) cluster in aws use vagrant, terraform, ansible, and kubeadm.

A bit more detail: use vagrant to deploy a VM which contain terraform and ansible, use
terraform to deploy the required resources in aws, then use ansible to prepare EC2
instances and deploy a k8s cluster using kubeadm. In the end there is k8s cluster with 1
controlplane (master) node and 3 worker nodes, network load balancers (NLB) for k8s api
cluster and nginx ingress controller, and some EBS storages.

By default it costs more than 5 US dollars per day. For test purpose, in the beginning you
can use smaller machines (such as `t3a.small`) and destroy the infrastructure when you
don't need it (and start another one with same infra in the next day easily).

Tested on MacOS 10.15.x and Ubuntu 18.04.

# Prerequisites
* Vagrant and virtualbox installed
* A domain name, such as `example.com` (from domain name register such as namecheap or godaddy)
* An aws account. And in aws console:
  - Add a route53 hosted zone for that domain name. You should see a NS record with about 
    4 values, each value looks like `ns-1234.awsdns-56.org.` (and probably `.co.uk.`, `.com.`, 
    `.net.`). Note that it costs $0.5/month, so probably only need to do it once.
  - In domain name register, add these NS record to custom DNS (DNS propagation need sometime)
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
> and perhaps also `terraform/local_file.tmpl`. And run `terraform plan && terraform apply`

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
* playbook `25-k8s.yml` creates container network interface (cni), `storageClass`, and
  `nginx-ingress` controller. This step creates a Network Load Balancer in AWS.
* playbook `25-masterall.yml` joins other third controlplanes to the cluster (by default
  there's none)
* playbook `30-workerAll.yml` joins the worker nodes to the cluster

### (optional) Install rook-ceph
Usually one should simply use the `default` StorageClass which use aws-ebs provisioner,
which is deployed in `25-k8s.yml` ansible playbook. Install rook-ceph is for test only.

First go to aws console and create 3 EBS volumes (10GB, for instance) for each worker node
and attach those volumes to EC2 instances (has to be in same AZ as the instance). Then run
```
ansible-p[laybook -i inventory 35-rook-prepare.yml
ansible-p[laybook -i inventory 40-rook-ceph.yml
```
Note that the `40-rool-ceph.yml` playbook clones https://github.com/rook/rook.git.
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

## Autoscaling group
At this deployment, there are two aws autoscaling group (asg), one for controlplane nodes
and the other for worker nodes.

To improve the availability, a good starting point for HA is to have 3 nodes for each asg
group. One reason is that `etcd` need odd number of nodes to avoid `split brain`. The
other reason is that in most case there are 3-4 available zones (AZs) in each aws region,
and asg by default spreads nodes to different AZs.

If a node is down, asg should able to automatically brought up another one.  But the new
node cannot join the cluster automatically, need to do these manually (note: consider use
aws SNS to notify via email).

To re-join a worker node (say, `worker2`), run:
```
cd /vagrant/terraform; terraform plan; terraform apply
cd ../ansible
ansible-playbook -i inventory 30-workerAll.yml --limit worker2
```
Change the `worker2` to appropriate value (while `terraform apply` you should able to see
which node's ip address has beed updated, that should be the new EC2 instance).

For controlplane group, need to update the certificate (use the script in the task "Get
the certificate for other controlplane..." in `20-cp1-kubeadm_init-playbook.yml`, and copy
the result to `ansible/join-cert`). Once done, run

For controlplane group, need to update the certificate
```
cd /vagrant/ansible
ansible -i inventory --become -m command -a 'kubeadm init phase upload-certs --upload-certs' cp1
```
Then copy the cert key (64 characters) to `ansible/join-cert`.
Once done, run
```
cd /vagrant/terraform; terraform plan; terraform apply
cd ../ansible
ansible-playbook -i inventory 25-masterAll.yml --limit cp3
```
Again, assume the `cp3` is the new node (in the inventory file).


# destroy the cluster
```
cd /vagrant/ansible
ansible-playbook -i inventory 90-local-k8s-cleaup.yml
ansible-playbook -i inventory 99-all-reset-playbook.yml
ansible-playbook -i inventory 99-local-ssh-remove-fingerprint.yml
cd ../terraform
terraform destroy
```

In my case, it occured a few times that `terraform destroy` took more than 10 minutes to
delete some resources. In such case need to use aws console to find out what other
resources are depend on the resource and delete the resource, and run `terraform destroy`
again (if you `CTRL-C` the previous one).

You should make sure aws resources are destroyed from aws console, especially:
* route 53 A-records
* EBS
* EFS
* NLB

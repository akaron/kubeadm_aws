#!/bin/bash
# assume that apt-transport-https is installed in cloud-init script
set -ex 

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
add-apt-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io kubeadm kubectl kubelet
apt-mark hold kubelet kubeadm kubectl
usermod -aG docker ubuntu
cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
    "max-size": "100m"
},
"storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
systemctl daemon-reload
systemctl restart docker

hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

reboot

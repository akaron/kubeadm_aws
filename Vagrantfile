# -*- mode: ruby -*-
# vi: set ft=ruby :

# ENV["LC_ALL"] = "en_US.UTF-8"

$script = <<-SCRIPT
apt-get update -y
apt-get install unzip virtualenv -y
curl https://releases.hashicorp.com/terraform/0.13.3/terraform_0.13.3_linux_amd64.zip -o terraform.zip -s
unzip terraform.zip
mv terraform /usr/local/bin
rm terraform.zip
su - vagrant
virtualenv -p /usr/bin/python3 /home/vagrant/venv
source /home/vagrant/venv/bin/activate
pip3 install ansible openshift pyyaml
echo "source /home/vagrant/venv/bin/activate" >> /home/vagrant/.bashrc
echo "export KUBECONFIG=/vagrant/ansible/kubeconfig.yml" >> /home/vagrant/.bashrc
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |v|
    v.name = "aws_kubeadm_tst"
    v.memory = "1536"
  end
  # config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.network "forwarded_port", guest: 9090, host: 9090, host_ip: "127.0.0.1", protocol: "tcp"
  
  config.vm.provision "file", source: "~/tmp/.aws", destination: "$HOME/.aws"
  config.vm.provision "shell", inline: $script
end

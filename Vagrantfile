# -*- mode: ruby -*-
# vi: set ft=ruby :

# ENV["LC_ALL"] = "en_US.UTF-8"

$script = <<-SCRIPT
apt-get update -y
apt-get install unzip ansible -y 
curl https://releases.hashicorp.com/terraform/0.13.2/terraform_0.13.2_linux_amd64.zip -o terraform.zip -s
unzip terraform.zip
mv terraform /usr/local/bin
rm terraform.zip
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provider "virtualbox" do |v|
    v.name = "aws_kubeadm_tst"
  end
  config.vm.provider "virtualbox"
  # config.vm.synced_folder '.', '/vagrant', disabled: true

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1536"
  end
  
  config.vm.provision "file", source: "~/tmp/.aws", destination: "$HOME/.aws"
  config.vm.provision "shell", inline: $script
end

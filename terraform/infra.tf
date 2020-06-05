provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_key_pair" "quickstart_key_pair" {
    key_name_prefix = "${var.prefix}-kubeadm-"
    public_key = file("${var.ssh_public_key_file_name}")
}

# All instances in same aws AZ
resource "aws_instance" "cp1" {
  ami = data.aws_ami.ubuntu.id
  # ami = data.aws_ami.debian.id
  instance_type = var.instance_type_controlplane
  vpc_security_group_ids = ["${aws_security_group.controlplane.id}"]
  # vpc_security_group_ids = ["${aws_security_group.k8s-general.id}"]
  subnet_id = local.pubsubnet1
  key_name = aws_key_pair.quickstart_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.controlplane.id
  root_block_device {
    volume_size = var.volume_size
  }

  tags = merge(
    local.tag,
    map("Name", "controlplane"),
    map("app", var.route53_hosted_zone),
  )

  provisioner "local-exec" {
    command = "echo cp1 pubip ${self.public_ip} privip ${self.private_ip} >> ip_address.txt"
  }
}

resource "aws_instance" "worker1" {
  ami = data.aws_ami.ubuntu.id
  # ami = data.aws_ami.debian.id
  instance_type = var.instance_type_worker
  vpc_security_group_ids = ["${aws_security_group.worker.id}"]
  # vpc_security_group_ids = ["${aws_security_group.k8s-general.id}"]
  subnet_id = local.pubsubnet1
  key_name = aws_key_pair.quickstart_key_pair.key_name
  iam_instance_profile = aws_iam_instance_profile.worker.id

  tags = merge(
    local.tag,
    map("Name", "worker"),
    map("app", var.route53_hosted_zone),
  )

  provisioner "local-exec" {
    command = "echo worker1 pubip ${self.public_ip} privip ${self.private_ip} >> ip_address.txt"
  }
}

resource "local_file" "export_ip" {
  content = templatefile("inventory.tmpl", {
    cp1 = aws_instance.cp1.public_ip
    worker1 = aws_instance.worker1.public_ip
    ssh_key_file = var.ssh_private_key_file_name
    cluster_name = var.cluster_name
  })
  filename = "../ansible/inventory"
  file_permission = "0644"
}

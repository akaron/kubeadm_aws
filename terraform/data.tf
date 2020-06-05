# Data for AWS module

# AWS data
# ----------------------------------------------------------

# Use latest Ubuntu 18.04 AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    # values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# data "aws_ami" "debian" {
#   most_recent = true
#   owners      = ["136693071363"]  # for Debian Buster releases
#   filter {
#     name   = "name"
#     values = ["debian-10-amd64-*"]
#   }
# }

locals {
  pubsubnet1 = module.vpc.subnet-public-1-id
  pubsubnet2 = module.vpc.subnet-public-2-id
  pubsubnet3 = module.vpc.subnet-public-3-id
  tag  = map(
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )
}


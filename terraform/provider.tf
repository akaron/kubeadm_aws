provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_key_pair" "quickstart_key_pair" {
    key_name_prefix = "${var.prefix}-kubeadm-"
    public_key = file(var.ssh_public_key_file_name)
}

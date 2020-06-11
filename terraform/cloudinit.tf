# compare to ansible, the problem of cloud-init is that you
# need to check the results manually
data "template_file" "init-script" {
  template = file("scripts/init.cfg")
  # vars are not used now
  vars = {
    REGION = var.aws_region
  }
}

data "template_file" "shell-script" {
  template = file("scripts/install_pkg.sh")
  vars = {
    REGION = var.aws_region
  }
}

data "template_cloudinit_config" "k8s_all" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init-script.rendered
  }

  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.shell-script.rendered
  }
}


resource "local_file" "inventory" {
  # depends_on = [aws_autoscaling_group.controlplane, aws_autoscaling_group.worker]
  content = templatefile("inventory.tmpl", {
    controlplane_ips = zipmap(range(1, 1+length(data.aws_instances.controlplane.public_ips)), data.aws_instances.controlplane.public_ips)
    worker_ips = zipmap(range(1, 1+length(data.aws_instances.worker.public_ips)), data.aws_instances.worker.public_ips)
    ssh_key_file = var.ssh_private_key_file_name
    cluster_name = var.cluster_name
    interpreter_python = var.interpreter_python
  })
  filename = "../ansible/inventory"
  file_permission = "0644"
}

resource "local_file" "vars" {
  # depends_on = [aws_autoscaling_group.controlplane, aws_autoscaling_group.worker]
  content = templatefile("vars-main.tmpl", {
    aws_region = var.aws_region
  })
  filename = "../ansible/vars/main.yml"
  file_permission = "0644"
}


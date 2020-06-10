resource "local_file" "inventory" {
  # depends_on = [aws_autoscaling_group.controlplane, aws_autoscaling_group.worker]
  content = templatefile("inventory.tmpl", {
    cp1 = data.aws_instances.controlplane.public_ips[0]
    worker1 = data.aws_instances.worker.public_ips[0]
    worker2 = data.aws_instances.worker.public_ips[1]
    worker3 = data.aws_instances.worker.public_ips[2]
    ssh_key_file = var.ssh_private_key_file_name
    cluster_name = var.cluster_name
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


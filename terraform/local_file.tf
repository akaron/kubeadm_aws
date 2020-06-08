resource "local_file" "export_ip" {
  # depends_on = [aws_autoscaling_group.controlplane, aws_autoscaling_group.worker]
  content = templatefile("inventory.tmpl", {
    cp1 = data.aws_instances.controlplane.public_ips[0]
    cp2 = data.aws_instances.controlplane.public_ips[1]
    cp3 = data.aws_instances.controlplane.public_ips[2]
    worker1 = data.aws_instances.worker.public_ips[0]
    ssh_key_file = var.ssh_private_key_file_name
    cluster_name = var.cluster_name
  })
  filename = "../ansible/inventory"
  file_permission = "0644"
}


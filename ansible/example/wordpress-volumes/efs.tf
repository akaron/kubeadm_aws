resource "aws_efs_file_system" "wordpress" {
  creation_token = "wordpress"

  tags = {
    Name = "wordpress-upload"
    app = var.route53_hosted_zone
  }
}

resource "aws_efs_mount_target" "wordpress-a" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = local.pubsubnet1
  security_groups = ["${aws_security_group.worker.id}"]
}

resource "aws_efs_mount_target" "wordpress-b" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = local.pubsubnet2
  security_groups = ["${aws_security_group.worker.id}"]
}

resource "aws_efs_mount_target" "wordpress-c" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = local.pubsubnet3
  security_groups = ["${aws_security_group.worker.id}"]
}

output "efs_dns_name" {
  value = aws_efs_file_system.wordpress.dns_name
}

resource "local_file" "vars-efs" {
  # depends_on = [aws_efs_mount_target.wordpress]
  content = "efs_mount_target_dns_name = ${aws_efs_file_system.wordpress.dns_name}"
  filename = "../ansible/vars/wp.yml"
  file_permission = "0644"
}


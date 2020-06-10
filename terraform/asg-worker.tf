resource "aws_launch_configuration" "worker" {
  associate_public_ip_address = true
  enable_monitoring           = false
  iam_instance_profile        = aws_iam_instance_profile.worker.id
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type_worker
  security_groups             = ["${aws_security_group.worker.id}"]
  key_name                    = aws_key_pair.quickstart_key_pair.id
  lifecycle {
    create_before_destroy = true
  }
  name_prefix = "asg-worker"
  root_block_device {
    delete_on_termination = true
    volume_size           = var.volume_size_worker
    volume_type           = "gp2"
  }
}

resource "aws_autoscaling_group" "worker" {
  depends_on = [aws_lb_target_group.apiserver]
  enabled_metrics      = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  launch_configuration = aws_launch_configuration.worker.id
  max_size             = 3
  metrics_granularity  = "1Minute"
  min_size             = 3
  name                 = "worker"
  vpc_zone_identifier  = [local.pubsubnet1, local.pubsubnet2, local.pubsubnet3]
  tag {
    key                 = "Name"
    value               = "worker"
    propagate_at_launch = true
  }
  tag {
    key                 = "app"
    value               = var.route53_hosted_zone
    propagate_at_launch = true
  }
  tag {
    key                 = "kubernetes.io/cluster/${var.cluster_name}"
    value               = "owned"
    propagate_at_launch = true
  }
  tag {
    key                 = "role"
    value               = "worker"
    propagate_at_launch = true
  }
}

data "aws_instances" "worker" {
  depends_on = [aws_autoscaling_group.worker]
  instance_tags = map("role", "worker")
}

output "worker-private-ips" {
  value = data.aws_instances.worker.private_ips
}

output "worker-public-ips" {
  value = data.aws_instances.worker.public_ips
}

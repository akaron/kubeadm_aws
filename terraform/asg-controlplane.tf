resource "aws_launch_configuration" "controlplane" {
  associate_public_ip_address = true
  enable_monitoring           = false
  iam_instance_profile        = aws_iam_instance_profile.controlplane.id
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type_controlplane
  security_groups             = ["${aws_security_group.controlplane.id}"]
  key_name                    = aws_key_pair.quickstart_key_pair.id
  user_data = data.template_cloudinit_config.k8s_all.rendered
  lifecycle {
    create_before_destroy = true
  }
  name_prefix = "asg-controlplane"
  root_block_device {
    delete_on_termination = true
    volume_size           = var.volume_size_controlplane
    volume_type           = "gp2"
  }
}

resource "aws_autoscaling_group" "controlplane" {
  depends_on = [aws_lb_target_group.apiserver]
  enabled_metrics      = ["GroupDesiredCapacity", "GroupInServiceInstances", "GroupMaxSize", "GroupMinSize", "GroupPendingInstances", "GroupStandbyInstances", "GroupTerminatingInstances", "GroupTotalInstances"]
  # health_check_type    = "ELB"  # Can NLB or ALB use ELB health check type?
  # health_check_grace_period = 300
  launch_configuration = aws_launch_configuration.controlplane.id
  max_size             = 1
  metrics_granularity  = "1Minute"
  min_size             = 1
  name                 = "controlplane"
  vpc_zone_identifier  = [local.pubsubnet1, local.pubsubnet2, local.pubsubnet3]
  target_group_arns    = [aws_lb_target_group.apiserver.arn]
  tag {
    key                 = "Name"
    value               = "controlplane"
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
    value               = "master"
    propagate_at_launch = true
  }
}

data "aws_instances" "controlplane" {
  depends_on = [aws_autoscaling_group.controlplane]
  instance_tags = map("role", "master")
}

output "controlplane-private-ips" {
  value = data.aws_instances.controlplane.private_ips
}

output "controlplane-public-ips" {
  value = data.aws_instances.controlplane.public_ips
}

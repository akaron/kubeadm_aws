resource "aws_lb" "apiserver" {
  load_balancer_type = "network"

  subnet_mapping {
    subnet_id  = local.pubsubnet1
  }
  subnet_mapping {
    subnet_id  = local.pubsubnet2
  }
  subnet_mapping {
    subnet_id  = local.pubsubnet3
  }

}

resource "aws_lb_target_group" "apiserver" {
  name     = "apiserver"
  port     = 6443
  protocol = "TCP"
  vpc_id   = module.vpc.id
  stickiness {
    type    = "lb_cookie"
    enabled = false
  }
}

resource "aws_lb_target_group_attachment" "attach_worker_to_api" {
  target_group_arn = aws_lb_target_group.apiserver.arn
  target_id        = aws_instance.cp1.id
  port             = 6443
}


resource "aws_lb_listener" "forward6443" {
  load_balancer_arn = aws_lb.apiserver.arn
  port              = "6443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apiserver.arn
  }
}


# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
# https://docs.projectcalico.org/getting-started/kubernetes/requirements
# NOTE: 
# * port 443 is required as well
# * use aws_security_group_rule instead of define the rules inside aws_security_group seems more flexible. For instance, can cross-reference.
# * in this file, "master" = "controlplane"
# * open tcp 443,6443,2379-2380,10250-10252,179,5473; udp 4789 is still not enough? For now allow all within cluster

resource "aws_security_group" "controlplane" {
  name        = "${var.prefix}-kubeadm-controlplane"
  vpc_id      = module.vpc.id
  description = "Kubeadm controlplane"
  tags = merge(
    local.tag,
    map("Name", "controlplane"),
    map("Creator", "terraform")
  )
}

# TODO: make ec2 instance more secure
#   1. add a security group for NLB, which allow 80 and 443 from 0.0.0.0/0
#   2. allow 443 to only (1)controlplanes; (2)workers; (3)NLB
#   3. don't assign public ip for master and worker!
resource "aws_security_group_rule" "master-443-for-all" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  description       = ""
  security_group_id = aws_security_group.controlplane.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-6443-for-all" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  description       = ""
  security_group_id = aws_security_group.controlplane.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "master-ssh-for-home" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = ""
  security_group_id = aws_security_group.controlplane.id
  cidr_blocks       = ["${var.myip_cidr}"]
}

resource "aws_security_group_rule" "master-all-for-master" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = ""
  security_group_id        = aws_security_group.controlplane.id
  source_security_group_id = aws_security_group.controlplane.id
}

resource "aws_security_group_rule" "master-all-for-worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = ""
  security_group_id        = aws_security_group.controlplane.id
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "master-egress" {
  type              = "egress"
  from_port         = 0 
  to_port           = 0 
  protocol          = "-1"
  description       = ""
  security_group_id = aws_security_group.controlplane.id
  cidr_blocks       = ["0.0.0.0/0"]
}


resource "aws_security_group" "worker" {
  name        = "${var.prefix}-kubeadm-worker"
  vpc_id      = module.vpc.id
  description = "Kubeadm worker"
  tags = merge(
    local.tag,
    map("Name", "worker"),
    map("Creator", "terraform")
  )
}

resource "aws_security_group_rule" "worker-ssh-from-home" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = ""
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["${var.myip_cidr}"]
}

resource "aws_security_group_rule" "worker-kubelet-for-self" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  description              = ""
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "worker-kubelet-for-master" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  description              = ""
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.controlplane.id
}

resource "aws_security_group_rule" "worker-all-for-master" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = ""
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.controlplane.id
}

resource "aws_security_group_rule" "worker-all-for-worker" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  description              = ""
  security_group_id        = aws_security_group.worker.id
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "worker-nodeport-from-all" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  description       = ""
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["0.0.0.0/0"]
  # cidr_blocks = ["${var.myip_cidr}"]
  }

resource "aws_security_group_rule" "worker-egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0 
  protocol          = "-1"
  description       = ""
  security_group_id = aws_security_group.worker.id
  cidr_blocks       = ["0.0.0.0/0"]
}

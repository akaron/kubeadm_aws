# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#check-required-ports
resource "aws_security_group" "k8s-general" {
  name        = "${var.prefix}-k8s-general"
  vpc_id      = module.vpc.id
  description = "general for all k8s nodes"

  ingress {
    from_port   = "443"
    to_port     = "443"
    protocol    = "tcp"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "6443"
    to_port     = "6443"
    protocol    = "tcp"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    description = ""
    self        = true
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    description = ""
    cidr_blocks = ["${var.myip_cidr}"]
  }

  ingress {
    from_port   = "-1"
    to_port     = "-1"
    protocol    = "icmp"
    description = ""
    self        = true
    # cidr_blocks = ["172.16.0.0/16"]
  }

  egress {
    from_port   = "0" 
    to_port     = "0" 
    protocol    = "-1"
    description = ""
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.tag,
    map("Name", "k8s-general-sg"),
    map("Creator", "terraform")
  )
}

resource "aws_security_group" "controlplane" {
  name        = "${var.prefix}-kubeadm-controlplane"
  # vpc_id      = data.aws_vpc.default.id
  vpc_id      = module.vpc.id
  description = "Kubeadm controlplane"

  ingress {
    from_port   = "6443"
    to_port     = "6443"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.myip_cidr}"]
  }

  ingress {
    from_port   = "2379"
    to_port     = "2380"
    protocol    = "tcp"
    self        = true
  }

  ingress {
    from_port   = "10250"
    to_port     = "10252"
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = "0" 
    to_port     = "0" 
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tags = { 
  #   Creator = "terraform"
  #   "kubernetes.io/cluster/mycluster" = 1
  # }
  tags = merge(
    local.tag,
    map("Name", "controlplane"),
    map("Creator", "terraform")
  )
}

resource "aws_security_group" "worker" {
  name        = "${var.prefix}-kubeadm-worker"
  # vpc_id      = data.aws_vpc.default.id
  vpc_id      = module.vpc.id
  description = "Kubeadm worker"

  ingress {
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    cidr_blocks = ["${var.myip_cidr}"]
  }

  ingress {
    from_port   = "10250"
    to_port     = "10250"
    protocol    = "tcp"
    security_groups = ["${aws_security_group.controlplane.id}"]
    self        = true
  }

  ingress {
    from_port   = "30000"
    to_port     = "32767"
    protocol    = "tcp"
    # cidr_blocks = ["${var.myip_cidr}"]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
     from_port   = "8443"
     to_port     = "8443"
     protocol    = "tcp"
     security_groups = ["${aws_security_group.controlplane.id}"]
     description = "for nginx ingress controller"
   }
  
  egress {
    from_port   = "0" 
    to_port     = "0" 
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tags = { 
  #   Creator = "terraform"
  #   "kubernetes.io/cluster/mycluster" = 1
  # }
  tags = merge(
    local.tag,
    map("Name", "worker"),
    map("Creator", "terraform")
  )
}

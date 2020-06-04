variable "AWS_REGION" {
  type    = string
  default = "us-east-1"
}

variable "vpc_name" {
  type    = string
  default = "myvpc"
}

variable "cluster_name" {
  type = string
}

locals {
  aza  = "${var.AWS_REGION}a"
  azb  = "${var.AWS_REGION}b"
  azc  = "${var.AWS_REGION}c"
  
  # note: looks like it's not possible to put variables in the key of tag, one work-around
  #   is to define a variable of type map, and put the map to the tag, and usually need to
  #   use merge() to combine with other tags (see vpc.tf)
  tag  = map(
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )
}

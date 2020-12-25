# Variables for AWS infrastructure module

variable "aws_profile" {
  type        = string
  default     = "default"
  description = "the profile configured in the aws credential profile (default: default)"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
}

variable "cluster_name" {
  type        = string
  description = "name of kubernetes cluster (used in tags)"
  default     = "myCluster"
}

variable "prefix" {
  type        = string
  description = "Prefix added to names of all resources"
  default     = "quickstart"
}

variable "ssh_private_key_file_name" {
  type        = string
  description = "File path and name of SSH private key used for infrastructure"
}

variable "ssh_public_key_file_name" {
  type        = string
  description = "File path and name of SSH public key used for infrastructure"
}

variable "instance_type_controlplane" {
  type        = string
  description = "EC2 Instance type used for controlplane nodes"
  default     = "t3a.medium"
}

variable "instance_type_worker" {
  type        = string
  description = "EC2 Instance type used for worker nodes"
  default     = "t3a.medium"
}

variable "volume_size_controlplane" {
  type        = string
  description = "root volume size used for all controlplane nodes; at least 8GB"
  default     = "10"  # GiB
}

variable "volume_size_worker" {
  type        = string
  description = "root volume size used for all worker nodes; at least 8GB"
  default     = "10"  # GiB
}

variable "route53_hosted_zone" {
  type        = string
  description = "Existing Route 53 hosted zone. Remember the `.` in the end. (such as:`example.com.`)"
}

# Required
variable "myip_cidr" {
  type        = string
  description = "EC2 instances allow connections of some ports from this IP (ex: 1.2.3.4/32)"
}

variable "interpreter_python" {
  type        = string
  description = "interpreter of python for ansible"
}


# Local variables used to reduce repetition
locals {
  node_username = "ubuntu"  # the default user of the ubuntu AMIs
}

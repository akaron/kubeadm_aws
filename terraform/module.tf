module "vpc" {
  source = "./vpc"
  AWS_REGION = var.aws_region
  cluster_name = var.cluster_name
}

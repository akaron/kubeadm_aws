module "vpc" {
  source = "./vpc"
  AWS_REGION = var.aws_region
  cluster_name = var.cluster_name
  route53_hosted_zone = var.route53_hosted_zone
}

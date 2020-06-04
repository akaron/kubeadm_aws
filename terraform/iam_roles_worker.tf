# IAM policies from https://github.com/kubernetes/cloud-provider-aws 
resource "aws_iam_role_policy" "worker" {
  name = "${var.prefix}-kubeadm-worker"
  role = aws_iam_role.worker.id

  policy = <<-EOF
	{
			"Version": "2012-10-17",
			"Statement": [
					{
							"Effect": "Allow",
							"Action": [
									"ec2:DescribeInstances",
									"ec2:DescribeRegions",
									"ecr:GetAuthorizationToken",
									"ecr:BatchCheckLayerAvailability",
									"ecr:GetDownloadUrlForLayer",
									"ecr:GetRepositoryPolicy",
									"ecr:DescribeRepositories",
									"ecr:ListImages",
									"ecr:BatchGetImage"
							],
							"Resource": "*"
					} 
			]
	}
  EOF
}

resource "aws_iam_role" "worker" {
  name = "${var.prefix}-kubeadm-worker"
  assume_role_policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
  tags = {
    app = var.route53_hosted_zone
  }
}

resource "aws_iam_instance_profile" "worker" {
  name = "kubeadm_worker"
  role = aws_iam_role.worker.name
}


# Please fill in all values
# The comment lines are optional variables with their default values filled

# aws_profile = "default"
aws_region = ""  # such as "us-east-2"

# myip_cidr: for aws security group to open some ports to this machine
# should use something other than "0.0.0.0/32"
myip_cidr = ""
route53_hosted_zone = ""  # assume the hosted_zone already created (dont forget the '.' in the end)
# cluster_name = "myCluster"

# Prefix for most resources
# prefix = "quickstart"

# EC2 instance
# instance_type_controlplane = "t3a.medium"  # or smaller for test purpose
# instance_type_worker = "t3a.medium"
ssh_private_key_file_name = ""  # the full path
ssh_public_key_file_name = ""
# volume_size_controlplane = "10"  # at least 9 GB
# volume_size_worker = "10"

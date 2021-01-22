# Please fill in all values
# The comment lines are optional variables with their default values filled

# aws_profile = "default"
aws_region = ""  # such as "us-east-2"

# myip_cidr: for aws security group to open some ports to this machine
# should use something other than "0.0.0.0/32"
myip_cidr = ""
route53_hosted_zone = ""  # assume the hosted_zone already created. such as "example.com." (there's a dot in the end)
cluster_name = ""  # such as "example.com"

interpreter_python = "/usr/bin/python3"  # for ansible inventory file

# Prefix for most resources
# prefix = "quickstart"

# EC2 instance
# instance_type_controlplane = "t3a.small"  # for test purpose
# instance_type_worker = "t3a.small"
ssh_private_key_file_name = ""  # the full path
ssh_public_key_file_name = ""
# volume_size_controlplane = "10"  # at least 9 GB 
# volume_size_worker = "10"

# notes:
# * recommended instance type and EBS volume sizes for simple tests:
#   - 2 vCPU and 2 GB RAM (t3.small or t3a.small), 8GB of EBS
#   - notes
#     - in a test run using t3a.small, there are ~1.2-1.4GB of free RAM in worker nodes with
#       prometheus, grafana, and cert-manager running, and 3-4 GB of EBS has been used
#     - t3.micro/small/medium: all 2 vCPU and 1/2/4 GB of ram, daily costs are about
#       0.25/0.5/1.0 US dollar per instance

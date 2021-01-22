#
# Default values, modify if you want and you know what you're doing
#
# aws_profile = "default"
# prefix = "quickstart"  # prefix for name or tag of some aws resources
# instance_type_controlplane = "t3.medium"  # at least "t3.small" or "t3a.small"
# instance_type_worker = "t3a.medium"
# volume_size_controlplane = "12"  # at least 9 GB 
# volume_size_worker = "13"
# ssh_private_key_file_name = "/vagrant/mykey"  # the full path
# ssh_public_key_file_name = "/vagrant/mykey.pub"

#
# Please fill in all values below
#
aws_region = ""  # such as "us-east-2"
myip_cidr = ""  # basically it's your external ip, such as "1.2.3.4/32" (try `curl ifconfig.me` to find it out)
route53_hosted_zone = ""  # assume the hosted_zone already created. such as "example.com." (there's a dot in the end)
cluster_name = ""  # such as "example.com"

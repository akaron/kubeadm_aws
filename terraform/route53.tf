data "aws_route53_zone" "selected" {
  name         = var.route53_hosted_zone
}

# TODO: should provision a LB and put the LB to the record (instead of ip of one machine).
#       Adding multiple ip to the same "A" record may sufficient for test purpose
resource "aws_route53_record" "master" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "api.${data.aws_route53_zone.selected.name}"
  type    = "A"
  ttl     = "300"
  records = [ aws_instance.cp1.public_ip ]

  depends_on = [ aws_instance.cp1 ]
}


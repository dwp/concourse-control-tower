data "aws_route53_zone" "concourse" {
  name = var.dns_zone_name
}

resource "aws_route53_record" "concourse" {
  name = var.dns_zone_name
  type = "A"
  zone_id = data.aws_route53_zone.concourse.id
  alias {
    evaluate_target_health = false
    name = aws_elb.concourse.dns_name
    zone_id = aws_elb.concourse.zone_id
  }
}

resource "aws_acm_certificate" "concourse" {
  domain_name       = data.aws_route53_zone.concourse.name
  validation_method = "DNS"
}

resource "aws_route53_record" "concourse_validation" {
  name    = "${aws_acm_certificate.concourse.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.concourse.domain_validation_options.0.resource_record_type}"
  zone_id = data.aws_route53_zone.concourse.id
  records = ["${aws_acm_certificate.concourse.domain_validation_options.0.resource_record_value}"]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.concourse.arn
  validation_record_fqdns = [aws_route53_record.concourse_validation.fqdn]
}

resource "aws_elb" "concourse" {
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.elb.id]
  instances = aws_instance.web.*.id

  listener {
    instance_port      = 8080
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate_validation.cert.certificate_arn
  }
}

resource "aws_security_group" "elb" {
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "elb_http_in" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "elb_web_out" {
  from_port                = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb.id
  to_port                  = 8080
  type                     = "egress"
  source_security_group_id = aws_security_group.web.id
}

resource "aws_elb" "concourse" {
  subnets         = var.vpc.aws_subnets_public[*].id
  security_groups = [aws_security_group.elb.id]
  instances       = aws_instance.web.*.id

  health_check {
    healthy_threshold   = 2
    interval            = 30
    target              = "HTTP:8080/"
    timeout             = 5
    unhealthy_threshold = 2
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "HTTP"
    lb_port            = 443
    lb_protocol        = "HTTPS"
    ssl_certificate_id = aws_acm_certificate_validation.cert.certificate_arn
  }

  listener {
    instance_port     = 2222
    instance_protocol = "TCP"
    lb_port           = 2222
    lb_protocol       = "TCP"
  }

  tags = merge(
    var.tags,
    { Name = "elb" }
  )
}

resource "aws_security_group" "elb" {
  vpc_id = var.vpc.aws_vpc.id
  tags = merge(
    var.tags,
    { Name = "elb" }
  )
}

resource "aws_security_group_rule" "elb_http_in" {
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "elb_external_ssh_in" {
  from_port         = 2222
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  to_port           = 2222
  type              = "ingress"
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "elb_worker_ssh_in" {
  from_port         = 2222
  protocol          = "tcp"
  security_group_id = aws_security_group.elb.id
  to_port           = 2222
  type              = "ingress"
  source_security_group_id = aws_security_group.worker.id
}

resource "aws_security_group_rule" "elb_web_http_out" {
  from_port                = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb.id
  to_port                  = 8080
  type                     = "egress"
  source_security_group_id = aws_security_group.web.id
}

resource "aws_security_group_rule" "elb_web_ssh_out" {
  from_port                = 2222
  protocol                 = "tcp"
  security_group_id        = aws_security_group.elb.id
  to_port                  = 2222
  type                     = "egress"
  source_security_group_id = aws_security_group.web.id
}

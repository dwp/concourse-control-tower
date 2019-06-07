resource "aws_instance" "web" {
  count                  = var.web.count
  ami                    = data.aws_ami.ami.id
  instance_type          = var.web.instance_type
  subnet_id              = aws_subnet.private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.concourse.id
  user_data_base64       = data.template_cloudinit_config.web_bootstrap.rendered
  vpc_security_group_ids = [aws_security_group.web.id]
  tags = merge(
    var.tags,
    { Name = "web-${local.zone_names[count.index]}" }
  )
}

data "template_file" "web_systemd" {
  template = file("${path.module}/templates/web_systemd.tpl")

  vars = {
    external_url      = "https://${local.fqdn}"
    cluster_name = var.cluster_name
    admin_user        = var.web.admin_user
    admin_password    = var.web.admin_password
    database_host     = aws_rds_cluster.concourse.endpoint
    database_name     = aws_rds_cluster.concourse.database_name
    database_user     = aws_rds_cluster.concourse.master_username
    database_password = aws_rds_cluster.concourse.master_password
  }
}

data "template_file" "web_bootstrap" {
  template = file("${path.module}/templates/web_bootstrap.sh.tpl")

  vars = {
    concourse_version  = var.concourse_version
    keys_bucket_id     = module.keys.keys_bucket_id
    aws_default_region = data.aws_region.current.name
  }
}

data "template_cloudinit_config" "web_bootstrap" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "package_update: true"
  }

  part {
    content_type = "text/cloud-config"
    content      = "package_upgrade: true"
  }

  part {
    content_type = "text/cloud-config"

    content = <<EOF
packages:
  - awscli
  - jq
EOF

  }

  # Create concourse_worker systemd service file
  part {
    content_type = "text/cloud-config"

    content = <<EOF
write_files:
- encoding: b64
  content: ${base64encode(data.template_file.web_systemd.rendered)}
  owner: root:root
  path: /etc/systemd/system/concourse_web.service
  permissions: '0755'
EOF

  }

  # Bootstrap concourse
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.web_bootstrap.rendered
  }

}

resource "aws_security_group" "web" {
  vpc_id = aws_vpc.main.id
  tags = merge(
  var.tags,
  { Name = "web" }
  )
}

resource "aws_security_group_rule" "web_elb_in" {
  from_port                = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web.id
  to_port                  = 8080
  type                     = "ingress"
  source_security_group_id = aws_security_group.elb.id
}

resource "aws_security_group_rule" "tsa_elb_in" {
  from_port                = 2222
  protocol                 = "tcp"
  security_group_id        = aws_security_group.web.id
  to_port                  = 2222
  type                     = "ingress"
  source_security_group_id = aws_security_group.elb.id
}

resource "aws_security_group_rule" "tsa_peer_in" {
  from_port         = 2222
  protocol          = "tcp"
  security_group_id = aws_security_group.web.id
  to_port           = 2222
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "web_all_out" {
  from_port         = 0
  protocol          = "all"
  security_group_id = aws_security_group.web.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

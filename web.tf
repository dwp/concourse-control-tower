data "aws_ssm_parameter" "admin_password" {
  name = var.secrets.admin.password_ssm_name
}

data "aws_ssm_parameter" "admin_user" {
  name = var.secrets.admin.user_ssm_name
}

resource "aws_instance" "web" {
  count                  = var.web.count
  ami                    = data.aws_ami.ami.id
  instance_type          = var.web.instance_type
  subnet_id              = var.vpc.aws_subnets_private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.concourse.id
  user_data_base64       = data.template_cloudinit_config.web_bootstrap.rendered
  vpc_security_group_ids = [aws_security_group.web.id]
  tags = merge(
    var.tags,
    { Name = "web-${local.zone_names[count.index]}" }
  )
}

locals {
  web_systemd_file = templatefile(
    "${path.module}/templates/web_systemd.tpl",
    {
      environment_vars = merge(
        {
          CONCOURSE_PEER_ADDRESS         = "%H"
          CONCOURSE_SESSION_SIGNING_KEY  = "/etc/concourse/session_signing_key"
          CONCOURSE_TSA_HOST_KEY         = "/etc/concourse/host_key"
          CONCOURSE_TSA_AUTHORIZED_KEYS  = "/etc/concourse/authorized_worker_keys"
          CONCOURSE_EXTERNAL_URL         = "https://${local.fqdn}"
          CONCOURSE_CLUSTER_NAME         = var.cluster_name
          CONCOURSE_POSTGRES_HOST        = aws_rds_cluster.concourse.endpoint
          CONCOURSE_POSTGRES_USER        = aws_rds_cluster.concourse.master_username
          CONCOURSE_POSTGRES_PASSWORD    = aws_rds_cluster.concourse.master_password
          CONCOURSE_POSTGRES_DATABASE    = aws_rds_cluster.concourse.database_name
          CONCOURSE_ADD_LOCAL_USER       = "${data.aws_ssm_parameter.admin_user.value}:${data.aws_ssm_parameter.admin_password.value}"
          CONCOURSE_MAIN_TEAM_LOCAL_USER = data.aws_ssm_parameter.admin_user.value
        },
        var.web.environment_override
      )
    }
  )
  web_bootstrap_file = templatefile(
    "${path.module}/templates/web_bootstrap.sh.tpl",
    {
      concourse_version  = var.concourse_version
      keys_bucket_id     = data.aws_s3_bucket.concourse_keys.id
      aws_default_region = data.aws_region.current.name
    }
  )
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
    content      = <<EOF
packages:
  - awscli
  - jq
EOF
  }

  # Create concourse_worker systemd service file
  part {
    content_type = "text/cloud-config"
    content      = <<EOF
write_files:
- encoding: b64
  content: ${base64encode(local.web_systemd_file)}
  owner: root:root
  path: /etc/systemd/system/concourse_web.service
  permissions: '0755'
- encoding: b64
  content: ${base64encode(local.logger_conf_file)}
  owner: root:root
  path: /opt/journald-cloudwatch-logs/journald-cloudwatch-logs.conf
  permissions: '0755'
- encoding: b64
  content: ${base64encode(local.logger_systemd_file)}
  owner: root:root
  path: /etc/systemd/system/journald_cloudwatch_logs.service
  permissions: '0755'
EOF
  }

  # Bootstrap concourse
  part {
    content_type = "text/x-shellscript"
    content      = local.web_bootstrap_file
  }

  # Bootstrap logger
  part {
    content_type = "text/x-shellscript"
    content      = local.logger_bootstrap_file
  }
}

resource "aws_security_group" "web" {
  vpc_id = var.vpc.aws_vpc.id
  tags = merge(
    var.tags,
    { Name = "web" }
  )
  lifecycle {
    create_before_destroy = true
  }
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

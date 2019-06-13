resource "aws_instance" "worker" {
  count                  = var.worker.count
  ami                    = data.aws_ami.ami.id
  instance_type          = var.worker.instance_type
  subnet_id              = var.vpc.aws_subnets_private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.concourse.id
  user_data_base64       = data.template_cloudinit_config.worker_bootstrap.rendered
  vpc_security_group_ids = [aws_security_group.worker.id]
  tags = merge(
    var.tags,
    { Name = "worker-${local.zone_names[count.index]}" }
  )
}

locals {
  worker_systemd_file = templatefile(
    "${path.module}/templates/worker_systemd.tpl",
    {
      environment_vars = merge(
      {
        CONCOURSE_TSA_HOST = "${local.fqdn}:2222"
        CONCOURSE_TSA_PUBLIC_KEY = "/etc/concourse/tsa_host_key.pub"
        CONCOURSE_TSA_WORKER_PRIVATE_KEY = "/etc/concourse/worker_key"
        CONCOURSE_EPHEMERAL = true
        CONCOURSE_WORK_DIR = "/opt/concourse"
      },
      var.worker.environment_override
      )
    }
  )
  worker_bootstrap_file = templatefile(
    "${path.module}/templates/worker_bootstrap.sh.tpl",
    {
      concourse_version  = var.concourse_version
      keys_bucket_id     = data.aws_s3_bucket.concourse_keys.id
      aws_default_region = data.aws_region.current.name
    }
  )
}

data "template_cloudinit_config" "worker_bootstrap" {
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

    content = <<EOF
write_files:
- encoding: b64
  content: ${base64encode(local.worker_systemd_file)}
  owner: root:root
  path: /etc/systemd/system/concourse_worker.service
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
    content      = local.worker_bootstrap_file
  }

  # Bootstrap logger
  part {
    content_type = "text/x-shellscript"
    content = local.logger_bootstrap_file
  }
}

resource "aws_security_group" "worker" {
  vpc_id = var.vpc.aws_vpc.id
  tags = merge(
  var.tags,
  { Name = "worker" }
  )
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "worker_all_out" {
  from_port = 0
  protocol = "all"
  security_group_id = aws_security_group.worker.id
  to_port = 0
  type = "egress"
  cidr_blocks = ["0.0.0.0/0"]
}

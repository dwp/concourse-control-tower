resource "aws_instance" "worker" {
  count                  = var.worker.count
  ami                    = data.aws_ami.ami.id
  instance_type          = var.worker.instance_type
  subnet_id              = aws_subnet.private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.concourse.id
  user_data_base64       = data.template_cloudinit_config.worker_bootstrap.rendered
  vpc_security_group_ids = [aws_security_group.worker.id]
  tags = merge(
    var.tags,
    { Name = "worker-${local.zone_names[count.index]}" }
  )
}

data "template_file" "worker_systemd" {
  template = file("${path.module}/templates/worker_systemd.tpl")

  vars = {
    tsa_host = "${local.fqdn}:2222"
    tags     = ""
  }
}

data "template_file" "worker_bootstrap" {
  template = file("${path.module}/templates/worker_bootstrap.sh.tpl")

  vars = {
    concourse_version  = var.concourse_version
    keys_bucket_id     = module.keys.keys_bucket_id
    aws_default_region = data.aws_region.current.name
  }
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
  content: ${base64encode(data.template_file.worker_systemd.rendered)}
  owner: root:root
  path: /etc/systemd/system/concourse_worker.service
  permissions: '0755'
EOF

  }

  # Bootstrap concourse
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.worker_bootstrap.rendered
  }

}

resource "aws_security_group" "worker" {
  vpc_id = aws_vpc.main.id
  tags = merge(
  var.tags,
  { Name = "worker" }
  )
}

resource "aws_security_group_rule" "worker_all_out" {
  from_port         = 0
  protocol          = "all"
  security_group_id = aws_security_group.worker.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

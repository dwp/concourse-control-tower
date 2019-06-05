data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# TODO: Fix ref to workers, pass in tags
module "keys" {
  source                          = "./modules/keys"
  concourse_workers_iam_role_arns = [aws_iam_role.concourse.arn]
  environment                     = lookup(var.tags, "Environment")
  name                            = lookup(var.tags, "Name")
}

resource "aws_iam_role" "concourse" {
  assume_role_policy = data.aws_iam_policy_document.concourse.json
}

resource "aws_iam_role_policy" "concourse" {
  policy = data.aws_iam_policy_document.concourse_policy.json
  role   = aws_iam_role.concourse.id
}
data "aws_iam_policy_document" "concourse" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "concourse_policy" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*",
    ]

    resources = [
      module.keys.keys_bucket_arn,
      "${module.keys.keys_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_instance_profile" "concourse" {
  role = aws_iam_role.concourse.id
}

resource "aws_instance" "web" {
  count                  = var.web_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private[count.index].id
  iam_instance_profile   = aws_iam_instance_profile.concourse.id
  user_data_base64       = data.template_cloudinit_config.concourse_bootstrap.rendered
  vpc_security_group_ids = [aws_security_group.web.id]
  tags = merge(
    var.tags,
    { Name = "web-${local.zone_names[count.index]}" }
  )
}

# TODO: interpolate hostname from R53
data "template_file" "concourse_systemd" {
  template = file("${path.module}/templates/web_systemd.tpl")

  vars = {
    external_url      = "https://${var.dns_zone_name}"
    admin_user        = var.web_admin_user
    admin_password    = var.web_admin_password
    database_host     = aws_rds_cluster.concourse.endpoint
    database_name     = aws_rds_cluster.concourse.database_name
    database_user     = aws_rds_cluster.concourse.master_username
    database_password = aws_rds_cluster.concourse.master_password
  }
}

data "aws_region" "current" {}

data "template_file" "concourse_bootstrap" {
  template = file("${path.module}/templates/bootstrap_web.sh.tpl")

  vars = {
    concourse_version  = var.concourse_version
    keys_bucket_id     = module.keys.keys_bucket_id
    aws_default_region = data.aws_region.current.name
  }
}

data "template_cloudinit_config" "concourse_bootstrap" {
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
  content: ${base64encode(data.template_file.concourse_systemd.rendered)}
  owner: root:root
  path: /etc/systemd/system/concourse_web.service
  permissions: '0755'
EOF

  }

  # Bootstrap concourse
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.concourse_bootstrap.rendered
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

resource "aws_security_group_rule" "web_all_out" {
  from_port         = 0
  protocol          = "all"
  security_group_id = aws_security_group.web.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}

locals {
  logger_conf_file = <<EOF
log_group = "journald"
log_priority = "7"
state_file = "/opt/journald-cloudwatch-logs/state"
EOF
  logger_bootstrap_file = file("${path.module}/templates/logger_bootstrap.sh")
  logger_systemd_file = file("${path.module}/templates/logger_systemd")
}

data "aws_region" "current" {}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
}

resource "aws_iam_role" "concourse" {
  name = "concourse"
  assume_role_policy = data.aws_iam_policy_document.concourse.json
}

resource "aws_iam_role_policy" "concourse" {
  policy = data.aws_iam_policy_document.concourse_policy.json
  role = aws_iam_role.concourse.id
}

resource "aws_iam_role_policy_attachment" "logger" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role = aws_iam_role.concourse.id
}

data "aws_iam_policy_document" "concourse" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"
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
      data.aws_s3_bucket.concourse_keys.arn,
      "${data.aws_s3_bucket.concourse_keys.arn}/*",
    ]
  }
}

resource "aws_iam_instance_profile" "concourse" {
  role = aws_iam_role.concourse.id
}

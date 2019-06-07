data "aws_region" "current" {}

data "aws_ami" "ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-2.0.*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Amazon
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

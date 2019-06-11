variable "ssm_name_prefix" {
  description = "name prefix for ssm parameter store"
  type = string
}

variable "kms_key_id" {
  description = "kms key for encrypting strings"
  type = string
  default = "alias/aws/ssm"
}

variable "user" {
  description = "fixed user name"
  type = string
  default = ""
}

resource "random_string" "user" {
  length = 32
  special = false # RDS doesn't allow /,", and @
}

resource "random_string" "password" {
  length = 32
  special = false # RDS doesn't allow /,", and @
}

resource "aws_ssm_parameter" "user" {
  name = "${var.ssm_name_prefix}/user"
  type = "SecureString"
  key_id = var.kms_key_id
  value = var.user == "" ? random_string.user.result : var.user
}

resource "aws_ssm_parameter" "password" {
  name = "${var.ssm_name_prefix}/password"
  type = "SecureString"
  key_id = var.kms_key_id
  value = random_string.password.result
}

output "user_ssm_name" {
  value = aws_ssm_parameter.user.name
}

output "password_ssm_name" {
  value  = aws_ssm_parameter.password.name
}

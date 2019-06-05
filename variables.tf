# TODO: descriptions
variable "cidr_block" {
  type = string
}
variable "tags" {
  type = map
}

variable "web_count" {
  type = number
}

variable "concourse_version" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "whitelist_cidr_blocks" {
  type = list(string)
}

variable "database_user" {}
variable "database_password" {}
variable "database_instance_class" {}
variable "database_count" {}

variable "web_admin_user" {}
variable "web_admin_password" {}

# TODO: descriptions
variable "cidr_block" {
  type = string
}
variable "tags" {
  type = map
}

variable "cluster_name" {
  type = string
  default = "concourse"
  description = "cluster name, used in dns"
}

variable "concourse_version" {
  type = string
  default = "5.2.0"
  description = "concourse version to install"
}

variable "parent_domain_name" {
  type = string
  description = "parent domain name for CI"
}

variable "whitelist_cidr_blocks" {
  type = list(string)
}

variable "database" {
  type = map
}

variable "web" {
  type = map
}

variable "worker" {
  type = map
}

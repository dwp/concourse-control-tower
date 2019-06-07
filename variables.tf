# TODO: descriptions
variable "cidr_block" {
  type = string
}
variable "tags" {
  type = map
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

variable "database" {
  type = map
}

variable "web" {
  type = map
}

variable "worker" {
  type = map
}

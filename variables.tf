variable "ssm_name_prefix" {
  description = "name prefix for ssm parameters"
  type        = string
  default     = "/concourse"
}

variable "cidr_block" {
  description = "cidr block to use for vpc"
  type        = string
}
variable "tags" {
  description = "tags to apply to aws resource"
  type        = map(string)
}

variable "cluster_name" {
  description = "cluster name, used in dns"
  type        = string
  default     = "concourse"
}

variable "concourse_version" {
  description = "concourse version to install"
  type        = string
  default     = "5.2.0"
}

variable "parent_domain_name" {
  description = "parent domain name for CI"
  type        = string
}

variable "whitelist_cidr_blocks" {
  description = "list of allowed cidr blocks"
  type        = list(string)
}

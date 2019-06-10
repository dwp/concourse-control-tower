variable "cidr_block" {
  description = "cidr block to use for vpc"
  type = string
}
variable "tags" {
  description = "tags to apply to aws resource"
  type = map(string)
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
  type = list(string)
}

variable "database" {
  description = "database configuration options"
  type = object({
    name = string
    user          = string
    password      = string
    instance_type = string
    count         = number
  })
}

variable "web" {
  description = "atc/tsa configuration options"
  type = object({
    admin_user     = string
    admin_password = string
    count          = number
    instance_type  = string
  })
}

variable "worker" {
  description = "worker configuration options"
  type = object({
    instance_type = string
    count         = number
  })
}

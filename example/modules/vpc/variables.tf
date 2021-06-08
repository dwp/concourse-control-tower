variable "cidr_block" {
  description = "cidr block to use for vpc"
  type        = string
}

variable "tags" {
  description = "tags to apply to aws resource"
  type        = map(string)
}

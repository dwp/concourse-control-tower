provider "aws" {
  region = "eu-west-3"
}

variable "parent_domain_name" {}
variable "tags"{}
variable "whitelist_cidr_blocks" {}
variable "cidr_block" {}
variable "ssm_name_prefix" {}

module "concourse" {
  source   = "../"
  secrets = {
    database = module.database_secrets
    admin    = module.admin_secrets
  }
  parent_domain_name    = var.parent_domain_name
  tags                  = var.tags
  vpc                   = module.management
  whitelist_cidr_blocks = var.whitelist_cidr_blocks
  key_bucket_name       = random_id.key_bucket.hex
}

module "management" {
  source     = "./modules/vpc"
  cidr_block = var.cidr_block
  tags       = var.tags
}

resource "random_id" "key_bucket" {
  byte_length = 16
}

module "database_secrets" {
  source          = "./modules/secrets"
  ssm_name_prefix = "${var.ssm_name_prefix}/database"
}

module "admin_secrets" {
  source          = "./modules/secrets"
  ssm_name_prefix = "${var.ssm_name_prefix}/admin"
  user            = "concourse"
}

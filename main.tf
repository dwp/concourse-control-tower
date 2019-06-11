provider "aws" {
  region = "eu-west-3"
}

module "concourse" {
  source   = "./modules/concourse"
  database = var.database
  secrets = {
    database = module.database_secrets
    admin    = module.admin_secrets
  }
  parent_domain_name    = var.parent_domain_name
  tags                  = var.tags
  vpc                   = module.management
  web                   = var.web
  whitelist_cidr_blocks = var.whitelist_cidr_blocks
  worker                = var.worker
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
}

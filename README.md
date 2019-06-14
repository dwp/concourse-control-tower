# Concourse Terraform Module
Installs and configures Concourse CI in AWS  
Considerations:
- Uses EC2 classic loadbalancer to provide ATC(HTTPS) and TSA(TCP) services on the same domain
- Expects various TLS key pairs in an S3 bucket, see ``example/modules/keys``
- Written for Terraform 12, makes good use of complex types

## Example
example/main.tf: demonstrates how to use this module, useful for testing & development
requires the following variables to be set:

```ini
# terraform.tfvars
cidr_block = "10.0.0.0/16"
tags = {
  Name        = "concourse"
  Environment = "development"
  Project     = "ci"
}
parent_domain_name    = "example.com"
whitelist_cidr_blocks = ["0.0.0.0/0"]
ssm_name_prefix       = "/concourse"
```

example directory also contains the following modules:
- keys: generates and stores concourse keys in S3
- vpc: placeholder vpc module
- secrets: generates and stores username/passwords in SSM

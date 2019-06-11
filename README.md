concourse

## Structure
root: harness for testing & development
- concourse: installs and runs concourse
- vpc: placeholder vpc module
- secrets: adhoc secret generation

## Usage
```bash
# stub modules are provided to create secrets
# you may need to apply these prior to a standard terraform apply
terraform apply -target module.database_secrets -target module.database_secrets
```
You can remove these and provide the various ssm_paths directly to the concourse module

```bash
# standup concourse with your default region & credentials
terraform apply
```

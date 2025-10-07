# rds-shared (PostgreSQL)

Creates a **single RDS PostgreSQL instance** intended to host **multiple logical databases** (e.g., one for `dev`, another for `prod`) to save cost.

## What this module does
- DB subnet group (you pass the subnets)
- Security Group allowing inbound **only** from the SGs you specify
- (Optional) custom parameter group (e.g., `rds.force_ssl = 1`)
- RDS instance (PostgreSQL; single-AZ by default; gp3 storage; backups; deletion protection)
- Secret in **AWS Secrets Manager** for the **master** credentials + connection info

> This module **does not create logical databases or app users**. Do that with:
> - CI/CD migrations (preferred), **or**
> - a separate Terraform step using the `postgresql` provider (requires network access to RDS via TFC Agent or running locally).

## Inputs (key)
- Networking: `vpc_id`, `db_subnet_ids`, `allowed_sg_ids`
- Engine/size: `engine_version`, `instance_class`, `allocated_storage`, `max_allocated_storage`
- Ops: `backup_retention_days`, `maintenance_window`, `backup_window`, `deletion_protection`, `multi_az`
- Secrets: `master_username` (password auto-generated)
- Parameters: `create_parameter_group`, `parameters` (map of `{name, value, apply_method}`)
- Tags

## Outputs
- `rds_endpoint`, `rds_address`, `rds_port`
- `db_instance_arn`, `db_instance_id`
- `db_subnet_group_name`, `rds_sg_id`
- `master_secret_arn`

## Example
```hcl
module "rds_shared" {
  source = "./modules/rds-shared"

  name            = "shared"
  vpc_id          = var.vpc_id
  db_subnet_ids   = var.private_subnet_ids
  allowed_sg_ids  = [module.users_web_api.service_sg_id, module.email_web_api.service_sg_id]

  engine_version         = "16.6"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  max_allocated_storage  = 100
  backup_retention_days  = 7
  deletion_protection    = true

  tags = { Project = "EColors", Env = "shared" }
}

# Consume in services (example connection string in app config)
# host = module.rds_shared.rds_address
# port = module.rds_shared.rds_port
# username/password from Secrets Manager: module.rds_shared.master_secret_arn

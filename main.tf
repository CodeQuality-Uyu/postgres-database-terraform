# --- Import cluster networking from Terraform Cloud ---
data "terraform_remote_state" "cluster" {
  backend = "remote"
  config = {
    organization = var.clusters_org
    workspaces   = { name = var.clusters_ws_name } # e.g., clusters-dev
  }
}

# Reuse cluster VPC and PUBLIC subnets (low-budget)
# RDS will still be PRIVATE (no public IP) when publicly_accessible=false.
locals {
  vpc_id                = data.terraform_remote_state.cluster.outputs.vpc_id
  service_subnet_ids    = data.terraform_remote_state.cluster.outputs.service_subnet_ids
  ecs_service_sg_id     = data.terraform_remote_state.cluster.outputs.service_security_group_id
  alb_listener_arn      = try(data.terraform_remote_state.cluster.outputs.alb_listener_arn, null)

  db_identifier_effective = coalesce(var.db_identifier, "${var.env}-${var.db_name}")
  name_prefix             = "${var.env}-${var.db_name}"
}

# Security Group for RDS: allow 5432 only from ECS services SG (plus optional CIDRs)
resource "aws_security_group" "db" {
  name        = "${local.name_prefix}-db-sg"
  description = "Allow Postgres from ECS services and optional CIDRs"
  vpc_id      = local.vpc_id

  # Ingress from ECS service SG
  ingress {
    description     = "ECS services"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [local.ecs_service_sg_id]
  }

  # Optional extra CIDRs (e.g., bastion/jumpbox/VPN)
  dynamic "ingress" {
    for_each = var.extra_ingress_cidrs
    content {
      description = "Extra CIDR"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Environment = var.env, Name = "${local.name_prefix}-db-sg" }
}

# Subnet group (use cluster subnets; ensure at least 2 AZs there)
resource "aws_db_subnet_group" "db" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = local.service_subnet_ids
  tags       = { Name = "${local.name_prefix}-db-subnets" }
}

# Credentials (generate once; store in SSM Parameter Store SecureStrings)
resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

# Write SSM params
resource "aws_ssm_parameter" "db_master_username" {
  name        = "${var.ssm_prefix}/${var.env}/${var.db_name}/master_username"
  description = "RDS ${var.db_name} master username"
  type        = "String"
  value       = "pgadmin"
}

resource "aws_ssm_parameter" "db_master_password" {
  name        = "${var.ssm_prefix}/${var.env}/${var.db_name}/master_password"
  description = "RDS ${var.db_name} master password"
  type        = "SecureString"
  value       = random_password.master.result
}

# The database instance
resource "aws_db_instance" "postgres" {
  identifier                  = local.db_identifier_effective
  engine                      = "postgres"
  engine_version              = var.engine_version
  instance_class              = var.instance_class

  db_name                     = replace(var.db_name, "-", "_")    # must start with letter & no hyphens
  username                    = aws_ssm_parameter.db_master_username.value
  password                    = aws_ssm_parameter.db_master_password.value

  allocated_storage           = var.allocated_storage
  max_allocated_storage       = var.max_allocated_storage
  storage_type                = var.storage_type
  storage_encrypted           = true

  multi_az                    = var.multi_az
  publicly_accessible         = var.publicly_accessible   # keep false
  deletion_protection         = var.deletion_protection

  backup_retention_period     = var.backup_retention_days
  copy_tags_to_snapshot       = var.copy_tags_to_snapshot
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade

  db_subnet_group_name        = aws_db_subnet_group.db.name
  vpc_security_group_ids      = [aws_security_group.db.id]

  apply_immediately           = false

  # Optional windows
  backup_window     = var.preferred_backup_window
  maintenance_window = var.preferred_maintenance_window

  tags = {
    Environment = var.env
    Name        = local.name_prefix
  }
}

# Convenience SSM with the connection URL (without password)
resource "aws_ssm_parameter" "db_endpoint" {
  name        = "${var.ssm_prefix}/${var.env}/${var.db_name}/endpoint"
  description = "RDS ${var.db_name} endpoint"
  type        = "String"
  value       = aws_db_instance.postgres.address
}

resource "aws_ssm_parameter" "db_url" {
  name        = "${var.ssm_prefix}/${var.env}/${var.db_name}/url"
  description = "Postgres URL (no password)"
  type        = "String"
  value       = "postgresql://${aws_ssm_parameter.db_master_username.value}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${aws_db_instance.postgres.db_name}"
}

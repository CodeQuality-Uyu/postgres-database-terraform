resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-.:;<=>?@^_~" # sin comillas ni backslashes
  upper            = true
  lower            = true
  numeric          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "random_password" "master" {
  length           = 24
  special          = true
  override_special = "!#$%&*+-.:;<=>?@^_~" # sin comillas ni backslashes
  upper            = true
  lower            = true
  numeric          = true
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-pg"
  engine         = "postgres"
  engine_version = var.engine_version

  instance_class = local.effective_instance_class

  allocated_storage      = var.allocated_storage
  max_allocated_storage  = local.effective_max_allocated_storage
  storage_type           = var.storage_type
  storage_throughput     = var.storage_type == "gp3" ? var.storage_throughput : null

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.publicly_accessible
  multi_az               = local.effective_multi_az
  storage_encrypted      = true

  port     = 5432
  username = var.master_username
  password = random_password.master.result

  backup_retention_period = local.effective_backup_retention
  maintenance_window      = var.maintenance_window
  backup_window           = var.backup_window

  deletion_protection         = var.deletion_protection
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = false
  apply_immediately           = var.apply_immediately

  performance_insights_enabled          = local.effective_enable_pi
  performance_insights_retention_period = local.effective_enable_pi ? var.performance_insights_retention : null

  # Now env-aware ([] in non-prod by default if use_environment_defaults = true)
  enabled_cloudwatch_logs_exports = local.effective_cloudwatch_logs

  parameter_group_name = var.create_parameter_group ? aws_db_parameter_group.this[0].name : null

  iam_database_authentication_enabled = var.iam_authentication

  # Destruction behavior (make true in dev/stage tfvars for ephemeral DBs)
  skip_final_snapshot   = var.skip_final_snapshot
  copy_tags_to_snapshot = true

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-pg"
    Environment = local.env
  })
}


resource "random_password" "master" {
  length              = 24
  special             = true
  override_special    = "!#$%&*+-.:;<=>?@^_~" # sin comillas ni backslashes
  upper               = true
  lower               = true
  numeric             = true
  min_upper           = 1
  min_lower           = 1
  min_numeric         = 1
  min_special         = 1
}

resource "aws_db_instance" "this" {
  identifier                   = "${var.name}-pg"
  engine                       = "postgres"
  engine_version               = var.engine_version

  instance_class               = var.instance_class
  allocated_storage            = var.allocated_storage
  max_allocated_storage        = var.max_allocated_storage
  storage_type                 = var.storage_type
  storage_throughput           = var.storage_type == "gp3" ? var.storage_throughput : null

  db_subnet_group_name         = aws_db_subnet_group.this.name
  vpc_security_group_ids       = [aws_security_group.rds.id]
  publicly_accessible          = var.publicly_accessible
  multi_az                     = var.multi_az
  storage_encrypted            = true

  port                         = 5432
  username                     = var.master_username
  password                     = random_password.master.result

  backup_retention_period      = var.backup_retention_days
  preferred_maintenance_window = var.maintenance_window
  preferred_backup_window      = var.backup_window

  deletion_protection          = var.deletion_protection
  auto_minor_version_upgrade   = var.auto_minor_version_upgrade
  allow_major_version_upgrade  = false
  apply_immediately            = var.apply_immediately

  performance_insights_enabled = var.enable_performance_insights
  performance_insights_retention_period = var.enable_performance_insights ? var.performance_insights_retention : null

  enabled_cloudwatch_logs_exports = ["postgresql"] # helpful for troubleshooting

  parameter_group_name         = var.create_parameter_group ? aws_db_parameter_group.this[0].name : null

  iam_database_authentication_enabled = var.iam_authentication

  skip_final_snapshot           = false
  copy_tags_to_snapshot         = true

  tags = merge(var.tags, { Name = "${var.name}-pg" })
}

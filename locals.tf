locals {
  # ---------- Environment & naming ----------
  env       = lower(var.environment)
  is_prod   = local.env == "prod"
  is_nonprod = !local.is_prod

  # Identifier prefix used across resources (e.g., ecolors-dev)
  name_prefix = "${var.name}-${local.env}"

  # ---------- Networking & remote-state lookups (yours, kept) ----------
  vpc_id = coalesce(
    var.vpc_id,
    try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
  )

  # Subnets privadas para el DB Subnet Group (usa var si está, si no las del módulo VPC)
  db_subnet_ids = length(var.db_subnet_ids) > 0 ? var.db_subnet_ids : try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])

  db_clients_sg_id = try(data.terraform_remote_state.vpc.outputs.db_clients_sg_id, null)
  bastion_sg_id    = try(data.terraform_remote_state.vpc.outputs.ssm_bastion_sg_id, null)

  # por si querés añadir SGs extra manualmente
  allowed_extra_sg_ids = var.allowed_sg_ids

  allowed_sg_ids_final = compact(distinct(flatten([
    [local.db_clients_sg_id],
    [local.bastion_sg_id],
    local.allowed_extra_sg_ids
  ])))

  # ---------- Environment defaults (yours, kept) ----------
  env_defaults = {
    prod = {
      instance_class   = "db.t4g.medium"
      multi_az         = true
      enable_pi        = true
      backup_retention = var.prod_backup_retention_days
    }
    nonprod = {
      instance_class   = "db.t4g.micro" # "db.t4g.small"
      multi_az         = false
      enable_pi        = false
      backup_retention = var.nonprod_backup_retention_days
    }
  }

  # Base chosen env defaults
  _chosen = local.is_prod ? local.env_defaults.prod : local.env_defaults.nonprod

  # ---------- Instance class selection with optional per-env overrides ----------
  # If use_environment_defaults:
  #   - prod uses prod_instance_class if set, else env_default
  #   - non-prod uses nonprod_instance_class if set, else env_default
  # Else:
  #   - use var.instance_class
  effective_instance_class = var.use_environment_defaults ? (
    local.is_prod
      ? coalesce(var.prod_instance_class, local._chosen.instance_class)
      : coalesce(var.nonprod_instance_class, local._chosen.instance_class)
  ) : var.instance_class

  # ---------- Other env-aware toggles ----------
  effective_multi_az         = var.use_environment_defaults ? local._chosen.multi_az         : var.multi_az
  effective_enable_pi        = var.use_environment_defaults ? local._chosen.enable_pi        : var.enable_performance_insights
  effective_backup_retention = var.use_environment_defaults ? local._chosen.backup_retention : var.backup_retention_days

  # New: CloudWatch log exports empty on non-prod by default (for cost)
  effective_cloudwatch_logs = var.use_environment_defaults && local.is_nonprod ? [] : var.cloudwatch_logs_exports

  # New: disable storage autoscaling on non-prod by default (predictable/cheapest)
  effective_max_allocated_storage = var.use_environment_defaults && local.is_nonprod ? null : var.max_allocated_storage
}

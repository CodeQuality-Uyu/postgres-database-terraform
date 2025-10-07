locals {
  # VPC ID: prefer explicit var, else pull from remote VPC workspace
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

  # -------- Environment defaults ----------
  is_prod = lower(var.environment) == "prod"

  env_defaults = {
    prod = {
      instance_class   = "db.t4g.medium"
      multi_az         = true
      enable_pi        = true
      backup_retention = var.prod_backup_retention_days
    }
    nonprod = {
      instance_class   = "db.t3.micro" #"db.t4g.small"
      multi_az         = false
      enable_pi        = false
      backup_retention = var.nonprod_backup_retention_days
    }
  }

  _chosen = local.is_prod ? local.env_defaults.prod : local.env_defaults.nonprod

  effective_instance_class   = var.use_environment_defaults ? local._chosen.instance_class   : var.instance_class
  effective_multi_az         = var.use_environment_defaults ? local._chosen.multi_az         : var.multi_az
  effective_enable_pi        = var.use_environment_defaults ? local._chosen.enable_pi        : var.enable_performance_insights
  effective_backup_retention = var.use_environment_defaults ? local._chosen.backup_retention : var.backup_retention_days

  name_prefix = "${var.name}-${var.environment}"
}

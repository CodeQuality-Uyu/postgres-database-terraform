locals {
  # VPC ID: usa var.vpc_id si viene; si no, toma el output del workspace de VPC
  vpc_id = coalesce(
    var.vpc_id,
    try(data.terraform_remote_state.vpc.outputs.vpc_id, null)
  )

  # Subnets privadas para el DB Subnet Group:
  db_subnet_ids = length(var.db_subnet_ids) > 0
    ? var.db_subnet_ids
    : try(data.terraform_remote_state.vpc.outputs.private_subnet_ids, [])

  # SGs permitidos para acceder a la DB (ECS tasks):
  allowed_sg_ids = length(var.allowed_sg_ids) > 0
    ? var.allowed_sg_ids
    : compact([
        # ajustá el nombre del output si es distinto en tu workspace ECS
        try(data.terraform_remote_state.ecs.outputs.service_security_group_id, null)
      ])
}

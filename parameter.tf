resource "aws_db_parameter_group" "this" {
  count       = var.create_parameter_group ? 1 : 0
  name        = "${local.name_prefix}-pg"
  family      = "postgres${split(".", var.engine_version)[0]}" # e.g., "postgres16"
  description = "Custom params for ${local.name_prefix}"
  tags        = merge(var.tags, { Environment = var.environment })

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = try(parameter.value.apply_method, "pending-reboot")
    }
  }
}

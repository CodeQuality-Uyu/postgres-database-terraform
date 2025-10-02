resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = local.db_subnet_ids
  tags       = merge(var.tags, { Name = "${local.name_prefix}-db-subnets", Environment = var.environment })
}

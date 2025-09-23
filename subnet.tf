resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnets"
  subnet_ids = var.db_subnet_ids
  tags       = merge(var.tags, { Name = "${var.name}-db-subnets" })
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "RDS SG for ${local.name_prefix}"
  vpc_id      = local.vpc_id
  tags        = merge(var.tags, { Name = "${local.name_prefix}-rds-sg", Environment = var.environment })
}

# Allow from service SGs (ECS tasks)
resource "aws_vpc_security_group_ingress_rule" "from_sg" {
  for_each                      = toset(local.allowed_sg_ids)
  security_group_id             = aws_security_group.rds.id
  referenced_security_group_id  = each.value
  ip_protocol                   = "tcp"
  from_port                     = 5432
  to_port                       = 5432
}

# Allow from explicit CIDRs (optional)
resource "aws_vpc_security_group_ingress_rule" "from_cidr" {
  for_each          = toset(var.allowed_cidrs)
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 5432
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.rds.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

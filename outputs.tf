# ---------- Core connection info ----------
output "db_identifier" {
  description = "RDS instance identifier."
  value       = aws_db_instance.postgres.id
}

output "db_address" {
  description = "RDS endpoint hostname."
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "RDS endpoint port (usually 5432)."
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Initial database name created on the instance."
  value       = aws_db_instance.postgres.db_name
}

# ---------- Networking ----------
output "db_sg_id" {
  description = "Security Group ID attached to the RDS instance (ingress 5432)."
  value       = aws_security_group.db.id
}

# ---------- SSM Parameter Store paths (names only; values are fetched via SSM) ----------
output "ssm_master_username_path" {
  description = "SSM path for the master username (String)."
  value       = aws_ssm_parameter.db_master_username.name
}

output "ssm_master_password_path" {
  description = "SSM path for the master password (SecureString)."
  value       = aws_ssm_parameter.db_master_password.name
}

output "ssm_endpoint_path" {
  description = "SSM path for the DB endpoint hostname."
  value       = aws_ssm_parameter.db_endpoint.name
}

output "ssm_url_path" {
  description = "SSM path for the connection URL without password."
  value       = aws_ssm_parameter.db_url.name
}

# ---------- Helpful extras ----------
output "db_arn" {
  description = "RDS instance ARN."
  value       = aws_db_instance.postgres.arn
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group used by the instance."
  value       = aws_db_subnet_group.db.name
}

output "engine_version" {
  description = "PostgreSQL engine version running on the instance."
  value       = aws_db_instance.postgres.engine_version
}

output "db_instance_id"   { value = aws_db_instance.this.id }
output "db_instance_arn"  { value = aws_db_instance.this.arn }
output "rds_endpoint"     { value = aws_db_instance.this.endpoint }
output "rds_address"      { value = aws_db_instance.this.address }
output "rds_port"         { value = aws_db_instance.this.port }

output "db_subnet_group_name" { value = aws_db_subnet_group.this.name }
output "rds_sg_id"            { value = aws_security_group.rds.id }

output "master_secret_arn" {
  description = "Secrets Manager ARN with connection info and master password."
  value       = aws_secretsmanager_secret.master.arn
}

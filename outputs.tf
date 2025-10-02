output "environment" {
  value = var.environment
}

output "rds_identifier" {
  value = aws_db_instance.this.id
}

output "rds_endpoint" {
  value = aws_db_instance.this.endpoint
}

output "master_secret_arn" {
  value = aws_secretsmanager_secret.master.arn
}

# Master credentials & connection secret (JSON)
resource "aws_secretsmanager_secret" "master" {
  name = "rds/${var.name}/master"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "master" {
  secret_id = aws_secretsmanager_secret.master.id
  secret_string = jsonencode({
    engine   = "postgres"
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    username = var.master_username
    password = random_password.master.result
    dbname   = "postgres" # default; create per-env DBs separately
    endpoint = aws_db_instance.this.endpoint
  })
}

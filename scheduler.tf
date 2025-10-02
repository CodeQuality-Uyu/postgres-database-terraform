# ========== Optional Non-Prod Stop/Start Scheduler ==========
# Uses EventBridge Scheduler to call RDS Start/Stop APIs without Lambda.

resource "aws_iam_role" "scheduler_role" {
  count = var.environment == "prod" || !var.enable_nonprod_stop_schedule ? 0 : 1
  name  = "${local.name_prefix}-rds-scheduler-role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "scheduler.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  tags = merge(var.tags, { Environment = var.environment })
}

resource "aws_iam_role_policy" "scheduler_policy" {
  count = length(aws_iam_role.scheduler_role) == 0 ? 0 : 1
  name  = "${local.name_prefix}-rds-scheduler-policy"
  role  = aws_iam_role.scheduler_role[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["rds:StartDBInstance", "rds:StopDBInstance", "rds:DescribeDBInstances"],
      Resource = aws_db_instance.this.arn
    }]
  })
}

resource "aws_scheduler_schedule" "stop_nonprod" {
  count                        = var.environment == "prod" || !var.enable_nonprod_stop_schedule ? 0 : 1
  name                         = "${local.name_prefix}-rds-stop"
  schedule_expression          = var.nonprod_stop_cron
  schedule_expression_timezone = var.scheduler_timezone
  flexible_time_window { mode = "OFF" }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:stopDBInstance"
    role_arn = aws_iam_role.scheduler_role[0].arn
    input    = jsonencode({ DbInstanceIdentifier = aws_db_instance.this.id })
  }
  tags = merge(var.tags, { Environment = var.environment })
}

resource "aws_scheduler_schedule" "start_nonprod" {
  count                        = var.environment == "prod" || !var.enable_nonprod_stop_schedule ? 0 : 1
  name                         = "${local.name_prefix}-rds-start"
  schedule_expression          = var.nonprod_start_cron
  schedule_expression_timezone = var.scheduler_timezone
  flexible_time_window { mode = "OFF" }
  target {
    arn      = "arn:aws:scheduler:::aws-sdk:rds:startDBInstance"
    role_arn = aws_iam_role.scheduler_role[0].arn
    input    = jsonencode({ DbInstanceIdentifier = aws_db_instance.this.id })
  }
  tags = merge(var.tags, { Environment = var.environment })
}

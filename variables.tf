# =========================
# Basics
# =========================
variable "aws_region"            { type = string }               # e.g., us-east-2
variable "aws_access_key"        { type = string }
variable "aws_secret_key"        { type = string }

variable "name" {
  description = "Base name for RDS resources; combined with environment in locals (e.g., <name>-<env>-pg)."
  type        = string
}

variable "remote_state_org"        { type = string }
variable "remote_state_cluster_ws" {
  type = string
  default = null
}
variable "remote_state_vpc_ws"     { type = string }

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

# =========================
# Networking
# =========================
variable "vpc_id" {
  description = "VPC ID for Security Group."
  type        = string
  default     = null
}

variable "db_subnet_ids" {
  description = "Private subnet IDs for DB Subnet Group (2+ AZs recommended)."
  type        = list(string)
  default     = []
}

variable "allowed_sg_ids" {
  description = "Security Group IDs allowed to connect to the DB port."
  type        = list(string)
  default     = []
}

variable "allowed_cidrs" {
  description = "CIDR blocks allowed to connect (use sparingly)."
  type        = list(string)
  default     = []
}

# =========================
# Engine & sizing
# =========================
variable "engine_version" {
  description = "PostgreSQL engine version (e.g., 16.6)."
  type        = string
  default     = "16.6"
}

# Baseline instance class (used if env-specific are not set)
variable "instance_class" {
  description = "Default DB instance class (e.g., db.t4g.micro)."
  type        = string
  default     = "db.t4g.micro"
}

# Optional env-specific overrides (null -> falls back to instance_class)
variable "prod_instance_class" {
  description = "Instance class to use in prod when use_environment_defaults = true. Null -> use instance_class."
  type        = string
  default     = null
}

variable "nonprod_instance_class" {
  description = "Instance class to use in non-prod (dev/stage) when use_environment_defaults = true. Null -> use instance_class."
  type        = string
  default     = null
}

variable "allocated_storage" {
  description = "Initial storage (GiB). Minimum for RDS Postgres is 20."
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Max storage for auto-scaling (GiB). In non-prod we typically set this to null via locals."
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Storage type (gp3 or gp2)."
  type        = string
  default     = "gp3"
}

variable "storage_throughput" {
  description = "gp3 throughput (MiB/s). Null lets AWS choose; do NOT set in non-prod to keep baseline pricing."
  type        = number
  default     = null
}

# =========================
# Operations
# =========================
variable "multi_az" {
  description = "Enable Multi-AZ (costlier). If use_environment_defaults = true, prod -> true, non-prod -> false."
  type        = bool
  default     = false
}

variable "backup_retention_days" {
  description = "Automated backup retention days (used when use_environment_defaults = false)."
  type        = number
  default     = 7
}

variable "maintenance_window" {
  description = "Weekly maintenance window (UTC), e.g., Mon:03:00-Mon:04:00."
  type        = string
  default     = null
}

variable "backup_window" {
  description = "Daily backup window (UTC)."
  type        = string
  default     = null
}

variable "deletion_protection" {
  description = "Protect instance from deletion."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply modifications immediately (may cause restarts)."
  type        = bool
  default     = false
}

variable "auto_minor_version_upgrade" {
  description = "Auto-apply minor engine updates."
  type        = bool
  default     = true
}

variable "enable_performance_insights" {
  description = "Enable Performance Insights. If use_environment_defaults = true, only enabled in prod by default."
  type        = bool
  default     = false
}

variable "performance_insights_retention" {
  description = "PI retention days (7 or 731). Only used when PI is enabled."
  type        = number
  default     = 7
}

# CloudWatch log exports (empty in non-prod via locals when use_environment_defaults = true)
variable "cloudwatch_logs_exports" {
  description = "Which logs to export to CloudWatch (empty list disables)."
  type        = list(string)
  default     = ["postgresql"]
}

# Final snapshot control (typically true in dev/stage to avoid snapshot charges)
variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion (use true for ephemeral non-prod)."
  type        = bool
  default     = false
}

# =========================
# Auth & access
# =========================
variable "master_username" {
  description = "Master username."
  type        = string
  default     = "master"
}

variable "publicly_accessible" {
  description = "Whether the DB is publicly accessible (usually false)."
  type        = bool
  default     = false
}

variable "iam_authentication" {
  description = "Enable IAM authentication for DB logins."
  type        = bool
  default     = false
}

# =========================
# Parameter group
# =========================
variable "create_parameter_group" {
  description = "Create a custom parameter group."
  type        = bool
  default     = true
}

variable "parameters" {
  description = "List of additional DB parameters."
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "pending-reboot")
  }))
  default = [
    # Example: force SSL
    { name = "rds.force_ssl", value = "1", apply_method = "pending-reboot" }
  ]
}

# =========================
# Environment-aware settings
# =========================
variable "environment" {
  description = "Environment name: one of dev, stage, prod."
  type        = string
  validation {
    condition     = contains(["dev","stage","prod"], lower(var.environment))
    error_message = "environment must be one of: dev, stage, prod."
  }
}

variable "use_environment_defaults" {
  description = "If true, auto-derive class, Multi-AZ, PI, log exports, backup retention, and max storage from environment."
  type        = bool
  default     = true
}

variable "prod_backup_retention_days" {
  description = "Production backup retention in days (used when use_environment_defaults = true)."
  type        = number
  default     = 14
}

variable "nonprod_backup_retention_days" {
  description = "Dev/Stage backup retention in days (used when use_environment_defaults = true)."
  type        = number
  default     = 3
}

# Optional nightly stop/start for non-prod (saves cost)
variable "enable_nonprod_stop_schedule" {
  description = "Create EventBridge Scheduler to stop/start non-prod DB nightly."
  type        = bool
  default     = true
}

variable "nonprod_start_cron" {
  description = "Start schedule CRON for non-prod (EventBridge)."
  type        = string
  default     = "cron(0 8 * * ? *)"  # 08:00 local
}

variable "nonprod_stop_cron" {
  description = "Stop schedule CRON for non-prod (EventBridge)."
  type        = string
  default     = "cron(0 23 * * ? *)" # 23:00 local
}

variable "scheduler_timezone" {
  description = "Timezone for the schedules."
  type        = string
  default     = "America/Montevideo"
}

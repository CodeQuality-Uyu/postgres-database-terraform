# Basics
variable "aws_region"            { type = string }               # e.g., us-east-2
variable "aws_access_key"        { type = string }
variable "aws_secret_key"        { type = string }

variable "name" {
  description = "Name prefix for RDS resources (identifier)."
  type        = string
}

variable "remote_state_org" {
  type = string
}

variable "remote_state_cluster_ws" {
  type = string
}

variable "remote_state_vpc_ws" {
  type = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}

# Networking
variable "vpc_id" {
  description = "VPC ID for SG."
  type        = string
}
variable "db_subnet_ids" {
  description = "Private subnet IDs for DB Subnet Group (2+ AZs recommended)."
  type        = list(string)
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

# Engine & sizing
variable "engine_version" {
  description = "PostgreSQL engine version (e.g., 16.3)."
  type        = string
  default     = "16.3"
}
variable "instance_class" {
  description = "DB instance class (e.g., db.t4g.micro)."
  type        = string
  default     = "db.t4g.micro"
}
variable "allocated_storage" {
  description = "Initial storage (GiB)."
  type        = number
  default     = 20
}
variable "max_allocated_storage" {
  description = "Max storage for auto-scaling (GiB)."
  type        = number
  default     = 100
}
variable "storage_type" {
  description = "Storage type (gp3 or gp2)."
  type        = string
  default     = "gp3"
}
variable "storage_throughput" {
  description = "gp3 throughput (MiB/s). Null lets AWS choose."
  type        = number
  default     = null
}

# Ops
variable "multi_az" {
  description = "Enable Multi-AZ (costlier)."
  type        = bool
  default     = false
}
variable "backup_retention_days" {
  description = "Automated backup retention days."
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
  description = "Enable Performance Insights."
  type        = bool
  default     = false
}
variable "performance_insights_retention" {
  description = "PI retention days (7 or 731)."
  type        = number
  default     = 7
}

# Auth
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

# Parameter group
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

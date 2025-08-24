# Basics
variable "aws_region"            { type = string }               # e.g., us-east-2
variable "aws_access_key"        { type = string }
variable "aws_secret_key"        { type = string }
variable "env"                   { type = string }               # dev | prod

# Pull networking from clusters workspace
variable "clusters_org"     { type = string }         # TFC org
variable "clusters_ws_name" { type = string }         # e.g., clusters-dev

# DB identity & sizing
variable "db_name"        { 
  type = string
  default = "postgres"
}
# logical name, e.g. "app"
variable "db_identifier"  {
  type = string
  default = null
}
# optional RDS identifier
variable "engine_version" {
  type = string
  default = "16.3"
}
variable "instance_class" {
  type = string
  default = "db.t4g.micro"
} # use t3.micro if not Graviton

# Storage & durability
variable "allocated_storage"     {
  type = number
  default = 20
}   # GiB
variable "max_allocated_storage" {
  type = number
  default = 100
}  # autoscaling storage
variable "storage_type"          {
  type = string
  default = "gp3"
}
variable "multi_az"              {
  type = bool
  default = false
}  # prod: true
variable "deletion_protection"   {
  type = bool
  default = false
}  # prod: true
variable "backup_retention_days" {
  type = number
  default = 1
}      # prod: >=7
variable "copy_tags_to_snapshot" {
  type = bool
  default = true
}
variable "auto_minor_version_upgrade" {
  type = bool
  default = true
}

# Access
variable "publicly_accessible" {
  type = bool
  default = false
}    # keep private
# Optional: specify CIDR or extra SGs that can reach the DB (besides ECS services SG)
variable "extra_ingress_cidrs" {
  type    = list(string)
  default = []
}

# Secrets handling (SSM Parameter Store paths)
variable "ssm_prefix" {
  description = "Base path for SSM parameters (no trailing slash)."
  type        = string
  default     = "/app"
}

# Optional windows (format: ddd:hh:mm-ddd:hh:mm)
variable "preferred_backup_window"     { # "03:00-04:00"
  type = string
  default = null
}
variable "preferred_maintenance_window" { # "Sun:04:00-Sun:05:00"
  type = string
  default = null
}

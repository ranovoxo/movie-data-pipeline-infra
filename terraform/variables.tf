variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "ml_artifacts_bucket_name" {
  description = "Name of the S3 bucket for storing ML model artifacts"
  type        = string
  default     = "ml-artifacts-prod2"
}

# variable "ami_id" {

#  description = "AMI_ID for the EC2 instance (Ubuntu 20.04 LTS)"
#  type        = string
#  default     = ""
# }


variable "key_name" {
  description = "Name of the existing EC2 Key Pair"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EC2 will be deployed"
  type        = string
}

variable "ec2_name" {
  description = "VPC ID where the EC2 will be deployed"
  type        = string
}

variable "project_name" {
  description = "VPC ID where the EC2 will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for EC2 instance"
  type        = string
}

variable "tmdb_key" {
  description = "Your TMDB API key (for .env injection)"
  type        = string
  default     = ""
}

variable "pipeline_cli_users" {
  description = "All IAM user names that should be in the CLI group"
  type        = list(string)
  sensitive   = true
}

variable "cli_group_name" {
  description = "Name of the IAM group for CLI access"
  type        = string
  sensitive   = true
}

variable "ami_id" {

  description = "Name of the AMI"
  type        = string
  sensitive   = true
}

variable "db_username" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
  default     = "airflow"
}

variable "db_password" {
  description = "Password for the RDS PostgreSQL instance"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Name of the RDS database"
  type        = string
  default     = "airflow"
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = string
  default     = "20"
}

variable "budget_alert_emails" {
  description = "Email addresses to notify when forecasted monthly spend exceeds the budget. Leave empty to disable email alerts."
  type        = list(string)
  default     = []
}

variable "enable_reports_website" {
  description = "Whether to provision the optional public movie reports website hosting resources."
  type        = bool
  default     = false
}

variable "reports_website_name" {
  description = "Name for the Amplify app that hosts the movie reports website."
  type        = string
  default     = "movie-reports-website"
}

variable "reports_website_repository" {
  description = "GitHub repository URL for the reports website, for example https://github.com/ranovoxo/movie-etl-web."
  type        = string
  default     = ""
}

variable "reports_website_branch" {
  description = "Git branch Amplify should deploy for the reports website."
  type        = string
  default     = "main"
}

variable "reports_website_github_access_token" {
  description = "GitHub access token used by Amplify to connect to the reports website repository."
  type        = string
  sensitive   = true
  default     = null
}

variable "reports_website_database_url" {
  description = "Optional server-side PostgreSQL/RDS connection string used by the reports website API routes. Leave empty to derive it from the Terraform-managed RDS instance."
  type        = string
  sensitive   = true
  default     = ""
}

variable "reports_website_pgssl" {
  description = "Whether the reports website should use TLS when connecting to PostgreSQL/RDS."
  type        = bool
  default     = true
}

variable "reports_website_pipeline_label" {
  description = "Public label displayed in the reports website status area."
  type        = string
  default     = "AWS EC2 Airflow"
}

variable "reports_website_stage" {
  description = "Amplify branch stage for the reports website."
  type        = string
  default     = "PRODUCTION"
}

variable "reports_website_environment_variables" {
  description = "Additional environment variables for the reports website Amplify app."
  type        = map(string)
  default     = {}
}

variable "reports_api_subnet_ids" {
  description = "Subnet IDs for the reports API Lambda. Defaults to subnet_id when empty."
  type        = list(string)
  default     = []
}

variable "reports_api_rds_security_group_id" {
  description = "Security group ID attached to RDS that should allow inbound PostgreSQL from the reports API Lambda. Leave empty to skip managing the rule."
  type        = string
  default     = ""
}

variable "reports_api_cors_allow_origin" {
  description = "Allowed CORS origin for the reports API."
  type        = string
  default     = "*"
}

variable "reports_api_memory_size" {
  description = "Memory size for the reports API Lambda."
  type        = number
  default     = 256
}

variable "reports_api_timeout_seconds" {
  description = "Timeout in seconds for the reports API Lambda."
  type        = number
  default     = 15
}

variable "airflow_admin_username" {
  description = "Airflow admin username"
  type        = string
}

variable "airflow_admin_firstname" {
  description = "Airflow admin first name"
  type        = string
}

variable "airflow_admin_lastname" {
  description = "Airflow admin last name"
  type        = string
}

variable "airflow_admin_role" {
  description = "Airflow admin role (e.g., Admin)"
  type        = string
  default     = "Admin"
}

variable "airflow_admin_email" {
  description = "Airflow admin email address"
  type        = string
}

variable "airflow_admin_password" {
  description = "Airflow admin password"
  type        = string
  sensitive   = true
}

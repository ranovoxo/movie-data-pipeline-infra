variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
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

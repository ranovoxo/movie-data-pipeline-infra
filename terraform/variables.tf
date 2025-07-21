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
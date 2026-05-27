output "pipeline_ip" {
  description = "Elastic IP address of the EC2 instance running the pipeline"
  value       = aws_eip.pipeline_ip.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.pipeline.id
}

output "security_group_id" {
  description = "Security group ID for SSH and Airflow UI"
  value       = aws_security_group.pipeline_sg.id
}

output "rds_endpoint" {
  description = "Endpoint of the PostgreSQL RDS instance"
  value       = aws_db_instance.postgres.endpoint
}

output "ml_artifacts_bucket_name" {
  description = "Name of the S3 bucket for ML artifacts"
  value       = aws_s3_bucket.ml_artifacts.bucket
}

output "ml_artifacts_bucket_arn" {
  description = "ARN of the S3 bucket for ML artifacts"
  value       = aws_s3_bucket.ml_artifacts.arn
}

output "reports_website_amplify_app_id" {
  description = "Amplify app ID for the optional reports website"
  value       = var.enable_reports_website ? aws_amplify_app.reports_website[0].id : null
}

output "reports_website_default_domain" {
  description = "Default Amplify domain for the optional reports website"
  value       = var.enable_reports_website ? aws_amplify_app.reports_website[0].default_domain : null
}

output "reports_website_branch_url" {
  description = "Deployed branch URL for the optional reports website"
  value       = var.enable_reports_website ? "https://${var.reports_website_branch}.${aws_amplify_app.reports_website[0].default_domain}" : null
}

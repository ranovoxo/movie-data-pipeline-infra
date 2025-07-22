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

output "dags_bucket_name" {
  description = "S3 bucket storing Airflow DAGs"
  value       = aws_s3_bucket.dags.bucket
}

output "backups_bucket_name" {
  description = "S3 bucket for backups"
  value       = aws_s3_bucket.backups.bucket
}

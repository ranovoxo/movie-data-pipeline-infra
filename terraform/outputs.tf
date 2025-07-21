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
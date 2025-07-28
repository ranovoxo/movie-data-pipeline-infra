# Movie Data Pipeline Infrastructure

This repository contains Terraform configurations for provisioning the AWS infrastructure required to run the [movie-data-pipeline](https://github.com/ranovoxo/movie-data-pipeline) project. The resources defined here create an EC2 instance that runs Docker Compose for Airflow, a PostgreSQL RDS database, S3 buckets for DAG storage and backups, IAM roles, and a monthly cost budget.

## Requirements

- Terraform >= 1.0
- An AWS account with appropriate permissions
- An existing EC2 key pair, VPC and subnet for the instance

## Project Structure

- **terraform/** – all Terraform configuration files
  - `main.tf` declares the required Terraform version and AWS provider
  - `provider.tf` configures the AWS region
  - `variables.tf` defines input variables for customizing the deployment
  - `ec2.tf` launches an EC2 instance and bootstraps the pipeline with Docker Compose
  - `iam.tf` sets up IAM roles and an instance profile
  - `rds.tf` provisions a PostgreSQL database and stores the password in Parameter Store
  - `storage.tf` creates S3 buckets and a monthly cost budget
  - `outputs.tf` exports useful values such as the instance IP and RDS endpoint

## Usage

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Review the execution plan:

   ```bash
   terraform plan -var="key_name=<ec2-key>" \
                  -var="vpc_id=<vpc-id>" \
                  -var="subnet_id=<subnet-id>" \
                  -var="pipeline_cli_users=[\"<iam-user>\"]" \
                  -var="cli_group_name=<cli-group>" \
                  -var="ami_id=<ami-id>" \
                  -var="db_password=<db-password>" \
                  -var="dags_bucket_name=<bucket-name>" \
                  -var="backups_bucket_name=<bucket-name>"
   ```

3. Apply the configuration:

   ```bash
   terraform apply
   ```

After provisioning, Terraform outputs the public IP of the EC2 instance along with other useful identifiers.

## Variables

Key variables for the deployment are defined in `terraform/variables.tf`. Examples include:

- `aws_region` – AWS region to deploy into (default: `us-east-1`)
- `key_name` – existing EC2 key pair name
- `dags_bucket_name` – S3 bucket name for Airflow DAGs
- `backups_bucket_name` – S3 bucket name for backups
- `budget_limit` – monthly cost limit in USD

See the variables file for the full list and descriptions.

## Outputs

Running `terraform apply` will produce values such as the instance ID, Elastic IP address, and RDS endpoint. These outputs are defined in `terraform/outputs.tf`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.


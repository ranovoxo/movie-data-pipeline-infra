# Movie Data Pipeline Infrastructure

This repository contains Terraform configurations for provisioning the AWS infrastructure required to run the [movie-data-pipeline](https://github.com/ranovoxo/movie-data-pipeline) project. The configuration spins up an EC2 instance to host the Airflow pipeline, a PostgreSQL RDS database, IAM roles and group membership, and a monthly cost budget.

### Resources Provisioned

* **EC2 instance** – Ubuntu 20.04 host bootstrapped with Docker and the pipeline via a user-data script. An Elastic IP and security group (SSH + Airflow UI) are attached.
* **RDS PostgreSQL** – database instance with credentials stored in AWS Systems Manager Parameter Store.
* **IAM** – instance role with SSM + KMS permissions and membership for a pre-existing CLI group.
* **Budget** – monthly cost budget to keep spending under control.

## Requirements

- Terraform >= 1.0
- An AWS account with credentials configured for the AWS CLI
- Existing VPC, subnet and EC2 key pair for the instance
- A pre-created IAM group for CLI users (`cli_group_name`)
- Required secrets stored in SSM Parameter Store (see [Bootstrap script](#bootstrap-script))

## Project Structure

- **terraform/** – all Terraform configuration files
  - `main.tf` declares the required Terraform version and AWS provider
  - `provider.tf` configures the AWS region
  - `variables.tf` defines input variables for customizing the deployment
  - `ec2.tf` launches an EC2 instance and bootstraps the pipeline with Docker Compose
  - `ec2_user_data.sh.tpl` shell script executed on first boot to install Docker, fetch secrets and start the services
  - `iam.tf` sets up IAM roles and an instance profile
  - `rds.tf` provisions a PostgreSQL database and stores the password in Parameter Store
  - `storage.tf` defines a monthly cost budget
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
                   -var="db_password=<db-password>"
   ```

3. Apply the configuration:

   ```bash
   terraform apply
   ```

4. (Optional) Tear everything down when finished:

   ```bash
   terraform destroy
   ```

After provisioning, Terraform outputs the public IP of the EC2 instance along with other useful identifiers.

## Bootstrap script

The `ec2_user_data.sh.tpl` template is rendered with database connection details and executed on the EC2 instance at launch. The script:

1. Installs Docker and Docker Compose
2. Clones the pipeline repository and pulls the latest changes
3. Retrieves secrets (database credentials, pgAdmin login, export paths, etc.) from SSM Parameter Store
4. Writes these values to a `.env` file and starts the Docker Compose stack

## Variables

Key variables for the deployment are defined in `terraform/variables.tf`. Examples include:

- `aws_region` – AWS region to deploy into (default: `us-east-1`)
- `key_name` – existing EC2 key pair name
- `vpc_id` / `subnet_id` – networking for the EC2 instance
- `pipeline_cli_users` – list of IAM users to add to the CLI group
- `cli_group_name` – existing IAM group for pipeline CLI access
- `db_username`, `db_password`, `db_name` – RDS database credentials
- `budget_limit` – monthly cost limit in USD

See the variables file for the full list and descriptions.

## Outputs

Running `terraform apply` will produce values such as the instance ID, Elastic IP address, and RDS endpoint. These outputs are defined in `terraform/outputs.tf`.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.


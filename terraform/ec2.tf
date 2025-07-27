# Data source to fetch the latest Ubuntu 20.04 LTS AMI
data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]  # Canonical’s AWS account ID
}

# Security Group for SSH & Airflow UI
resource "aws_security_group" "pipeline_sg" {
  name        = "movie-pipeline-sg"
  description = "Allow SSH and Airflow UI"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Airflow UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance using the looked-up AMI
resource "aws_instance" "pipeline" {
  ami                         = data.aws_ami.ubuntu_focal.id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.pipeline_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.pipeline_profile.name

  # ------------------------------------------------------------
  # user_data to fully bootstrap the repo & Docker Compose stack
  # ------------------------------------------------------------
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # Install prerequisites
    apt-get update
    # Install Docker and supporting tools
    apt-get install -y docker.io docker-compose git awscli jq
    systemctl enable docker
    systemctl start docker

    # Allow ubuntu user to run docker
    usermod -aG docker ubuntu

    # Clone the pipeline repository
    mkdir -p /home/ubuntu/app
    chown ubuntu:ubuntu /home/ubuntu/app
    sudo -u ubuntu git clone https://github.com/ranovoxo/movie-data-pipeline.git /home/ubuntu/app

    cd /home/ubuntu/app
    # Fetch parameters from AWS SSM Parameter Store and write to .env
    cat <<EOT > /home/ubuntu/app/.env
POSTGRES_USER=$(aws ssm get-parameter --name /movie-app/prod/postgres/POSTGRES_USER --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
POSTGRES_PW=$(aws ssm get-parameter --name /movie-app/prod/postgres/POSTGRES_PW --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
POSTGRES_DB=$(aws ssm get-parameter --name /movie-app/prod/postgres/POSTGRES_DB --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
PGADMIN_DEFAULT_EMAIL=$(aws ssm get-parameter --name /movie-app/prod/pgadmin/PGADMIN_DEFAULT_EMAIL --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
PGADMIN_DEFAULT_PASSWORD=$(aws ssm get-parameter --name /movie-app/prod/pgadmin/PGADMIN_DEFAULT_PASSWORD --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
TABLEAU_EXPORT_PATH=$(aws ssm get-parameter --name /movie-app/prod/export/TABLEAU_EXPORT_PATH --with-decryption --query Parameter.Value --output text --region ${var.aws_region})
EOT

    export POSTGRES_HOST=${aws_db_instance.postgres.address}

    # Start Airflow
    docker-compose up -d
  EOF

  tags = {
    Name = "movie-pipeline"
  }
}

# Elastic IP for a stable public endpoint
resource "aws_eip" "pipeline_ip" {
  instance = aws_instance.pipeline.id
  domain   = "vpc"
}

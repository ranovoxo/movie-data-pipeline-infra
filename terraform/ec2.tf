
# Data source to fetch the latest Ubuntu 20.04 LTS AMI
data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}

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

resource "aws_instance" "pipeline" {
  ami                         = data.aws_ami.ubuntu_focal.id
  instance_type               = "t3.micro"
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.pipeline_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.pipeline_profile.name

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # Install prerequisites
    apt-get update
    apt-get install -y docker.io git awscli jq curl
    systemctl enable docker
    systemctl start docker

    # Install Docker Compose v2 standalone binary
    curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 \
      -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    # Symlink so 'docker-compose' is on root's PATH
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    # Allow ubuntu user to run Docker
    usermod -aG docker ubuntu

    # Export AWS region for aws CLI
    export AWS_DEFAULT_REGION=${var.aws_region}

    # Clone or update the pipeline repo
    APP_DIR=/home/ubuntu/app
    REPO=https://github.com/ranovoxo/movie-data-pipeline-cloud.git
    mkdir -p "$${APP_DIR}"
    chown ubuntu:ubuntu "$${APP_DIR}"
    
    if [ ! -d "$${APP_DIR}/.git" ]; then
      sudo -u ubuntu git clone "$${REPO}" "$${APP_DIR}"
    else
      cd "$${APP_DIR}"
      sudo -u ubuntu git pull origin main
    fi
    cd "$${APP_DIR}"

    # Retry helper for SSM SecureString fetches
    fetch() {
      until aws ssm get-parameter --name "$1" --with-decryption \
            --query Parameter.Value --output text; do
        echo "Waiting for parameter $1…" >&2
        sleep 5
      done
    }

    # Write .env with decrypted values
    cat <<EOT > "$${APP_DIR}/.env"
    POSTGRES_USER=$(fetch /movie-app/prod/postgres/POSTGRES_USER)
    POSTGRES_PW=$(fetch /movie-app/prod/postgres/POSTGRES_PW)
    POSTGRES_DB=$(fetch /movie-app/prod/postgres/POSTGRES_DB)
    PGADMIN_DEFAULT_EMAIL=$(fetch /movie-app/prod/pgadmin/PGADMIN_DEFAULT_EMAIL)
    PGADMIN_DEFAULT_PASSWORD=$(fetch /movie-app/prod/pgadmin/PGADMIN_DEFAULT_PASSWORD)
    TABLEAU_EXPORT_PATH=$(fetch /movie-app/prod/export/TABLEAU_EXPORT_PATH)
    EOT

    # Point to your RDS host (Terraform will substitute the address)
    export POSTGRES_HOST=${aws_db_instance.postgres.address}

    # Bring up the Docker Compose services
    docker-compose up -d
  EOF


  tags = {
    Name = "movie-pipeline"
  }

  # To minimize downtime on replacement:
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "pipeline_ip" {
  instance = aws_instance.pipeline.id
  domain   = "vpc"
}

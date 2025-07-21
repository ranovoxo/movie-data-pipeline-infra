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

  # ------------------------------------------------------------
  # user_data to fully bootstrap the repo & Docker Compose stack
  # ------------------------------------------------------------
  user_data = <<-EOF
    #!/bin/bash
    set -e

    # 1. Install prerequisites
    apt-get update
    apt-get install -y docker.io docker-compose git

    # 2. Add ubuntu user to docker group
    usermod -aG docker ubuntu

    # 3. Clone your pipeline repo
    mkdir -p /home/ubuntu/app
    chown ubuntu:ubuntu /home/ubuntu/app
    sudo -u ubuntu git clone https://github.com/ranovoxo/movie-data-pipeline.git /home/ubuntu/app

    # 4. Copy .env template to .env
    cd /home/ubuntu/app
    if [ -f .env.template ]; then
      sudo -u ubuntu cp .env.template .env
      # Optionally inject real values here via envsubst or similar
      # e.g. sudo -u ubuntu sed -i "s/TMDB_API_KEY=.*/TMDB_API_KEY=${var.tmdb_key}/" .env
    fi

    # 5. Launch the Docker Compose stack
    cd /home/ubuntu/app
    sudo -u ubuntu docker-compose up -d --build
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

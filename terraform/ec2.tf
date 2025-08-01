# Data source to fetch the latest Ubuntu 20.04 LTS AMI
data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"]
}


resource "aws_instance" "pipeline" {
  ami                         = data.aws_ami.ubuntu_focal.id
  instance_type               = "t3.medium"
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.pipeline_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.pipeline_profile.name

  user_data = templatefile("${path.module}/ec2_user_data.sh.tpl", {
    aws_region        = var.aws_region
    postgres_host     = aws_db_instance.postgres.address
    postgres_port     = aws_db_instance.postgres.port
    airflow_admin_username  = var.airflow_admin_username
    airflow_admin_firstname = var.airflow_admin_firstname
    airflow_admin_lastname  = var.airflow_admin_lastname
    airflow_admin_role      = var.airflow_admin_role
    airflow_admin_email     = var.airflow_admin_email
    airflow_admin_password  = var.airflow_admin_password
  })

  tags = {
    Name = "movie-pipeline"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_eip" "pipeline_ip" {
  instance = aws_instance.pipeline.id
  domain   = "vpc"
}
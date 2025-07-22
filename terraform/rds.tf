# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier              = "movie-postgres"
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "14"
  instance_class          = "db.t3.micro"
  username                = var.db_username
  password                = aws_ssm_parameter.db_password.value
  db_name                 = var.db_name
  publicly_accessible     = true
  skip_final_snapshot     = true
}

# SSM parameter to store DB password
resource "aws_ssm_parameter" "db_password" {
  name  = "/movie/db_password"
  type  = "SecureString"
  value = var.db_password
}

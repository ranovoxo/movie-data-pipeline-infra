locals {
  reports_api_name         = "${var.project_name}-reports-api"
  reports_api_database_url = var.reports_website_database_url != "" ? var.reports_website_database_url : "postgresql://${urlencode(var.db_username)}:${urlencode(var.db_password)}@${aws_db_instance.postgres.address}:${aws_db_instance.postgres.port}/${var.db_name}?sslmode=require"
  reports_api_subnet_ids   = length(var.reports_api_subnet_ids) > 0 ? var.reports_api_subnet_ids : [var.subnet_id]
}

resource "null_resource" "reports_api_dependencies" {
  triggers = {
    package_json      = filemd5("${path.module}/../lambda/reports-api/package.json")
    package_lock_json = fileexists("${path.module}/../lambda/reports-api/package-lock.json") ? filemd5("${path.module}/../lambda/reports-api/package-lock.json") : ""
    source            = filemd5("${path.module}/../lambda/reports-api/index.mjs")
  }

  provisioner "local-exec" {
    command     = "npm install --omit=dev"
    working_dir = "${path.module}/../lambda/reports-api"
  }
}

data "archive_file" "reports_api" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/reports-api"
  output_path = "${path.module}/.terraform/reports-api.zip"

  excludes = [
    "package-lock.json"
  ]

  depends_on = [null_resource.reports_api_dependencies]
}

resource "aws_security_group" "reports_api_lambda" {
  name        = "${local.reports_api_name}-sg"
  description = "Allow the reports API Lambda to reach PostgreSQL"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Service = "movie-reports-api"
  }
}

resource "aws_security_group_rule" "reports_api_to_rds" {
  count = var.reports_api_rds_security_group_id != "" ? 1 : 0

  type                     = "ingress"
  description              = "Allow reports API Lambda to query PostgreSQL"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = var.reports_api_rds_security_group_id
  source_security_group_id = aws_security_group.reports_api_lambda.id
}

resource "aws_iam_role" "reports_api_lambda" {
  name = "${local.reports_api_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "reports_api_lambda_basic" {
  role       = aws_iam_role.reports_api_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "reports_api_lambda_vpc" {
  role       = aws_iam_role.reports_api_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_lambda_function" "reports_api" {
  function_name    = local.reports_api_name
  role             = aws_iam_role.reports_api_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.reports_api.output_path
  source_code_hash = data.archive_file.reports_api.output_base64sha256
  timeout          = var.reports_api_timeout_seconds
  memory_size      = var.reports_api_memory_size

  vpc_config {
    subnet_ids         = local.reports_api_subnet_ids
    security_group_ids = [aws_security_group.reports_api_lambda.id]
  }

  environment {
    variables = {
      DATABASE_URL      = local.reports_api_database_url
      PGSSL             = tostring(var.reports_website_pgssl)
      CORS_ALLOW_ORIGIN = var.reports_api_cors_allow_origin
      PGPOOL_MAX        = "2"
    }
  }

  tags = {
    Project = var.project_name
    Service = "movie-reports-api"
    Cost    = "low-idle"
  }
}

resource "aws_apigatewayv2_api" "reports_api" {
  name          = local.reports_api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["content-type"]
    allow_methods = ["GET", "OPTIONS"]
    allow_origins = [var.reports_api_cors_allow_origin]
    max_age       = 300
  }

  tags = {
    Project = var.project_name
    Service = "movie-reports-api"
  }
}

resource "aws_apigatewayv2_integration" "reports_api" {
  api_id                 = aws_apigatewayv2_api.reports_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.reports_api.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "reports_api" {
  api_id    = aws_apigatewayv2_api.reports_api.id
  route_key = "GET /api/reports/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.reports_api.id}"
}

resource "aws_apigatewayv2_route" "reports_api_options" {
  api_id    = aws_apigatewayv2_api.reports_api.id
  route_key = "OPTIONS /api/reports/{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.reports_api.id}"
}

resource "aws_apigatewayv2_stage" "reports_api" {
  api_id      = aws_apigatewayv2_api.reports_api.id
  name        = "$default"
  auto_deploy = true

  tags = {
    Project = var.project_name
    Service = "movie-reports-api"
  }
}

resource "aws_lambda_permission" "reports_api_gateway" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reports_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.reports_api.execution_arn}/*/*"
}

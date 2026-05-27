# Optional low-cost hosting for the public movie reports website.
#
# This uses AWS Amplify Hosting for the Next.js frontend and server-side API
# routes, avoiding another always-on EC2 instance for the website.
resource "aws_amplify_app" "reports_website" {
  count = var.enable_reports_website ? 1 : 0

  name         = var.reports_website_name
  repository   = var.reports_website_repository
  access_token = var.reports_website_github_access_token
  platform     = "WEB_COMPUTE"

  build_spec = <<-YAML
    version: 1
    frontend:
      phases:
        preBuild:
          commands:
            - npm ci
        build:
          commands:
            - npm run build
      artifacts:
        baseDirectory: .next
        files:
          - "**/*"
      cache:
        paths:
          - node_modules/**/*
  YAML

  environment_variables = merge(
    {
      DATABASE_URL               = var.reports_website_database_url
      PGSSL                      = tostring(var.reports_website_pgssl)
      NEXT_PUBLIC_PIPELINE_LABEL = var.reports_website_pipeline_label
    },
    var.reports_website_environment_variables
  )

  custom_rule {
    source = "/<*>"
    status = "404-200"
    target = "/index.html"
  }

  tags = {
    Project = var.project_name
    Service = "movie-reports-website"
    Cost    = "low-idle"
  }

  lifecycle {
    precondition {
      condition     = var.reports_website_repository != ""
      error_message = "reports_website_repository must be set when enable_reports_website is true."
    }

    precondition {
      condition     = var.reports_website_github_access_token != null && var.reports_website_github_access_token != ""
      error_message = "reports_website_github_access_token must be set when enable_reports_website is true."
    }
  }
}

resource "aws_amplify_branch" "reports_website" {
  count = var.enable_reports_website ? 1 : 0

  app_id            = aws_amplify_app.reports_website[0].id
  branch_name       = var.reports_website_branch
  enable_auto_build = true
  framework         = "Next.js - SSR"
  stage             = var.reports_website_stage

  environment_variables = merge(
    {
      DATABASE_URL               = var.reports_website_database_url
      PGSSL                      = tostring(var.reports_website_pgssl)
      NEXT_PUBLIC_PIPELINE_LABEL = var.reports_website_pipeline_label
    },
    var.reports_website_environment_variables
  )

  tags = {
    Project = var.project_name
    Service = "movie-reports-website"
    Cost    = "low-idle"
  }
}

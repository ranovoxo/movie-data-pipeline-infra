# S3 bucket for Airflow DAGs
resource "aws_s3_bucket" "dags" {
  bucket = var.dags_bucket_name
}

# S3 bucket for backups
resource "aws_s3_bucket" "backups" {
  bucket = var.backups_bucket_name
}

# Budget for cost control
resource "aws_budgets_budget" "monthly" {
  name         = "MonthlyBudget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}

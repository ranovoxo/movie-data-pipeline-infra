# Budget for cost control
resource "aws_budgets_budget" "monthly" {
  name         = "MonthlyBudget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"
}

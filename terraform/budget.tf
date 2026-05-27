# Budget for cost control
resource "aws_budgets_budget" "monthly" {
  name         = "MonthlyBudget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = length(var.budget_alert_emails) > 0 ? [1] : []

    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = 80
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = var.budget_alert_emails
    }
  }
}

# Ensure you're referencing attributes that exist on data sources:

data "aws_iam_group" "cli_group" {
  group_name = var.cli_group_name
}

resource "aws_iam_group_membership" "cli_group_membership" {
  name   = "pipeline-cli-membership"
  group  = data.aws_iam_group.cli_group.group_name
  users  = var.pipeline_cli_users
}
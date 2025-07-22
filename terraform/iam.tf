
data "aws_iam_group" "cli_group" {
  group_name = var.cli_group_name
}

resource "aws_iam_group_membership" "cli_group_membership" {
  name   = "pipeline-cli-membership"
  group  = data.aws_iam_group.cli_group.group_name
  users  = var.pipeline_cli_users
}

# IAM role for the EC2 instance so that bootstrap scripts can
# access Parameter Store to fetch secrets like the database password.
resource "aws_iam_role" "pipeline_instance_role" {
  name = "pipeline-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Give the instance read access to SSM parameters
resource "aws_iam_role_policy_attachment" "pipeline_ssm" {
  role       = aws_iam_role.pipeline_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}

resource "aws_iam_instance_profile" "pipeline_profile" {
  name = "pipeline-instance-profile"
  role = aws_iam_role.pipeline_instance_role.name
}
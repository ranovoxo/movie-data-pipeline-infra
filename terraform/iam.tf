
data "aws_iam_group" "cli_group" {
  group_name = var.cli_group_name
}

resource "aws_iam_group_membership" "cli_group_membership" {
  name  = "pipeline-cli-membership"
  group = data.aws_iam_group.cli_group.group_name
  users = var.pipeline_cli_users
}

# IAM role for the EC2 instance so that bootstrap scripts can
# access Parameter Store to fetch secrets like the database password.
resource "aws_iam_role" "pipeline_instance_role" {
  name = "pipeline-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach AWS-managed policy for read-only SSM access
resource "aws_iam_role_policy_attachment" "pipeline_ssm" {
  role       = aws_iam_role.pipeline_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}


# Inline policy granting KMS Decrypt on that key
resource "aws_iam_role_policy" "pipeline_kms_decrypt" {
  name = "pipeline-kms-decrypt"
  role = aws_iam_role.pipeline_instance_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["kms:Decrypt"]
      Resource = "arn:aws:kms:us-east-1:030878370508:key/52ce5ee6-e85b-49e8-9db6-0067e291a016"   
    }]
  })
}

resource "aws_iam_instance_profile" "pipeline_profile" {
  name = "pipeline-instance-profile"
  role = aws_iam_role.pipeline_instance_role.name
}
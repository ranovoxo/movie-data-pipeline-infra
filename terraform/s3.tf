resource "aws_s3_bucket" "ml_artifacts" {
  provider = aws.us_east_1
  bucket   = var.ml_artifacts_bucket_name
}

resource "aws_s3_bucket_versioning" "ml_artifacts" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.ml_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ml_artifacts" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.ml_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = "alias/aws/s3"
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ml_artifacts" {
  provider                = aws.us_east_1
  bucket                  = aws_s3_bucket.ml_artifacts.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "ml_artifacts" {
  provider = aws.us_east_1
  bucket   = aws_s3_bucket.ml_artifacts.id

  rule {
    id     = "ml-artifacts-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_transition {
      noncurrent_days = 90
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

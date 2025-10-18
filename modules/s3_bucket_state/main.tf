resource "random_string" "s3_bucket_suffix" {
  length  = 9
  upper   = false
  special = false
}

locals {
  state_bucket = "${var.bucket_suffix_name}-${random_string.s3_bucket_suffix.result}"
}

################################################################################
# Remote state storage (S3) + state locking (DynamoDB)
################################################################################

# S3 bucket for Terraform state
resource "aws_s3_bucket" "tf_state" {
  bucket        = local.state_bucket
  force_destroy = true

  tags = {
    Name        = local.state_bucket
    Terraform   = "true"
    Environment = "dev"
  }
}

# Required by newer provider versions before setting ACLs
resource "aws_s3_bucket_ownership_controls" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning to protect state history
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Default server-side encryption (SSE-S3). Use KMS if you prefer.
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# (Optional) Lifecycle: clean up incomplete uploads
resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    id     = "abort-multipart-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tf_locks" {
  count        = var.create_lock_table ? 1 : 0
  name         = var.lock_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = var.lock_table
    Terraform   = "true"
    Environment = "dev"
  }
}

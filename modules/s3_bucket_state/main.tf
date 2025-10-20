locals {
  s3_bucket_suffix          = "77g78ef5w"
  state_bucket              = "${var.bucket_prefix_name}-${local.s3_bucket_suffix}"
  backend_key_effective     = var.state_key

  s3_bucket_id_effective    = var.create_bucket     ? aws_s3_bucket.tf_state[0].id : var.existing_bucket_name
  lock_table_name_effective = var.create_lock_table ? aws_dynamodb_table.tf_locks[0].name : var.existing_lock_table
}

# 1) Bucket
resource "aws_s3_bucket" "tf_state" {
  count         = var.create_bucket ? 1 : 0
  bucket        = local.state_bucket
  force_destroy = true

  tags = {
    Name        = local.state_bucket
    Terraform   = "true"
    Environment = "dev"
  }
}

# 2) Dependents — use the SAME count and reference index [0]
resource "aws_s3_bucket_ownership_controls" "tf_state" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  count                   = var.create_bucket ? 1 : 0
  bucket                  = aws_s3_bucket.tf_state[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "tf_state" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "tf_state" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.tf_state[0].id
  rule {
    id     = "abort-multipart-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_dynamodb_table" "tf_locks" { 
  count = (var.lock_table != "" && var.create_lock_table) ? 1 : 0 
  name = var.lock_table 
  billing_mode = "PAY_PER_REQUEST" 
  hash_key = "LockID" 
  attribute { 
    name = "LockID" 
    type = "S" 
  } 
  tags = { 
    Name = var.lock_table 
    Terraform = "true" 
    Environment = "dev"
  } 
}

# Effective names: single source of truth for consumers
locals {
  s3_bucket_id_effective    = var.create_bucket     ? aws_s3_bucket.tf_state[0].id : var.existing_bucket_name
  lock_table_name_effective = var.create_lock_table ? aws_dynamodb_table.tf_locks[0].name : var.existing_lock_table
}
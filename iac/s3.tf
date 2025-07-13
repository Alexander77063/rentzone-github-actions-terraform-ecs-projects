# create an s3 bucket 
resource "aws_s3_bucket" "env_file_bucket_1" {
  bucket = "rentzone-an-rentzone-app-env-file-bucket-${random_id.bucket_suffix.hex}"
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# upload the environment file from local computer into the s3 bucket
resource "aws_s3_object" "upload_env_file" {
  bucket = aws_s3_bucket.env_file_bucket_1.id
  key    = var.env_file_name
  source = "./${var.env_file_name}"
}
# Add this to your Terraform configuration (main.tf or s3.tf)

# S3 bucket for storing environment files
resource "aws_s3_bucket" "env_file_bucket" {
  bucket = "${var.project_name}-env-files-${random_string.s3_suffix.result}"
}

# Random string to make bucket name unique
resource "random_string" "s3_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Block public access
resource "aws_s3_bucket_public_access_block" "env_file_bucket_pab" {
  bucket = aws_s3_bucket.env_file_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "env_file_bucket_versioning" {
  bucket = aws_s3_bucket.env_file_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "env_file_bucket_encryption" {
  bucket = aws_s3_bucket.env_file_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
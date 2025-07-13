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

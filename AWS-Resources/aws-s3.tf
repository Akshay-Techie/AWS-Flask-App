provider "aws" {
  region = var.region
}

resource "random_id" "bucket_id" {
  byte_length = 6
}

resource "aws_s3_bucket" "mybucket" {
  bucket = "logs-s3-bucket-${random_id.bucket_id.hex}"
}

# ✅ Block ALL public access
resource "aws_s3_bucket_public_access_block" "mybucket_public_access" {
  bucket = aws_s3_bucket.mybucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ✅ Enable Versioning
resource "aws_s3_bucket_versioning" "mybucket_versioning" {
  bucket = aws_s3_bucket.mybucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "bucket_data" {
  bucket = aws_s3_bucket.mybucket.bucket
  source = "myfile.txt"
  key    = "mylogs.txt"
}

output "ID" {
  value = random_id.bucket_id.hex
}
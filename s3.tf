data "aws_s3_bucket" "concourse_keys" {
  bucket = var.key_bucket_name
}

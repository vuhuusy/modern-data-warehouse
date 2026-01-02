################################################################################
# Bucket Identifiers
################################################################################

output "bucket_id" {
  description = "The name of the bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_name" {
  description = "The name of the bucket (alias for bucket_id)."
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "The ARN of the bucket."
  value       = aws_s3_bucket.this.arn
}

################################################################################
# Bucket Domain Names
################################################################################

output "bucket_regional_domain_name" {
  description = "The regional domain name of the bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_domain_name" {
  description = "The bucket domain name."
  value       = aws_s3_bucket.this.bucket_domain_name
}

################################################################################
# Bucket Region
################################################################################

output "bucket_region" {
  description = "The AWS region where the bucket is located."
  value       = aws_s3_bucket.this.region
}

################################################################################
# Bucket Policy
################################################################################

output "bucket_policy" {
  description = "The bucket policy JSON (if attached)."
  value       = local.attach_any_policy ? data.aws_iam_policy_document.combined[0].json : null
}

################################################################################
# Versioning Status
################################################################################

output "versioning_status" {
  description = "The versioning status of the bucket."
  value       = aws_s3_bucket_versioning.this.versioning_configuration[0].status
}

################################################################################
# Encryption Configuration
################################################################################

output "encryption_algorithm" {
  description = "The server-side encryption algorithm used."
  value       = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].sse_algorithm
}

output "encryption_kms_key_id" {
  description = "The KMS key ID used for encryption (if applicable)."
  value       = aws_s3_bucket_server_side_encryption_configuration.this.rule[0].apply_server_side_encryption_by_default[0].kms_master_key_id
}

################################################################################
# S3 URI
################################################################################

output "s3_uri" {
  description = "The S3 URI for the bucket (s3://bucket-name)."
  value       = "s3://${aws_s3_bucket.this.bucket}"
}

################################################################################
# Tags
################################################################################

output "tags" {
  description = "The tags applied to the bucket."
  value       = aws_s3_bucket.this.tags_all
}

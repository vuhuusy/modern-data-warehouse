################################################################################
# Outputs - Development Environment
################################################################################

#------------------------------------------------------------------------------
# Raw Data Bucket
#------------------------------------------------------------------------------

output "raw_bucket_name" {
  description = "Name of the raw data S3 bucket."
  value       = module.raw_bucket.bucket_name
}

output "raw_bucket_arn" {
  description = "ARN of the raw data S3 bucket."
  value       = module.raw_bucket.bucket_arn
}

output "raw_bucket_s3_uri" {
  description = "S3 URI for the raw data bucket."
  value       = module.raw_bucket.s3_uri
}

#------------------------------------------------------------------------------
# Curated Data Bucket
#------------------------------------------------------------------------------

output "curated_bucket_name" {
  description = "Name of the curated data S3 bucket."
  value       = module.curated_bucket.bucket_name
}

output "curated_bucket_arn" {
  description = "ARN of the curated data S3 bucket."
  value       = module.curated_bucket.bucket_arn
}

output "curated_bucket_s3_uri" {
  description = "S3 URI for the curated data bucket."
  value       = module.curated_bucket.s3_uri
}

#------------------------------------------------------------------------------
# MWAA Artifacts Bucket
#------------------------------------------------------------------------------

output "mwaa_artifacts_bucket_name" {
  description = "Name of the MWAA artifacts S3 bucket."
  value       = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_name : null
}

output "mwaa_artifacts_bucket_arn" {
  description = "ARN of the MWAA artifacts S3 bucket."
  value       = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_arn : null
}

output "mwaa_artifacts_bucket_s3_uri" {
  description = "S3 URI for the MWAA artifacts bucket."
  value       = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].s3_uri : null
}

#------------------------------------------------------------------------------
# Athena Results Bucket
#------------------------------------------------------------------------------

output "athena_results_bucket_name" {
  description = "Name of the Athena query results S3 bucket."
  value       = module.athena_results_bucket.bucket_name
}

output "athena_results_bucket_arn" {
  description = "ARN of the Athena query results S3 bucket."
  value       = module.athena_results_bucket.bucket_arn
}

output "athena_results_bucket_s3_uri" {
  description = "S3 URI for the Athena query results bucket."
  value       = module.athena_results_bucket.s3_uri
}

#------------------------------------------------------------------------------
# Access Logs Bucket (Conditional)
#------------------------------------------------------------------------------

output "access_logs_bucket_name" {
  description = "Name of the access logs S3 bucket (if enabled)."
  value       = var.enable_access_logging ? module.access_logs_bucket[0].bucket_name : null
}

output "access_logs_bucket_arn" {
  description = "ARN of the access logs S3 bucket (if enabled)."
  value       = var.enable_access_logging ? module.access_logs_bucket[0].bucket_arn : null
}

#------------------------------------------------------------------------------
# Summary Output
#------------------------------------------------------------------------------

output "all_bucket_arns" {
  description = "List of all S3 bucket ARNs for IAM policy creation."
  value = compact([
    module.raw_bucket.bucket_arn,
    module.curated_bucket.bucket_arn,
    var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_arn : "",
    module.athena_results_bucket.bucket_arn,
    var.enable_access_logging ? module.access_logs_bucket[0].bucket_arn : ""
  ])
}

output "data_lake_config" {
  description = "Data lake configuration for downstream services."
  value = {
    raw_bucket      = module.raw_bucket.bucket_name
    curated_bucket  = module.curated_bucket.bucket_name
    athena_results  = module.athena_results_bucket.bucket_name
    mwaa_artifacts  = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_name : null
    region          = var.aws_region
    environment     = var.environment
  }
}

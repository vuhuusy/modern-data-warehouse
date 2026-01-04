################################################################################
# Outputs - Production Environment
################################################################################
#
# Export resource attributes for use by other infrastructure components
# or external systems.
#
################################################################################

#------------------------------------------------------------------------------
# Raw Data Bucket Outputs
#------------------------------------------------------------------------------

output "raw_bucket_id" {
  description = "The name of the raw data bucket"
  value       = module.raw_bucket.bucket_id
}

output "raw_bucket_arn" {
  description = "The ARN of the raw data bucket"
  value       = module.raw_bucket.bucket_arn
}

output "raw_bucket_domain_name" {
  description = "The domain name of the raw data bucket"
  value       = module.raw_bucket.bucket_domain_name
}

#------------------------------------------------------------------------------
# Curated Data Bucket Outputs
#------------------------------------------------------------------------------

output "curated_bucket_id" {
  description = "The name of the curated data bucket"
  value       = module.curated_bucket.bucket_id
}

output "curated_bucket_arn" {
  description = "The ARN of the curated data bucket"
  value       = module.curated_bucket.bucket_arn
}

output "curated_bucket_domain_name" {
  description = "The domain name of the curated data bucket"
  value       = module.curated_bucket.bucket_domain_name
}

#------------------------------------------------------------------------------
# MWAA Artifacts Bucket Outputs
#------------------------------------------------------------------------------

output "mwaa_artifacts_bucket_id" {
  description = "The name of the MWAA artifacts bucket"
  value       = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_id : null
}

output "mwaa_artifacts_bucket_arn" {
  description = "The ARN of the MWAA artifacts bucket"
  value       = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_arn : null
}

#------------------------------------------------------------------------------
# Athena Results Bucket Outputs
#------------------------------------------------------------------------------

output "athena_results_bucket_id" {
  description = "The name of the Athena results bucket"
  value       = module.athena_results_bucket.bucket_id
}

output "athena_results_bucket_arn" {
  description = "The ARN of the Athena results bucket"
  value       = module.athena_results_bucket.bucket_arn
}

output "athena_results_location" {
  description = "The S3 location for Athena query results"
  value       = "s3://${module.athena_results_bucket.bucket_id}/"
}

#------------------------------------------------------------------------------
# Summary Outputs
#------------------------------------------------------------------------------

output "all_bucket_arns" {
  description = "Map of all bucket ARNs by purpose"
  value = {
    raw     = module.raw_bucket.bucket_arn
    curated = module.curated_bucket.bucket_arn
    mwaa    = var.enable_mwaa ? module.mwaa_artifacts_bucket[0].bucket_arn : null
    athena  = module.athena_results_bucket.bucket_arn
  }
}

output "environment_info" {
  description = "Environment configuration summary"
  value = {
    environment = var.environment
    region      = var.aws_region
    project     = var.project
  }
}

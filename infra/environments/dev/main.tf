################################################################################
# Main Configuration - Development Environment
################################################################################
#
# This file defines the S3 data lake infrastructure for the MDW project.
# All resources follow the naming convention: <project>-<env>-<region>-<name>
#
################################################################################

#------------------------------------------------------------------------------
# Provider Configuration
#------------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project    = var.project
      env        = var.environment
      region     = var.region
      owner      = var.owner
      managed_by = "terraform"
    }
  }
}

#------------------------------------------------------------------------------
# Local Values
#------------------------------------------------------------------------------

locals {
  # Common lifecycle rule for incomplete multipart uploads
  abort_incomplete_uploads_rule = {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    abort_incomplete_multipart_upload = {
      days_after_initiation = 7
    }
  }
}

################################################################################
# Raw Data Layer
################################################################################
#
# Landing zone for source data ingestion.
# - Longer retention for compliance and reprocessing
# - Tiered storage for cost optimization
#
################################################################################

module "raw_bucket" {
  source = "../../modules/s3"

  bucket_name = "data-raw"
  project     = var.project
  environment = var.environment
  region      = var.region
  owner       = var.owner

  lifecycle_rules = [
    {
      id     = "tiered-storage-transition"
      status = "Enabled"

      transition = [
        {
          days          = var.raw_data_ia_days
          storage_class = "STANDARD_IA"
        },
        {
          days          = var.raw_data_glacier_days
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days           = 90
        newer_noncurrent_versions = 3
      }
    },
    local.abort_incomplete_uploads_rule
  ]

  tags = merge(var.additional_tags, {
    layer               = "raw"
  })
}

################################################################################
# Curated Data Layer
################################################################################
#
# Processed and transformed analytics data.
# - Optimized for query performance
# - Contains business-ready datasets
#
################################################################################

module "curated_bucket" {
  source = "../../modules/s3"

  bucket_name = "data-curated"
  project     = var.project
  environment = var.environment
  region      = var.region
  owner       = var.owner

  lifecycle_rules = [
    {
      id     = "optimize-storage-costs"
      status = "Enabled"

      transition = [
        {
          days          = var.curated_data_ia_days
          storage_class = "STANDARD_IA"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days           = 30
        newer_noncurrent_versions = 5
      }
    },
    local.abort_incomplete_uploads_rule
  ]

  tags = merge(var.additional_tags, {
    layer               = "curated"
  })
}

################################################################################
# MWAA Artifacts
################################################################################
#
# Storage for Apache Airflow DAGs and dbt artifacts.
# - Active access pattern, no lifecycle transitions
# - Versioning for rollback capability
#
################################################################################

module "mwaa_artifacts_bucket" {
  count  = var.enable_mwaa ? 1 : 0
  source = "../../modules/s3"

  bucket_name = "mwaa-artifacts"
  project     = var.project
  environment = var.environment
  region      = var.region
  owner       = var.owner

  lifecycle_rules = [
    {
      id     = "cleanup-old-versions"
      status = "Enabled"

      noncurrent_version_expiration = {
        noncurrent_days           = 14
        newer_noncurrent_versions = 3
      }
    },
    local.abort_incomplete_uploads_rule
  ]

  tags = merge(var.additional_tags, {
    purpose = "mwaa"
    layer   = "orchestration"
  })
}

################################################################################
# Athena Query Results
################################################################################
#
# Temporary storage for Athena query output.
# - Short retention as results are ephemeral
# - No versioning needed
#
################################################################################

module "athena_results_bucket" {
  source = "../../modules/s3"

  bucket_name = "athena-results"
  project     = var.project
  environment = var.environment
  region      = var.region
  owner       = var.owner

  # Disable versioning for temporary data
  versioning_enabled = false

  lifecycle_rules = [
    {
      id     = "expire-query-results"
      status = "Enabled"

      expiration = {
        days = var.athena_results_expiration_days
      }
    },
    local.abort_incomplete_uploads_rule
  ]

  tags = merge(var.additional_tags, {
    purpose = "athena"
    layer   = "query"
  })
}



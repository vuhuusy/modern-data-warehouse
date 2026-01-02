################################################################################
# Example: Data Lake Buckets for Modern Data Warehouse
################################################################################
#
# This example demonstrates creating multiple S3 buckets for a data lake
# architecture with different configurations per layer.
#
# Usage:
#   terraform init
#   terraform plan -var-file="dev.tfvars"
#   terraform apply -var-file="dev.tfvars"
#
################################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Uncomment for remote state
  # backend "s3" {
  #   bucket         = "mdw-terraform-state"
  #   key            = "env/dev/s3/terraform.tfstate"
  #   region         = "us-west-2"
  #   encrypt        = true
  #   dynamodb_table = "mdw-terraform-locks"
  # }
}

provider "aws" {
  region = var.aws_region
}

################################################################################
# Variables
################################################################################

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-west-2"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "mdw"
}

variable "environment" {
  description = "Environment (dev/stg/prod)"
  type        = string
  default     = "dev"
}

variable "owner" {
  description = "Resource owner"
  type        = string
  default     = "data-engineering"
}

variable "cost_center" {
  description = "Cost center code"
  type        = string
  default     = "CC-DATA-001"
}

################################################################################
# Raw Layer Bucket
# - Source data landing zone
# - Longer retention for compliance
################################################################################

module "raw_bucket" {
  source = "../../modules/s3"

  bucket_name = "data-raw"
  project     = var.project
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  lifecycle_rules = [
    {
      id     = "archive-old-data"
      status = "Enabled"

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        },
        {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days           = 90
        newer_noncurrent_versions = 3
      }
    },
    {
      id     = "cleanup-incomplete-uploads"
      status = "Enabled"

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  tags = {
    layer               = "raw"
    data_classification = "internal"
  }
}

################################################################################
# Curated Layer Bucket
# - Processed analytics data
# - Higher performance requirements
################################################################################

module "curated_bucket" {
  source = "../../modules/s3"

  bucket_name = "data-curated"
  project     = var.project
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  lifecycle_rules = [
    {
      id     = "optimize-storage"
      status = "Enabled"

      transition = [
        {
          days          = 180
          storage_class = "STANDARD_IA"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days           = 30
        newer_noncurrent_versions = 5
      }
    }
  ]

  tags = {
    layer               = "curated"
    data_classification = "internal"
  }
}

################################################################################
# MWAA Artifacts Bucket
# - DAG files and dbt artifacts
# - No lifecycle transitions (active access)
################################################################################

module "mwaa_artifacts_bucket" {
  source = "../../modules/s3"

  bucket_name = "mwaa-artifacts"
  project     = var.project
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  lifecycle_rules = [
    {
      id     = "cleanup-old-versions"
      status = "Enabled"

      noncurrent_version_expiration = {
        noncurrent_days           = 14
        newer_noncurrent_versions = 3
      }
    }
  ]

  tags = {
    purpose = "mwaa"
  }
}

################################################################################
# Athena Query Results Bucket
# - Query results storage
# - Short retention (results are temporary)
################################################################################

module "athena_results_bucket" {
  source = "../../modules/s3"

  bucket_name = "athena-results"
  project     = var.project
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  lifecycle_rules = [
    {
      id     = "expire-query-results"
      status = "Enabled"

      expiration = {
        days = 7
      }
    }
  ]

  tags = {
    purpose = "athena"
  }
}

################################################################################
# Access Logs Bucket (for production)
# - Centralized access logging
# - Long retention for audit compliance
################################################################################

module "access_logs_bucket" {
  source = "../../modules/s3"

  bucket_name = "access-logs"
  project     = var.project
  environment = var.environment
  owner       = var.owner
  cost_center = var.cost_center

  # Logs bucket doesn't need versioning
  versioning_enabled = false

  # Use AES256 for logs (KMS adds cost for high-volume logging)
  encryption_configuration = {
    sse_algorithm      = "AES256"
    bucket_key_enabled = false
  }

  lifecycle_rules = [
    {
      id     = "archive-logs"
      status = "Enabled"

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 2555 # 7 years for compliance
      }
    }
  ]

  tags = {
    purpose             = "logging"
    data_classification = "audit"
  }
}

################################################################################
# Outputs
################################################################################

output "raw_bucket" {
  description = "Raw layer bucket details"
  value = {
    name   = module.raw_bucket.bucket_name
    arn    = module.raw_bucket.bucket_arn
    s3_uri = module.raw_bucket.s3_uri
  }
}

output "curated_bucket" {
  description = "Curated layer bucket details"
  value = {
    name   = module.curated_bucket.bucket_name
    arn    = module.curated_bucket.bucket_arn
    s3_uri = module.curated_bucket.s3_uri
  }
}

output "mwaa_artifacts_bucket" {
  description = "MWAA artifacts bucket details"
  value = {
    name   = module.mwaa_artifacts_bucket.bucket_name
    arn    = module.mwaa_artifacts_bucket.bucket_arn
    s3_uri = module.mwaa_artifacts_bucket.s3_uri
  }
}

output "athena_results_bucket" {
  description = "Athena results bucket details"
  value = {
    name   = module.athena_results_bucket.bucket_name
    arn    = module.athena_results_bucket.bucket_arn
    s3_uri = module.athena_results_bucket.s3_uri
  }
}

output "access_logs_bucket" {
  description = "Access logs bucket details"
  value = {
    name   = module.access_logs_bucket.bucket_name
    arn    = module.access_logs_bucket.bucket_arn
    s3_uri = module.access_logs_bucket.s3_uri
  }
}

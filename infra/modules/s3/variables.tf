################################################################################
# Required Variables
################################################################################

variable "bucket_name" {
  description = "The name of the S3 bucket. Will be prefixed with project and environment."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must contain only lowercase letters, numbers, and hyphens. Must start and end with alphanumeric character."
  }
}

variable "project" {
  description = "Project identifier used for naming and tagging resources."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment. Valid values: dev, prod."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be one of: dev, prod."
  }
}

variable "region" {
  description = "AWS region code for naming convention (e.g., us-west-2, us-east-1)."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-west-2, us-east-1)."
  }
}

variable "owner" {
  description = "Owner of the resource (team or individual) for tagging."
  type        = string
  default     = "syvh"
}

################################################################################
# Optional Variables - Naming
################################################################################

variable "use_prefix" {
  description = "Whether to prefix bucket name with project and environment. Set to false for custom naming."
  type        = bool
  default     = true
}

################################################################################
# Optional Variables - Security
################################################################################

variable "block_public_access" {
  description = "Configuration for S3 public access block. All options enabled by default for security."
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {}
}

variable "versioning_enabled" {
  description = "Enable versioning for the S3 bucket. Recommended for production workloads."
  type        = bool
  default     = true
}

variable "versioning_mfa_delete" {
  description = "Enable MFA delete for versioned objects. Requires versioning to be enabled."
  type        = bool
  default     = false
}

################################################################################
# Optional Variables - Encryption
################################################################################

variable "encryption_configuration" {
  description = "Server-side encryption configuration. Uses AES256 by default (free). Use aws:kms for production."
  type = object({
    sse_algorithm             = optional(string, "AES256")
    kms_master_key_id         = optional(string, null)
    bucket_key_enabled        = optional(bool, true)
  })
  default = {}

  validation {
    condition     = contains(["AES256", "aws:kms", "aws:kms:dsse"], var.encryption_configuration.sse_algorithm)
    error_message = "SSE algorithm must be one of: AES256, aws:kms, aws:kms:dsse."
  }
}

################################################################################
# Optional Variables - Bucket Policy
################################################################################

variable "attach_policy" {
  description = "Whether to attach a bucket policy. Set to true to enable custom policy attachment."
  type        = bool
  default     = false
}

variable "policy" {
  description = "JSON-encoded bucket policy. Required if attach_policy is true."
  type        = string
  default     = null
}

variable "attach_deny_insecure_transport_policy" {
  description = "Attach a policy that denies requests not using HTTPS."
  type        = bool
  default     = true
}

variable "attach_require_latest_tls_policy" {
  description = "Attach a policy that requires TLS 1.2 or higher."
  type        = bool
  default     = true
}

################################################################################
# Optional Variables - Object Ownership
################################################################################

variable "object_ownership" {
  description = "Object ownership setting. BucketOwnerEnforced disables ACLs (recommended)."
  type        = string
  default     = "BucketOwnerEnforced"

  validation {
    condition     = contains(["BucketOwnerEnforced", "BucketOwnerPreferred", "ObjectWriter"], var.object_ownership)
    error_message = "Object ownership must be one of: BucketOwnerEnforced, BucketOwnerPreferred, ObjectWriter."
  }
}

################################################################################
# Optional Variables - Lifecycle Rules
################################################################################

variable "lifecycle_rules" {
  description = "List of lifecycle rules for the bucket."
  type = list(object({
    id     = string
    status = optional(string, "Enabled")

    filter = optional(object({
      prefix                   = optional(string)
      object_size_greater_than = optional(number)
      object_size_less_than    = optional(number)
      tags                     = optional(map(string))
    }), {})

    expiration = optional(object({
      days                         = optional(number)
      date                         = optional(string)
      expired_object_delete_marker = optional(bool)
    }))

    transition = optional(list(object({
      days          = optional(number)
      date          = optional(string)
      storage_class = string
    })), [])

    noncurrent_version_expiration = optional(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
    }))

    noncurrent_version_transition = optional(list(object({
      noncurrent_days           = optional(number)
      newer_noncurrent_versions = optional(number)
      storage_class             = string
    })), [])

    abort_incomplete_multipart_upload = optional(object({
      days_after_initiation = number
    }))
  }))
  default = []
}

################################################################################
# Optional Variables - CORS
################################################################################

variable "cors_rules" {
  description = "List of CORS rules for the bucket."
  type = list(object({
    id              = optional(string)
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = list(string)
    allowed_origins = list(string)
    expose_headers  = optional(list(string), [])
    max_age_seconds = optional(number, 3600)
  }))
  default = []
}

################################################################################
# Optional Variables - Additional Tags
################################################################################

variable "managed_by" {
  description = "Managing team or organization for tagging."
  type        = string
  default     = "it-cloud-aws"
}

variable "tags" {
  description = "Additional tags to apply to the bucket. Merged with mandatory tags."
  type        = map(string)
  default     = {}
}

################################################################################
# Optional Variables - Force Destroy
################################################################################

variable "force_destroy" {
  description = "Allow bucket deletion even if it contains objects. Use with caution in production."
  type        = bool
  default     = false
}

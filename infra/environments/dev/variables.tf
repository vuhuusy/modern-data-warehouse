################################################################################
# Input Variables - Development Environment
################################################################################

#------------------------------------------------------------------------------
# Required Variables
#------------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region where resources will be deployed."
  type        = string
}

variable "project" {
  description = "Project identifier used for naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project))
    error_message = "Project must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment identifier."
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}

variable "region" {
  description = "AWS region code for resource naming convention."
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]+$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-west-2)."
  }
}

variable "owner" {
  description = "Team or individual responsible for the resources."
  type        = string
}

#------------------------------------------------------------------------------
# Optional Variables - Feature Flags
#------------------------------------------------------------------------------

variable "enable_mwaa" {
  description = "Create MWAA-related S3 buckets."
  type        = bool
  default     = true
}

#------------------------------------------------------------------------------
# Optional Variables - Lifecycle Configuration
#------------------------------------------------------------------------------

variable "raw_data_glacier_days" {
  description = "Days before transitioning raw data to Glacier storage."
  type        = number
  default     = 365
}

variable "raw_data_ia_days" {
  description = "Days before transitioning raw data to Infrequent Access."
  type        = number
  default     = 90
}

variable "curated_data_ia_days" {
  description = "Days before transitioning curated data to Infrequent Access."
  type        = number
  default     = 180
}

variable "athena_results_expiration_days" {
  description = "Days before Athena query results expire."
  type        = number
  default     = 7
}

#------------------------------------------------------------------------------
# Optional Variables - Tags
#------------------------------------------------------------------------------

variable "additional_tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

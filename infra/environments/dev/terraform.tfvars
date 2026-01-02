################################################################################
# Development Environment - Variable Values
################################################################################
#
# This file contains environment-specific values for the dev environment.
# DO NOT commit sensitive values to version control.
#
# Usage:
#   terraform plan -var-file="terraform.tfvars"
#   terraform apply -var-file="terraform.tfvars"
#
################################################################################

#------------------------------------------------------------------------------
# Core Configuration
#------------------------------------------------------------------------------

aws_region  = "us-west-2"
region      = "us-west-2"
project     = "mdw"
environment = "dev"
owner       = "data-engineering"

#------------------------------------------------------------------------------
# Feature Flags
#------------------------------------------------------------------------------

enable_access_logging = false
enable_mwaa           = true

#------------------------------------------------------------------------------
# Lifecycle Configuration
#------------------------------------------------------------------------------

raw_data_ia_days               = 90
raw_data_glacier_days          = 365
curated_data_ia_days           = 180
athena_results_expiration_days = 7
access_logs_retention_days     = 365 # 1 year for dev

#------------------------------------------------------------------------------
# Additional Tags
#------------------------------------------------------------------------------

additional_tags = {
  cost_allocation = "development"
}

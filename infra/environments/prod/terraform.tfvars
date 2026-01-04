################################################################################
# Production Environment - Variable Values
################################################################################
#
# This file contains environment-specific values for the prod environment.
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
environment = "prod"
owner       = "syvh"

#------------------------------------------------------------------------------
# Feature Flags
#------------------------------------------------------------------------------

enable_mwaa = true

#------------------------------------------------------------------------------
# Lifecycle Configuration
#------------------------------------------------------------------------------

raw_data_ia_days               = 90
raw_data_glacier_days          = 365
curated_data_ia_days           = 180
athena_results_expiration_days = 7

#------------------------------------------------------------------------------
# Additional Tags
#------------------------------------------------------------------------------

additional_tags = {
  cost_allocation = "production"
  compliance      = "required"
}

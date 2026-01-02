################################################################################
# Terraform Backend Configuration - Development Environment
################################################################################
#
# State is stored in S3 with native S3 state locking for team collaboration.
# The backend bucket must be created before running terraform init.
#
# To create backend resources, run:
#   cd infra/bootstrap && terraform init && terraform apply
#
################################################################################

terraform {
  backend "s3" {
    bucket       = "mdw-dev-us-west-2-tfstate"
    key          = "infrastructure/terraform.tfstate"
    region       = "us-west-2"
    encrypt      = true
    use_lockfile = true
  }
}

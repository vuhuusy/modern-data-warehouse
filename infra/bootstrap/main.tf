################################################################################
# Bootstrap - Terraform State Backend Resources
################################################################################
#
# This module creates the S3 bucket and DynamoDB table required for
# Terraform remote state management.
#
# IMPORTANT: Run this module FIRST before initializing other environments.
#
# Usage:
#   cd infra/bootstrap
#   terraform init
#   terraform apply
#
################################################################################

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      project    = var.project
      owner      = var.owner
      managed_by = "terraform"
      purpose    = "terraform-state"
    }
  }
}

################################################################################
# S3 Buckets for Terraform State
################################################################################

resource "aws_s3_bucket" "tfstate" {
  for_each = toset(var.environments)

  bucket = "${var.project}-${each.value}-${var.aws_region}-tfstate"

  tags = {
    env           = each.value
    resource_type = "s3"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Enable versioning for state history and recovery
resource "aws_s3_bucket_versioning" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

################################################################################
# DynamoDB Tables for State Locking
################################################################################

resource "aws_dynamodb_table" "tfstate_lock" {
  for_each = toset(var.environments)

  name         = "${var.project}-${each.value}-${var.aws_region}-tfstate-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    env           = each.value
    resource_type = "dynamodb"
  }

  lifecycle {
    prevent_destroy = true
  }
}

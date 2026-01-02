################################################################################
# Bootstrap Outputs
################################################################################

output "tfstate_bucket_ids" {
  description = "S3 bucket names for Terraform state by environment"
  value = {
    for env, bucket in aws_s3_bucket.tfstate : env => bucket.id
  }
}

output "tfstate_bucket_arns" {
  description = "S3 bucket ARNs for Terraform state by environment"
  value = {
    for env, bucket in aws_s3_bucket.tfstate : env => bucket.arn
  }
}

output "dynamodb_table_names" {
  description = "DynamoDB table names for state locking by environment"
  value = {
    for env, table in aws_dynamodb_table.tfstate_lock : env => table.name
  }
}

output "backend_config" {
  description = "Backend configuration snippets for each environment"
  value = {
    for env in var.environments : env => <<-EOT
      terraform {
        backend "s3" {
          bucket         = "${var.project}-${env}-${var.aws_region}-tfstate"
          key            = "infrastructure/terraform.tfstate"
          region         = "${var.aws_region}"
          encrypt        = true
          dynamodb_table = "${var.project}-${env}-${var.aws_region}-tfstate-lock"
        }
      }
    EOT
  }
}

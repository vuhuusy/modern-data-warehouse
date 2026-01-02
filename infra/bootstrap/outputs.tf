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

output "backend_config" {
  description = "Backend configuration snippets for each environment"
  value = {
    for env in var.environments : env => <<-EOT
      terraform {
        backend "s3" {
          bucket       = "${var.project}-${env}-${var.aws_region}-tfstate"
          key          = "infrastructure/terraform.tfstate"
          region       = "${var.aws_region}"
          encrypt      = true
          use_lockfile = true
        }
      }
    EOT
  }
}

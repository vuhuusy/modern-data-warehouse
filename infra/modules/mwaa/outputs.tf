################################################################################
# MWAA Environment Outputs
################################################################################

output "environment_arn" {
  description = "ARN of the MWAA environment"
  value       = aws_mwaa_environment.this.arn
}

output "environment_name" {
  description = "Name of the MWAA environment"
  value       = aws_mwaa_environment.this.name
}

output "webserver_url" {
  description = "URL of the Airflow web UI"
  value       = aws_mwaa_environment.this.webserver_url
}

output "status" {
  description = "Status of the MWAA environment"
  value       = aws_mwaa_environment.this.status
}

output "airflow_version" {
  description = "Airflow version running in the environment"
  value       = aws_mwaa_environment.this.airflow_version
}

output "environment_class" {
  description = "Environment class (instance size)"
  value       = aws_mwaa_environment.this.environment_class
}

################################################################################
# IAM Outputs
################################################################################

output "execution_role_arn" {
  description = "ARN of the MWAA execution role"
  value       = var.create_execution_role ? aws_iam_role.mwaa[0].arn : var.execution_role_arn
}

output "execution_role_name" {
  description = "Name of the MWAA execution role"
  value       = var.create_execution_role ? aws_iam_role.mwaa[0].name : null
}

################################################################################
# Security Group Outputs
################################################################################

output "security_group_id" {
  description = "ID of the MWAA security group"
  value       = var.create_security_group ? aws_security_group.mwaa[0].id : null
}

output "security_group_arn" {
  description = "ARN of the MWAA security group"
  value       = var.create_security_group ? aws_security_group.mwaa[0].arn : null
}

################################################################################
# Logging Outputs
################################################################################

output "log_group_arns" {
  description = "CloudWatch log group ARNs for each Airflow component"
  value = {
    dag_processing = aws_mwaa_environment.this.logging_configuration[0].dag_processing_logs[0].cloud_watch_log_group_arn
    scheduler      = aws_mwaa_environment.this.logging_configuration[0].scheduler_logs[0].cloud_watch_log_group_arn
    task           = aws_mwaa_environment.this.logging_configuration[0].task_logs[0].cloud_watch_log_group_arn
    webserver      = aws_mwaa_environment.this.logging_configuration[0].webserver_logs[0].cloud_watch_log_group_arn
    worker         = aws_mwaa_environment.this.logging_configuration[0].worker_logs[0].cloud_watch_log_group_arn
  }
}

################################################################################
# Network Outputs
################################################################################

output "vpc_id" {
  description = "VPC ID where MWAA is deployed"
  value       = var.vpc_id
}

output "subnet_ids" {
  description = "Subnet IDs used by MWAA"
  value       = var.private_subnet_ids
}

################################################################################
# S3 Configuration Outputs
################################################################################

output "source_bucket_arn" {
  description = "ARN of the S3 bucket containing DAGs"
  value       = var.source_bucket_arn
}

output "dags_path" {
  description = "S3 path to DAGs folder"
  value       = var.dags_path
}

################################################################################
# Tags Output
################################################################################

output "tags" {
  description = "Tags applied to all resources"
  value       = local.tags
}

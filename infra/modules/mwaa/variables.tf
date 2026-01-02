################################################################################
# Required Variables
################################################################################

variable "environment_name" {
  description = "The name of the MWAA environment. Will be prefixed with project, env, and region."
  type        = string
  default     = "mwaa"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.environment_name))
    error_message = "Environment name must contain only lowercase letters, numbers, and hyphens. Must start with a letter."
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
# S3 Configuration
################################################################################

variable "source_bucket_arn" {
  description = "ARN of the S3 bucket containing DAGs, plugins, and requirements."
  type        = string
}

variable "dags_path" {
  description = "S3 path to the DAGs folder (relative to bucket root)."
  type        = string
  default     = "dags"
}

variable "plugins_path" {
  description = "S3 path to the plugins.zip file (relative to bucket root). Set to null to disable."
  type        = string
  default     = null
}

variable "requirements_path" {
  description = "S3 path to the requirements.txt file (relative to bucket root). Set to null to disable."
  type        = string
  default     = null
}

variable "startup_script_path" {
  description = "S3 path to the startup script (relative to bucket root). Set to null to disable."
  type        = string
  default     = null
}

################################################################################
# Network Configuration
################################################################################

variable "vpc_id" {
  description = "VPC ID where MWAA will be deployed."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for MWAA (minimum 2 in different AZs)."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "MWAA requires at least 2 private subnets in different availability zones."
  }
}

variable "security_group_ids" {
  description = "List of additional security group IDs to attach to MWAA. If empty, a default SG will be created."
  type        = list(string)
  default     = []
}

variable "create_security_group" {
  description = "Whether to create a default security group for MWAA."
  type        = bool
  default     = true
}

################################################################################
# MWAA Environment Configuration
################################################################################

variable "airflow_version" {
  description = "Apache Airflow version. Supported: 2.8.1, 2.9.2, 2.10.1, 2.10.3, 2.10.4."
  type        = string
  default     = "2.10.4"

  validation {
    condition     = contains(["2.8.1", "2.9.2", "2.10.1", "2.10.3", "2.10.4"], var.airflow_version)
    error_message = "Airflow version must be one of: 2.8.1, 2.9.2, 2.10.1, 2.10.3, 2.10.4."
  }
}

variable "environment_class" {
  description = "Environment class. mw1.small (1 vCPU, 2GB), mw1.medium (2 vCPU, 4GB), mw1.large (4 vCPU, 8GB), mw1.xlarge (8 vCPU, 24GB), mw1.2xlarge (16 vCPU, 48GB)."
  type        = string
  default     = "mw1.small"

  validation {
    condition     = contains(["mw1.small", "mw1.medium", "mw1.large", "mw1.xlarge", "mw1.2xlarge"], var.environment_class)
    error_message = "Environment class must be one of: mw1.small, mw1.medium, mw1.large, mw1.xlarge, mw1.2xlarge."
  }
}

variable "max_workers" {
  description = "Maximum number of workers for auto-scaling."
  type        = number
  default     = 10

  validation {
    condition     = var.max_workers >= 1 && var.max_workers <= 25
    error_message = "Max workers must be between 1 and 25."
  }
}

variable "min_workers" {
  description = "Minimum number of workers for auto-scaling."
  type        = number
  default     = 1

  validation {
    condition     = var.min_workers >= 1 && var.min_workers <= 25
    error_message = "Min workers must be between 1 and 25."
  }
}

variable "max_webservers" {
  description = "Maximum number of web servers."
  type        = number
  default     = 2

  validation {
    condition     = var.max_webservers >= 2 && var.max_webservers <= 5
    error_message = "Max webservers must be between 2 and 5."
  }
}

variable "min_webservers" {
  description = "Minimum number of web servers."
  type        = number
  default     = 2

  validation {
    condition     = var.min_webservers >= 2 && var.min_webservers <= 5
    error_message = "Min webservers must be between 2 and 5."
  }
}

variable "schedulers" {
  description = "Number of schedulers (2-5)."
  type        = number
  default     = 2

  validation {
    condition     = var.schedulers >= 2 && var.schedulers <= 5
    error_message = "Schedulers must be between 2 and 5."
  }
}

################################################################################
# Web Server Access Configuration
################################################################################

variable "webserver_access_mode" {
  description = "Web server access mode. PRIVATE_ONLY or PUBLIC_ONLY."
  type        = string
  default     = "PRIVATE_ONLY"

  validation {
    condition     = contains(["PRIVATE_ONLY", "PUBLIC_ONLY"], var.webserver_access_mode)
    error_message = "Webserver access mode must be PRIVATE_ONLY or PUBLIC_ONLY."
  }
}

################################################################################
# Logging Configuration
################################################################################

variable "logging_configuration" {
  description = "Logging configuration for MWAA components."
  type = object({
    dag_processing_logs = optional(object({
      enabled   = optional(bool, true)
      log_level = optional(string, "INFO")
    }), {})
    scheduler_logs = optional(object({
      enabled   = optional(bool, true)
      log_level = optional(string, "INFO")
    }), {})
    task_logs = optional(object({
      enabled   = optional(bool, true)
      log_level = optional(string, "INFO")
    }), {})
    webserver_logs = optional(object({
      enabled   = optional(bool, true)
      log_level = optional(string, "INFO")
    }), {})
    worker_logs = optional(object({
      enabled   = optional(bool, true)
      log_level = optional(string, "INFO")
    }), {})
  })
  default = {}
}

################################################################################
# Airflow Configuration Options
################################################################################

variable "airflow_configuration_options" {
  description = "Airflow configuration options as key-value pairs."
  type        = map(string)
  default     = {}
}

################################################################################
# Maintenance Window
################################################################################

variable "weekly_maintenance_window_start" {
  description = "Weekly maintenance window start time in UTC (e.g., 'SUN:03:00')."
  type        = string
  default     = "SUN:03:00"
}

################################################################################
# IAM Configuration
################################################################################

variable "create_execution_role" {
  description = "Whether to create the MWAA execution role."
  type        = bool
  default     = true
}

variable "execution_role_arn" {
  description = "ARN of an existing IAM role for MWAA execution. Required if create_execution_role is false."
  type        = string
  default     = null
}

variable "additional_execution_role_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the execution role."
  type        = list(string)
  default     = []
}

variable "s3_bucket_arns" {
  description = "List of S3 bucket ARNs that MWAA should have access to (for data processing)."
  type        = list(string)
  default     = []
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encryption. If null, AWS managed key is used."
  type        = string
  default     = null
}

################################################################################
# Tagging
################################################################################

variable "managed_by" {
  description = "Team or system managing this resource."
  type        = string
  default     = "terraform"
}

variable "tags" {
  description = "Additional tags to apply to all resources."
  type        = map(string)
  default     = {}
}

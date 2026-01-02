################################################################################
# Amazon MWAA (Managed Workflows for Apache Airflow) Module
################################################################################
#
# This module creates an enterprise-grade MWAA environment with:
# - IAM execution role with least-privilege permissions
# - Security group with required MWAA networking rules
# - CloudWatch logging for all Airflow components
# - Auto-scaling configuration for workers and webservers
#
# Naming Convention: <project>-<env>-<region>-<name>
#
################################################################################

locals {
  # Resource naming
  name_prefix      = "${var.project}-${var.environment}-${var.region}"
  environment_name = "${local.name_prefix}-${var.environment_name}"

  # Extract bucket name from ARN for S3 paths
  source_bucket_name = element(split(":::", var.source_bucket_arn), 1)

  # Mandatory tags
  mandatory_tags = {
    project       = var.project
    env           = var.environment
    region        = var.region
    owner         = var.owner
    managed_by    = var.managed_by
    resource_type = "mwaa"
    created_by    = "terraform"
    created_date  = formatdate("YYYYMMDD", timestamp())
  }

  tags = merge(var.tags, local.mandatory_tags)

  # Determine execution role ARN
  execution_role_arn = var.create_execution_role ? aws_iam_role.mwaa[0].arn : var.execution_role_arn

  # Default Airflow configuration options
  default_airflow_config = {
    "core.default_timezone"                = "Asia/Ho_Chi_Minh"
    "webserver.default_ui_timezone"        = "Asia/Ho_Chi_Minh"
    "core.load_examples"                   = "False"
    "scheduler.catchup_by_default"         = "False"
    "celery.worker_autoscale"              = "${var.max_workers},${var.min_workers}"
    "core.parallelism"                     = "32"
    "core.max_active_tasks_per_dag"        = "16"
    "scheduler.max_dagruns_to_create_per_loop" = "10"
  }

  airflow_configuration_options = merge(local.default_airflow_config, var.airflow_configuration_options)

  # Logging configuration with defaults
  logging_config = {
    dag_processing_logs = {
      enabled   = try(var.logging_configuration.dag_processing_logs.enabled, true)
      log_level = try(var.logging_configuration.dag_processing_logs.log_level, "INFO")
    }
    scheduler_logs = {
      enabled   = try(var.logging_configuration.scheduler_logs.enabled, true)
      log_level = try(var.logging_configuration.scheduler_logs.log_level, "INFO")
    }
    task_logs = {
      enabled   = try(var.logging_configuration.task_logs.enabled, true)
      log_level = try(var.logging_configuration.task_logs.log_level, "INFO")
    }
    webserver_logs = {
      enabled   = try(var.logging_configuration.webserver_logs.enabled, true)
      log_level = try(var.logging_configuration.webserver_logs.log_level, "INFO")
    }
    worker_logs = {
      enabled   = try(var.logging_configuration.worker_logs.enabled, true)
      log_level = try(var.logging_configuration.worker_logs.log_level, "INFO")
    }
  }
}

################################################################################
# Data Sources
################################################################################

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

################################################################################
# IAM Role for MWAA Execution
################################################################################

data "aws_iam_policy_document" "mwaa_assume_role" {
  count = var.create_execution_role ? 1 : 0

  statement {
    sid     = "MWAAAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "airflow.amazonaws.com",
        "airflow-env.amazonaws.com"
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:airflow:${var.region}:${data.aws_caller_identity.current.account_id}:environment/${local.environment_name}"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_role" "mwaa" {
  count = var.create_execution_role ? 1 : 0

  name = "${local.name_prefix}-mwaa-execution-role"
  path = "/service-role/"

  assume_role_policy = data.aws_iam_policy_document.mwaa_assume_role[0].json

  tags = merge(local.tags, {
    resource_type = "iam-role"
  })

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "mwaa_execution" {
  count = var.create_execution_role ? 1 : 0

  # Airflow connections and variables
  statement {
    sid    = "AirflowPublishMetrics"
    effect = "Allow"
    actions = [
      "airflow:PublishMetrics"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:airflow:${var.region}:${data.aws_caller_identity.current.account_id}:environment/${local.environment_name}"
    ]
  }

  # S3 access for DAGs, plugins, requirements
  statement {
    sid    = "S3GetObjectsForMWAA"
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*"
    ]
    resources = [
      var.source_bucket_arn,
      "${var.source_bucket_arn}/*"
    ]
  }

  # Additional S3 bucket access for data processing
  dynamic "statement" {
    for_each = length(var.s3_bucket_arns) > 0 ? [1] : []

    content {
      sid    = "S3AccessForDataProcessing"
      effect = "Allow"
      actions = [
        "s3:GetObject*",
        "s3:PutObject*",
        "s3:DeleteObject*",
        "s3:GetBucket*",
        "s3:List*"
      ]
      resources = flatten([
        for arn in var.s3_bucket_arns : [
          arn,
          "${arn}/*"
        ]
      ])
    }
  }

  # CloudWatch Logs
  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:DescribeLogGroups"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${local.environment_name}-*"
    ]
  }

  # CloudWatch metrics
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData"
    ]
    resources = ["*"]
  }

  # SQS for Celery (required by MWAA)
  statement {
    sid    = "SQSAccess"
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage"
    ]
    resources = [
      "arn:${data.aws_partition.current.partition}:sqs:${var.region}:*:airflow-celery-*"
    ]
  }

  # KMS for encryption
  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      sid    = "KMSDecrypt"
      effect = "Allow"
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey",
        "kms:GenerateDataKey*",
        "kms:Encrypt"
      ]
      resources = [var.kms_key_arn]
      condition {
        test     = "StringLike"
        variable = "kms:ViaService"
        values   = ["sqs.${var.region}.amazonaws.com"]
      }
    }
  }
}

resource "aws_iam_role_policy" "mwaa_execution" {
  count = var.create_execution_role ? 1 : 0

  name   = "${local.name_prefix}-mwaa-execution-policy"
  role   = aws_iam_role.mwaa[0].id
  policy = data.aws_iam_policy_document.mwaa_execution[0].json
}

# Attach additional policies
resource "aws_iam_role_policy_attachment" "additional" {
  count = var.create_execution_role ? length(var.additional_execution_role_policy_arns) : 0

  role       = aws_iam_role.mwaa[0].name
  policy_arn = var.additional_execution_role_policy_arns[count.index]
}

################################################################################
# Security Group for MWAA
################################################################################

resource "aws_security_group" "mwaa" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.name_prefix}-mwaa-sg"
  description = "Security group for MWAA environment ${local.environment_name}"
  vpc_id      = var.vpc_id

  tags = merge(local.tags, {
    Name          = "${local.name_prefix}-mwaa-sg"
    resource_type = "security-group"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# MWAA requires self-referencing ingress rule
resource "aws_vpc_security_group_ingress_rule" "mwaa_self" {
  count = var.create_security_group ? 1 : 0

  security_group_id            = aws_security_group.mwaa[0].id
  description                  = "Allow all traffic within MWAA security group"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.mwaa[0].id

  tags = {
    Name = "${local.name_prefix}-mwaa-self-ingress"
  }
}

# HTTPS ingress for web UI (if PUBLIC_ONLY)
resource "aws_vpc_security_group_ingress_rule" "mwaa_https" {
  count = var.create_security_group && var.webserver_access_mode == "PUBLIC_ONLY" ? 1 : 0

  security_group_id = aws_security_group.mwaa[0].id
  description       = "Allow HTTPS for Airflow web UI"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-mwaa-https-ingress"
  }
}

# Egress to anywhere (required for MWAA to function)
resource "aws_vpc_security_group_egress_rule" "mwaa_all" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.mwaa[0].id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-mwaa-egress"
  }
}

################################################################################
# MWAA Environment
################################################################################

resource "aws_mwaa_environment" "this" {
  name = local.environment_name

  # Airflow version and environment class
  airflow_version   = var.airflow_version
  environment_class = var.environment_class

  # IAM execution role
  execution_role_arn = local.execution_role_arn

  # S3 source configuration
  source_bucket_arn     = var.source_bucket_arn
  dag_s3_path           = var.dags_path
  plugins_s3_path       = var.plugins_path
  requirements_s3_path  = var.requirements_path
  startup_script_s3_path = var.startup_script_path

  # Network configuration
  network_configuration {
    security_group_ids = var.create_security_group ? concat([aws_security_group.mwaa[0].id], var.security_group_ids) : var.security_group_ids
    subnet_ids         = var.private_subnet_ids
  }

  # Web server access
  webserver_access_mode = var.webserver_access_mode

  # Scaling configuration
  max_workers    = var.max_workers
  min_workers    = var.min_workers
  max_webservers = var.max_webservers
  min_webservers = var.min_webservers
  schedulers     = var.schedulers

  # Airflow configuration options
  airflow_configuration_options = local.airflow_configuration_options

  # Logging configuration
  logging_configuration {
    dag_processing_logs {
      enabled   = local.logging_config.dag_processing_logs.enabled
      log_level = local.logging_config.dag_processing_logs.log_level
    }

    scheduler_logs {
      enabled   = local.logging_config.scheduler_logs.enabled
      log_level = local.logging_config.scheduler_logs.log_level
    }

    task_logs {
      enabled   = local.logging_config.task_logs.enabled
      log_level = local.logging_config.task_logs.log_level
    }

    webserver_logs {
      enabled   = local.logging_config.webserver_logs.enabled
      log_level = local.logging_config.webserver_logs.log_level
    }

    worker_logs {
      enabled   = local.logging_config.worker_logs.enabled
      log_level = local.logging_config.worker_logs.log_level
    }
  }

  # Encryption (optional KMS)
  dynamic "encryption_configuration" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      kms_key = var.kms_key_arn
    }
  }

  # Maintenance window
  weekly_maintenance_window_start = var.weekly_maintenance_window_start

  tags = local.tags

  lifecycle {
    ignore_changes = [
      plugins_s3_object_version,
      requirements_s3_object_version,
      startup_script_s3_object_version
    ]
  }

  depends_on = [
    aws_iam_role_policy.mwaa_execution
  ]
}

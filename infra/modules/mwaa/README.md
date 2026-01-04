# AWS MWAA (Managed Workflows for Apache Airflow) Module

Enterprise-grade Terraform module for provisioning Amazon MWAA environments with security best practices.

## Features

- ✅ **Security by Default**: Least-privilege IAM role, private networking option
- ✅ **Enterprise Naming**: Consistent `<project>-<env>-<region>-<name>` naming convention
- ✅ **Mandatory Tagging**: Enforces project, environment, region, owner tags
- ✅ **Auto-scaling**: Configurable worker and webserver scaling
- ✅ **CloudWatch Logging**: All Airflow components logged
- ✅ **Flexible Configuration**: Custom Airflow config options support

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              AWS Cloud                                   │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │                           VPC                                      │  │
│  │  ┌─────────────────────┐  ┌─────────────────────┐                 │  │
│  │  │  Private Subnet 1   │  │  Private Subnet 2   │                 │  │
│  │  │  ┌───────────────┐  │  │  ┌───────────────┐  │                 │  │
│  │  │  │    MWAA       │  │  │  │    MWAA       │  │                 │  │
│  │  │  │  Webserver    │◄─┼──┼─►│   Workers     │  │                 │  │
│  │  │  │  Scheduler    │  │  │  │               │  │                 │  │
│  │  │  └───────────────┘  │  │  └───────────────┘  │                 │  │
│  │  └─────────────────────┘  └─────────────────────┘                 │  │
│  └───────────────────────────────────────────────────────────────────┘  │
│                                    │                                     │
│                                    ▼                                     │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐               │
│  │  S3 Bucket    │  │  CloudWatch   │  │   IAM Role    │               │
│  │  (DAGs/Plugins)│  │    Logs      │  │ (Execution)   │               │
│  └───────────────┘  └───────────────┘  └───────────────┘               │
└─────────────────────────────────────────────────────────────────────────┘
```

## Usage

### Basic Usage (Development)

```hcl
module "mwaa" {
  source = "../../modules/mwaa"

  project     = "mdw"
  environment = "dev"
  region      = "us-west-2"
  owner       = "data-engineering"

  # S3 bucket for DAGs
  source_bucket_arn = module.mwaa_artifacts_bucket.bucket_arn
  dags_path         = "dags"

  # Network configuration
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Development sizing
  environment_class = "mw1.small"
  max_workers       = 2
  min_workers       = 1
}
```

### Full Configuration

```hcl
module "mwaa" {
  source = "../../modules/mwaa"

  project     = "mdw"
  environment = "dev"
  region      = "us-west-2"
  owner       = "data-engineering"

  # S3 bucket for DAGs
  source_bucket_arn   = module.mwaa_artifacts_bucket.bucket_arn
  dags_path           = "dags"
  plugins_path        = "plugins/plugins.zip"
  requirements_path   = "requirements/requirements.txt"
  startup_script_path = "startup/startup.sh"

  # Network configuration
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  webserver_access_mode = "PRIVATE_ONLY"

  # Production sizing
  environment_class = "mw1.medium"
  max_workers       = 10
  min_workers       = 2
  max_webservers    = 4
  min_webservers    = 2
  schedulers        = 2

  # Data bucket access for dbt/ETL
  s3_bucket_arns = [
    module.raw_bucket.bucket_arn,
    module.curated_bucket.bucket_arn
  ]

  # KMS encryption
  kms_key_arn = aws_kms_key.mwaa.arn

  # Custom Airflow configuration
  airflow_configuration_options = {
    "core.default_timezone"         = "Asia/Ho_Chi_Minh"
    "webserver.default_ui_timezone" = "Asia/Ho_Chi_Minh"
    "core.parallelism"              = "64"
    "core.max_active_tasks_per_dag" = "32"
  }

  # Enhanced logging for production
  logging_configuration = {
    dag_processing_logs = { enabled = true, log_level = "INFO" }
    scheduler_logs      = { enabled = true, log_level = "INFO" }
    task_logs           = { enabled = true, log_level = "INFO" }
    webserver_logs      = { enabled = true, log_level = "WARNING" }
    worker_logs         = { enabled = true, log_level = "INFO" }
  }

  tags = {
    data_classification = "internal"
    compliance          = "required"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | ~> 1.14.0 |
| aws | ~> 6.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| project | Project identifier | `string` | n/a | yes |
| environment | Deployment environment | `string` | n/a | yes |
| region | AWS region code | `string` | n/a | yes |
| source_bucket_arn | ARN of S3 bucket containing DAGs | `string` | n/a | yes |
| vpc_id | VPC ID for MWAA deployment | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs (min 2) | `list(string)` | n/a | yes |
| environment_name | MWAA environment name suffix | `string` | `"mwaa"` | no |
| owner | Owner for tagging | `string` | `"syvh"` | no |
| dags_path | S3 path to DAGs folder | `string` | `"dags"` | no |
| plugins_path | S3 path to plugins.zip | `string` | `null` | no |
| requirements_path | S3 path to requirements.txt | `string` | `null` | no |
| startup_script_path | S3 path to startup script | `string` | `null` | no |
| airflow_version | Apache Airflow version | `string` | `"2.10.4"` | no |
| environment_class | MWAA environment class | `string` | `"mw1.small"` | no |
| max_workers | Maximum workers | `number` | `10` | no |
| min_workers | Minimum workers | `number` | `1` | no |
| max_webservers | Maximum webservers | `number` | `2` | no |
| min_webservers | Minimum webservers | `number` | `2` | no |
| schedulers | Number of schedulers | `number` | `2` | no |
| webserver_access_mode | Web UI access mode | `string` | `"PRIVATE_ONLY"` | no |
| create_security_group | Create default security group | `bool` | `true` | no |
| create_execution_role | Create IAM execution role | `bool` | `true` | no |
| s3_bucket_arns | Additional S3 buckets for data access | `list(string)` | `[]` | no |
| kms_key_arn | KMS key ARN for encryption | `string` | `null` | no |
| airflow_configuration_options | Custom Airflow config | `map(string)` | `{}` | no |
| logging_configuration | Logging configuration | `object` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| environment_arn | ARN of the MWAA environment |
| environment_name | Name of the MWAA environment |
| webserver_url | URL of the Airflow web UI |
| status | Status of the MWAA environment |
| execution_role_arn | ARN of the MWAA execution role |
| security_group_id | ID of the MWAA security group |
| log_group_arns | CloudWatch log group ARNs |

## Environment Classes

| Class | vCPU | Memory | Concurrent Tasks | Use Case |
|-------|------|--------|-----------------|----------|
| mw1.small | 1 | 2 GB | ~5 | Development, small workloads |
| mw1.medium | 2 | 4 GB | ~10 | Moderate workloads |
| mw1.large | 4 | 8 GB | ~20 | Production workloads |
| mw1.xlarge | 8 | 24 GB | ~40 | Large-scale production |
| mw1.2xlarge | 16 | 48 GB | ~80 | Enterprise workloads |

## Networking Requirements

MWAA requires:
- **VPC** with DNS resolution and DNS hostnames enabled
- **At least 2 private subnets** in different Availability Zones
- **NAT Gateway** for outbound internet access (to pull PyPI packages, Docker images)
- **Security Group** with self-referencing ingress rule

## IAM Permissions

The module creates an execution role with least-privilege permissions for:
- S3 access (DAGs, plugins, requirements, data buckets)
- CloudWatch Logs (all Airflow components)
- SQS (Celery task queue)
- CloudWatch Metrics (Airflow metrics)
- KMS (if encryption enabled)

## Cost Estimation

| Component | Dev (mw1.small) | Prod (mw1.medium) |
|-----------|-----------------|-------------------|
| Environment | ~$0.49/hour | ~$0.97/hour |
| Workers (per worker) | ~$0.49/hour | ~$0.97/hour |
| Additional Workers | Variable | Variable |
| **Monthly (24/7)** | **~$350** | **~$700+** |

## References

- [Amazon MWAA Documentation](https://docs.aws.amazon.com/mwaa/latest/userguide/what-is-mwaa.html)
- [MWAA Best Practices](https://docs.aws.amazon.com/mwaa/latest/userguide/best-practices.html)
- [Apache Airflow Documentation](https://airflow.apache.org/docs/)

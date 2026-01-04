# Infrastructure as Code (IaC)

This directory contains Terraform configurations for provisioning the Modern Data Warehouse (MDW) infrastructure on AWS.

## Directory Structure

```
infra/
├── bootstrap/             # Terraform state backend resources
│   ├── main.tf           # S3 for state management
│   ├── variables.tf      # Bootstrap configuration
│   ├── outputs.tf        # Backend config snippets
│   └── versions.tf       # Provider constraints
├── environments/          # Environment configurations
│   └── dev/              # Development environment
│       ├── backend.tf    # Remote state configuration
│       ├── main.tf       # Resource definitions
│       ├── outputs.tf    # Output values
│       ├── terraform.tfvars # Variable values
│       ├── variables.tf  # Variable declarations
│       └── versions.tf   # Provider constraints
├── modules/              # Reusable Terraform modules
│   └── s3/              # S3 bucket module with security defaults
└── README.md            # This file
```

## Prerequisites

- **Terraform** ~> 1.14.0
- **AWS CLI** configured with appropriate credentials
- **AWS Account** with permissions to create S3, IAM, and DynamoDB resources

## Naming Convention

All AWS resources follow this naming pattern:

```
<project>-<env>-<region>-<name>
```

| Component | Description | Example |
|-----------|-------------|---------|
| `project` | Project identifier | `mdw` |
| `env` | Environment | `dev` |
| `region` | AWS region | `us-west-2` |
| `name` | Descriptive resource name | `data-raw` |

**Example:** `mdw-dev-us-west-2-data-raw`

## Quick Start

### 1. Bootstrap Backend (First Time Only)

Run the bootstrap module to create S3 bucket for Terraform state:

```bash
cd infra/bootstrap
terraform init
terraform apply
```

This creates:
- `mdw-dev-us-west-2-tfstate` - S3 bucket for state

### 2. Deploy Infrastructure

```bash
cd environments/dev

# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply changes
terraform apply
```

## Environment Configuration

| Feature | Configuration |
|---------|---------------|
| Encryption | AES-256 (default) |
| MWAA | Enabled |
| Raw Data IA Transition | 90 days |
| Raw Data Glacier | 365 days |
| Athena Results Retention | 7 days |

## Modules

### S3 Module

Enterprise-grade S3 bucket module with security defaults:

- ✅ Server-side encryption (AES-256 or KMS)
- ✅ Public access blocked
- ✅ TLS 1.2+ enforced
- ✅ Versioning enabled by default
- ✅ Configurable lifecycle rules

**Usage:**

```hcl
module "data_bucket" {
  source = "../../modules/s3"

  bucket_name = "data-raw"
  project     = "mdw"
  environment = "dev"
  region      = "us-west-2"
  owner       = "data-team"

  tags = {
    layer = "raw"
  }
}
```

See [modules/s3/README.md](modules/s3/README.md) for full documentation.

## Security

### IAM Best Practices

- All S3 buckets deny public access by default
- TLS is enforced for all bucket operations
- IAM policies follow least privilege principle

### Encryption

- Default: AES-256 server-side encryption

### State Security

- Remote state stored in encrypted S3 bucket
- State locking via S3 native locking
- Never commit `.terraform/` or `*.tfstate` files

## Outputs

After deployment, Terraform outputs include:

| Output | Description |
|--------|-------------|
| `raw_bucket_arn` | ARN of the raw data bucket |
| `curated_bucket_arn` | ARN of the curated data bucket |
| `athena_results_location` | S3 URI for Athena query results |
| `all_bucket_arns` | Map of all bucket ARNs by purpose |

## Common Operations

### Validate Configuration

```bash
terraform fmt -check -recursive
terraform validate
```

### Import Existing Resources

```bash
terraform import module.raw_bucket.aws_s3_bucket.this mdw-dev-us-west-2-data-raw
```

### Destroy Environment

```bash
# CAUTION: This will delete all resources
terraform destroy
```

## Troubleshooting

### State Lock Issues

If a previous run was interrupted:

```bash
terraform force-unlock <LOCK_ID>
```

### Provider Version Conflicts

```bash
rm -rf .terraform .terraform.lock.hcl
terraform init -upgrade
```

## References

- [AWS S3 Best Practices](https://docs.aws.amazon.com/AmazonS3/latest/userguide/security-best-practices.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Project Copilot Instructions](../.github/copilot-instructions.md#write-terraform-infrastructure)

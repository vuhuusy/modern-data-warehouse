# AWS S3 Bucket Module

Enterprise-grade Terraform module for creating secure AWS S3 buckets with best practices enforced by default.

## Features

- ✅ **Security by Default**: All public access blocked, versioning enabled
- ✅ **Enterprise Naming**: Consistent `<project>-<env>-<region>-<name>` naming convention
- ✅ **Mandatory Tagging**: Enforces project, environment, region, owner tags
- ✅ **TLS Enforcement**: Denies non-HTTPS requests and requires TLS 1.2+
- ✅ **Flexible Configuration**: Optional lifecycle rules, CORS
- ✅ **Multi-Environment**: Supports dev and prod environments
- ✅ **Encryption Options**: AES-256 (default) or AWS KMS

## Usage

### Basic Usage

```hcl
module "data_lake" {
  source = "../../modules/s3"

  bucket_name = "data-lake"
  project     = "mdw"
  environment = "dev"
  region      = "us-west-2"
  owner       = "data-engineering"
}
```

### Production Data Lake with KMS Encryption

```hcl
module "data_lake_prod" {
  source = "../../modules/s3"

  bucket_name = "data-lake"
  project     = "mdw"
  environment = "prod"
  region      = "us-west-2"
  owner       = "data-engineering"

  # KMS encryption for production
  encryption_configuration = {
    sse_algorithm      = "aws:kms"
    bucket_key_enabled = true
  }

  # Lifecycle rules for cost optimization
  lifecycle_rules = [
    {
      id     = "transition-to-ia"
      status = "Enabled"
      
      filter = {
        prefix = "raw/"
      }

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        noncurrent_days = 90
      }
    },
    {
      id     = "abort-incomplete-uploads"
      status = "Enabled"

      abort_incomplete_multipart_upload = {
        days_after_initiation = 7
      }
    }
  ]

  tags = {
    data_classification = "confidential"
  }
}
```

### Bucket with Custom Policy

```hcl
data "aws_iam_policy_document" "cross_account_access" {
  statement {
    sid    = "CrossAccountRead"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::123456789012:root"]
    }

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "arn:aws:s3:::mdw-prod-us-west-2-shared-data",
      "arn:aws:s3:::mdw-prod-us-west-2-shared-data/*"
    ]
  }
}

module "shared_data" {
  source = "../../modules/s3"

  bucket_name = "shared-data"
  project     = "mdw"
  environment = "prod"
  region      = "us-west-2"
  owner       = "data-engineering"

  attach_policy = true
  policy        = data.aws_iam_policy_document.cross_account_access.json
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
| bucket_name | The name of the S3 bucket | `string` | n/a | yes |
| project | Project identifier | `string` | n/a | yes |
| environment | Deployment environment (dev/prod) | `string` | n/a | yes |
| region | AWS region code (e.g., us-west-2) | `string` | n/a | yes |
| owner | Owner for tagging | `string` | n/a | yes |
| use_prefix | Prefix bucket name with project, env, region | `bool` | `true` | no |
| block_public_access | Public access block configuration | `object` | All blocked | no |
| versioning_enabled | Enable bucket versioning | `bool` | `true` | no |
| versioning_mfa_delete | Enable MFA delete | `bool` | `false` | no |
| encryption_configuration | SSE configuration | `object` | SSE-KMS | no |
| attach_policy | Attach custom bucket policy | `bool` | `false` | no |
| policy | Custom bucket policy JSON | `string` | `null` | no |
| attach_deny_insecure_transport_policy | Deny non-HTTPS requests | `bool` | `true` | no |
| attach_require_latest_tls_policy | Require TLS 1.2+ | `bool` | `true` | no |
| object_ownership | Object ownership setting | `string` | `"BucketOwnerEnforced"` | no |
| logging_enabled | Enable access logging | `bool` | `false` | no |
| logging_target_bucket | Target bucket for logs | `string` | `null` | no |
| logging_target_prefix | Prefix for log objects | `string` | `null` | no |
| lifecycle_rules | Lifecycle rule configurations | `list(object)` | `[]` | no |
| cors_rules | CORS rule configurations | `list(object)` | `[]` | no |
| managed_by | Managing team for tagging | `string` | `"it-cloud-aws"` | no |
| tags | Additional tags | `map(string)` | `{}` | no |
| force_destroy | Allow deletion with objects | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_id | The name of the bucket |
| bucket_name | The name of the bucket (alias) |
| bucket_arn | The ARN of the bucket |
| bucket_regional_domain_name | Regional domain name |
| bucket_domain_name | Bucket domain name |
| bucket_region | AWS region |
| bucket_policy | Bucket policy JSON (if attached) |
| versioning_status | Versioning status |
| encryption_algorithm | SSE algorithm used |
| encryption_kms_key_id | KMS key ID (if applicable) |
| s3_uri | S3 URI (s3://bucket-name) |
| tags | Applied tags |

## Security Features

### Default Security Posture

This module enforces security by default:

1. **Public Access Blocked**: All four public access block settings enabled
2. **Versioning Enabled**: Protects against accidental deletion
3. **SSE-KMS Encryption**: Server-side encryption with KMS
4. **TLS Required**: Denies HTTP requests, requires TLS 1.2+
5. **ACLs Disabled**: BucketOwnerEnforced ownership

### Customizing Security

To relax security settings (not recommended for production):

```hcl
module "relaxed_bucket" {
  source = "../../modules/s3"

  # Required variables...

  # Disable specific security features
  attach_deny_insecure_transport_policy = false
  attach_require_latest_tls_policy      = false
  versioning_enabled                    = false

  # Use AES256 instead of KMS
  encryption_configuration = {
    sse_algorithm = "AES256"
  }
}
```

## Lifecycle Rules

### Supported Lifecycle Actions

- **Transition**: Move objects to different storage classes
- **Expiration**: Delete objects after specified days
- **Noncurrent Version Expiration**: Clean up old versions
- **Noncurrent Version Transition**: Move old versions to cheaper storage
- **Abort Incomplete Multipart Upload**: Clean up failed uploads

### Storage Classes for Transitions

- `STANDARD_IA` - Infrequent Access
- `ONEZONE_IA` - One Zone Infrequent Access
- `INTELLIGENT_TIERING` - Automatic tiering
- `GLACIER` - Archive storage
- `GLACIER_IR` - Glacier Instant Retrieval
- `DEEP_ARCHIVE` - Lowest cost archive

## Tags Applied

All buckets receive these mandatory tags:

| Tag | Description |
|-----|-------------|
| project | Project identifier |
| env | Environment (dev/stg/prod) |
| owner | Resource owner |
| cost_center | Billing cost center |
| managed_by | Managing team |
| resource_type | Always "s3" |
| created_by | Always "terraform" |
| created_date | Creation date (YYYYMMDD) |

## License

This module is part of the Modern Data Warehouse project.

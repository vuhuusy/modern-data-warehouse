# Bootstrap - Terraform State Backend

This module provisions the S3 bucket and DynamoDB table required for Terraform remote state management.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform ~> 1.14.0

## Resources Created

| Resource | Purpose | Naming Pattern |
|----------|---------|----------------|
| S3 Bucket | Store Terraform state files | `mdw-<env>-us-west-2-tfstate` |
| DynamoDB Table | State locking to prevent concurrent modifications | `mdw-<env>-us-west-2-tfstate-lock` |

## Usage

### 1. Initialize and Apply

```bash
cd infra/bootstrap
terraform init
terraform apply
```

### 2. Verify Resources

After successful apply, you'll see output like:

```
tfstate_bucket_ids = {
  "dev"  = "mdw-dev-us-west-2-tfstate"
  "prod" = "mdw-prod-us-west-2-tfstate"
}

dynamodb_table_names = {
  "dev"  = "mdw-dev-us-west-2-tfstate-lock"
  "prod" = "mdw-prod-us-west-2-tfstate-lock"
}
```

### 3. Initialize Environment Backends

Now you can initialize the dev/prod environments:

```bash
# Development
cd ../environments/dev
terraform init

# Production
cd ../environments/prod
terraform init
```

## Security Features

- ✅ S3 versioning enabled (state history and recovery)
- ✅ Server-side encryption (AES256)
- ✅ Public access blocked
- ✅ DynamoDB for state locking
- ✅ `prevent_destroy` lifecycle to prevent accidental deletion

## Important Notes

1. **Run this FIRST** before initializing other environments
2. **Do NOT delete** these resources - they contain your infrastructure state
3. Bootstrap uses **local state** (no remote backend for bootstrap itself)
4. The `prevent_destroy` lifecycle rule protects against accidental deletion

## Customization

Edit `variables.tf` to customize:

```hcl
# Add more environments
environments = ["dev", "staging", "prod"]

# Change region
aws_region = "ap-southeast-1"

# Change project name
project = "my-project"
```

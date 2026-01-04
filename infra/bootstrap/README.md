# Bootstrap - Terraform State Backend

This module provisions the S3 bucket required for Terraform remote state management.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform ~> 1.14.0

## Resources Created

| Resource | Purpose | Naming Pattern |
|----------|---------|----------------|
| S3 Bucket | Store Terraform state files | `mdw-dev-us-west-2-tfstate` |

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
  "dev" = "mdw-dev-us-west-2-tfstate"
}
```

### 3. Initialize Environment Backend

Now you can initialize the dev environment:

```bash
cd ../environments/dev
terraform init
```

## Security Features

- ✅ S3 versioning enabled (state history and recovery)
- ✅ Server-side encryption (AES256)
- ✅ Public access blocked
- ✅ S3 native state locking
- ✅ `prevent_destroy` lifecycle to prevent accidental deletion

## Important Notes

1. **Run this FIRST** before initializing environments
2. **Do NOT delete** these resources - they contain your infrastructure state
3. Bootstrap uses **local state** (no remote backend for bootstrap itself)
4. The `prevent_destroy` lifecycle rule protects against accidental deletion

## Customization

Edit `variables.tf` to customize:

```hcl
# Change region
aws_region = "ap-southeast-1"

# Change project name
project = "my-project"
```

# S3 Data Lake Example

This example creates a complete data lake infrastructure with multiple S3 buckets for different purposes.

## Buckets Created

| Bucket | Purpose | Key Features |
|--------|---------|--------------|
| `mdw-<env>-data-raw` | Source data landing zone | Glacier archival after 365 days |
| `mdw-<env>-data-curated` | Processed analytics data | IA transition after 180 days |
| `mdw-<env>-mwaa-artifacts` | DAG and dbt artifacts | Quick version cleanup |
| `mdw-<env>-athena-results` | Query results | 7-day expiration |
| `mdw-<env>-access-logs` | Centralized logging | 7-year retention |

## Usage

```bash
# Initialize
terraform init

# Plan for dev environment
terraform plan -var="environment=dev"

# Apply
terraform apply -var="environment=dev"

# Destroy
terraform destroy -var="environment=dev"
```

## Customization

Create a `terraform.tfvars` file:

```hcl
aws_region  = "us-west-2"
project     = "mdw"
environment = "prod"
owner       = "data-engineering"
cost_center = "CC-DATA-001"
```

Then run:

```bash
terraform apply -var-file="terraform.tfvars"
```

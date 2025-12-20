# Copilot instructions (modern-data-warehouse)

## Big picture
- This repo is an AWS “modern data warehouse” scaffold: Terraform IaC under `infra/` + a dbt project targeting **Athena + Iceberg** under `scripts/mdw_dbt_athena/`.
- Data modeling lives in dbt (currently only staging has models): `scripts/mdw_dbt_athena/models/sta/`.
- Database bootstrap SQL (sample retail schema + Airbyte read user) is in `scripts/database/`.

## Key directories
- `infra/`: Terraform backend + provider constraints (remote state in S3 + DynamoDB locks).
- `infra/modules/`: module folders exist but are currently empty placeholders.
- `scripts/mdw_dbt_athena/`: dbt project (`dbt_project.yml`, `profiles.yml`, `models/`, `macros/`, `target/`).
- `scripts/database/ddl.sql`: creates `sales.*` tables and an `airbyte` replication user; `scripts/database/backout.sql` drops the schema.

## Terraform workflow (AWS)
- Terraform is pinned to `>= 1.14.0 < 1.15.0` and AWS provider `~> 6.0` (see `infra/versions.tf`).
- Remote state is configured in `infra/backend.tf` (bucket `mdw-terraform-remote-state`, region `us-west-2`, DynamoDB lock table `mdw-terraform-locks`).
- Prefer region `us-west-2` (noted in `note.md`).
- Buckets referenced by the project (see `note.md`):
  - `mdw-terraform-remote-state`
  - `mdw-work-zone` (Athena query results)
  - `mdw-athena-warehouse` / `mdw-warehouse` (Iceberg tables / external locations)

## Provisioning infrastructure (AWS best practices)
- The Terraform backend is S3 + DynamoDB (see `infra/backend.tf`) and is pinned to Terraform `>= 1.14.0 < 1.15.0` (see `infra/versions.tf`).
- Default/expected region for this repo is `us-west-2` (see `infra/backend.tf`, `scripts/mdw_dbt_athena/profiles.yml`, and `note.md`).

### 0) Prerequisites & safety rails
- Use a dedicated AWS account (or at least dedicated prefixes) per environment.
- Prefer SSO / short-lived credentials and role assumption over static access keys.
- If you must use access keys locally, keep them out of git and out of Terraform variables checked into the repo.
- Plan for at least these principals:
  - **Terraform operator** (human or CI) that provisions infra.
  - **dbt runner principal** (local dev role or CI role) that runs Athena queries and writes Iceberg tables.
  - **Airbyte EC2 instance profile role** (if you run Airbyte on EC2; see `note.md`).

### 1) Bootstrap remote state (must exist before `terraform init`)
Backend config in `infra/backend.tf` expects:
- S3 bucket: `mdw-terraform-remote-state`
- DynamoDB table: `mdw-terraform-locks` with partition key `LockID` (string)

Recommended hardening for the remote-state bucket:
- Enable **Block Public Access**.
- Enable **default encryption** (SSE-S3 is fine to start; SSE-KMS if you need key control).
- Enable **versioning**.
- (Optional but recommended) Enable **access logging** to a separate log bucket.

AWS CLI bootstrap (PowerShell friendly; run in `us-west-2`):
- Create the bucket:
  - `aws s3api create-bucket --bucket mdw-terraform-remote-state --region us-west-2 --create-bucket-configuration LocationConstraint=us-west-2`
- Block public access:
  - `aws s3api put-public-access-block --bucket mdw-terraform-remote-state --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true`
- Enable encryption (SSE-S3 example):
  - `aws s3api put-bucket-encryption --bucket mdw-terraform-remote-state --server-side-encryption-configuration "{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"AES256\"}}]}"`
- Enable versioning:
  - `aws s3api put-bucket-versioning --bucket mdw-terraform-remote-state --versioning-configuration Status=Enabled`
- Create the lock table:
  - `aws dynamodb create-table --table-name mdw-terraform-locks --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region us-west-2`

Validation checks:
- `aws s3api get-bucket-versioning --bucket mdw-terraform-remote-state`
- `aws s3api get-bucket-encryption --bucket mdw-terraform-remote-state`
- `aws dynamodb describe-table --table-name mdw-terraform-locks --region us-west-2`

### 2) Provision the data lake buckets used by dbt/Athena
This repo separates query results from table data:
- Query results bucket: `mdw-work-zone` (used by dbt profile `s3_staging_dir` in `scripts/mdw_dbt_athena/profiles.yml`).
- Table data bucket: `mdw-warehouse` (used by dbt profile `s3_data_dir` in `scripts/mdw_dbt_athena/profiles.yml`).

Also note model-specific locations:
- `scripts/mdw_dbt_athena/models/sta/dbt_stores_syvh.sql` sets `location='s3://mdw-warehouse/athena/external/staging/'`.
  - Keep this consistent with your `s3_data_dir` conventions and ensure the dbt runner principal can write to that prefix.

Bucket best practices (apply to both `mdw-work-zone` and `mdw-warehouse`):
- Block Public Access on.
- Default encryption on.
- Versioning on.
- Lifecycle policies:
  - For query-results (`mdw-work-zone`), expire old results after N days.
  - For tables (`mdw-warehouse`), consider transitions/retention based on your data governance needs.

Athena-specific best practice:
- Prefer using an **Athena WorkGroup** with enforced result configuration pointing at `mdw-work-zone`.
  - This prevents accidental writes to random buckets and makes costs easier to control.

### 3) IAM patterns (least privilege)
- Airbyte on EC2: use an **Instance Profile** role (IAM role attached to the EC2 instance) instead of long-lived keys (see `note.md`).
- Separate roles/policies by function:
  - `terraform-provisioner`: can create/manage infra.
  - `dbt-runner`: can run Athena, read Glue catalog, and read/write the specific S3 prefixes used for query results + Iceberg table locations.
  - `airbyte-ec2`: can write raw/bronze data locations and update Glue metadata if your pipeline requires it.

If you introduce SSE-KMS:
- Ensure the role(s) have `kms:Encrypt`, `kms:Decrypt`, and `kms:GenerateDataKey` on the CMK.
- Ensure key policy allows the role(s) (key policy is required; IAM permissions alone aren’t enough).

### 4) Terraform execution (this repo)
From repo root:
- `cd infra`
- `terraform fmt -recursive`
- `terraform init`
- `terraform validate`
- `terraform plan`
- `terraform apply`

Notes:
- Because `infra/modules/*` are currently empty placeholders, `plan/apply` won’t create anything until you add root resources and/or wire up modules.
- Prefer a clear root composition file (e.g., `infra/main.tf`) that calls module(s) in `infra/modules/*` and passes shared inputs (region, tags, bucket names).

### 5) Glue/Athena alignment with dbt
dbt config in `scripts/mdw_dbt_athena/profiles.yml` uses:
- `database: awsdatacatalog` (Athena catalog)
- `schema: mdw` (default target schema for models)

Source config in `scripts/mdw_dbt_athena/models/sta/_source.yml` uses:
- `database: awsdatacatalog`
- `schema: iceberg`

Implication:
- Ensure the Athena/Glue database `iceberg` exists and contains the upstream table(s) used by sources (e.g., `stores`).
- Ensure the target database/schema you want dbt to build into (default `mdw`) exists or is creatable by the dbt runner principal.

### 6) Operational hygiene
- Cost/guardrails:
  - Keep to `us-west-2` (repo default) unless you intentionally change all configs.
  - Use separate buckets and prefixes for query results vs table data.
  - Use Athena WorkGroups and (optionally) enforce query result location.
- Naming:
  - Keep S3 prefixes stable; changing Iceberg locations after the fact can be painful.
- Tagging:
  - Apply a consistent `tags` map (example shape in `note.md`) and pass it to all module resources.

### 7) Quick failure triage (common issues)
- `terraform init` fails with backend errors:
  - Remote-state bucket/table are missing or in the wrong region; confirm `mdw-terraform-remote-state` and `mdw-terraform-locks` exist in `us-west-2`.
- dbt/Athena errors writing results:
  - The `mdw-work-zone` bucket/prefix isn’t writable by the dbt principal, or Athena WorkGroup points elsewhere.
- dbt can’t find sources:
  - Glue/Athena database `iceberg` or table `stores` doesn’t exist (see `scripts/mdw_dbt_athena/models/sta/_source.yml`).

## dbt (Athena/Iceberg) workflow
- Python deps live in `scripts/mdw_dbt_athena/requirements.txt` (`dbt-core`, `dbt-athena`).
- The dbt profile template is in `scripts/mdw_dbt_athena/profiles.yml` (Athena, region `us-west-2`, `s3_staging_dir`, `s3_data_dir`, catalog `awsdatacatalog`).
  - Many setups either copy this into `~/.dbt/profiles.yml` or run dbt with `--profiles-dir scripts/mdw_dbt_athena`.
- Default project model config sets `+table_type: iceberg` (see `scripts/mdw_dbt_athena/dbt_project.yml`).
- Example staging model: `scripts/mdw_dbt_athena/models/sta/dbt_stores_syvh.sql` selects from `{{ source('athena_stores','stores') }}` with `materialized='table'` and an explicit S3 `location`.
- Source definitions live alongside models (example: `scripts/mdw_dbt_athena/models/sta/_source.yml` uses `database: awsdatacatalog`, `schema: iceberg`).

## Common commands
- From repo root (if your environment already has the profile configured):
  - `dbt run --select dbt_stores_syvh --target dev --vars "{pdate: 'YYYYMMDD'}"`
  - `dbt test --target dev`
- From scratch (per `note.md`): create a venv and install requirements from the dbt folder.

## Conventions for AI edits
- Don’t edit generated dbt artifacts under `scripts/mdw_dbt_athena/target/`.
- When adding dbt models, follow the layer folders: `src/` → `sta/` → `dim/`/`fact/` → `mart/` (some folders may be empty today).
- Keep Athena/Iceberg specifics explicit: S3 locations (`location=...`) and Iceberg table type where required by existing patterns.

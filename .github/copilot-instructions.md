# Copilot Instructions - Modern Data Warehouse

## Project Overview

This is a **modern data warehouse project** for grocery sales analytics using:
- **dbt** (dbt-core + dbt-athena) for data transformations
- **Terraform** for AWS infrastructure provisioning
- **PostgreSQL-compatible** database schemas (targeting AWS Athena with Iceberg tables)

## Architecture

```
Source Data → S3 → Athena → dbt Transformations → Analytics
```

**Key directories:**
- `infra/modules/` - Terraform modules for AWS resources (S3, Athena, IAM, etc.)
- `scripts/database/` - SQL scripts for initial database and schema setup
- `dbt/` - dbt project with models, macros, and configurations
- `docs/images/` - Architecture diagrams (`architecture/`) and ERD (`database/`)
- `.github/dataset-instructions.md` - Authoritative data dictionary (7 tables, grocery sales domain)


## Create Commit and Pull Request

This section defines how GitHub Copilot should assist developers in creating commits and pull requests.

### Commit

When summarizing code changes:
- Analyze staged files and identify the primary intent of the change.
- Group related changes logically.
- Generate a conventional commit message.

Commit message format:
```
<type>(<scope>): <short description>
```

Commit types:
- `feat`: New feature or functionality
- `fix`: Bug fix
- `refactor`: Code restructuring without behavior change
- `docs`: Documentation changes
- `chore`: Maintenance tasks (dependencies, configs)
- `test`: Adding or updating tests

Guidelines:
- Use imperative mood (e.g., "add", "fix", "update").
- Keep the subject line under 72 characters.
- Scope is optional but recommended (e.g., `feat(schema):`).
- Do not end the subject line with a period.

### Pull Request

When generating a PR:
- Title: Use the same format as commit messages, summarizing the overall change.
- Description: Use Markdown with clear sections.

Required sections in PR description:
- **What changed**: List of changes in bullet points.
- **Why the change is needed**: Brief justification.
- **Breaking changes**: Explicitly state `None` if there are no breaking changes.

### PR Description Template

Use this exact template:

```markdown
## Summary

Brief one-line summary of the PR.

---

### What Changed

- Change 1
- Change 2
- Change 3

---

### Why This Change Is Needed

Explain the motivation or context.

---

### Breaking Changes

None.

---

### Checklist

- [ ] Code reviewed
- [ ] Documentation updated (if applicable)
- [ ] Tests passing (if applicable)
```

### Submission

Steps to push and create a PR:

1. Stage and commit changes:
   ```bash
   git add .
   git commit -m "<type>(<scope>): <description>"
   ```

2. Push the feature branch:
   ```bash
   git push origin <branch-name>
   ```

3. Create a PR using GitHub CLI:
   ```bash
   gh pr create --base main --head <branch-name> --title "<PR title>" --body "<PR description>"
   ```

   Or interactively:
   ```bash
   gh pr create --base main --head <branch-name>
   ```

### Identifying Unmerged Commits

Before creating a PR, the agent **MUST** identify only commits that have not yet been merged into the target branch.

**Required steps:**

1. Fetch the latest target branch:
   ```bash
   git fetch origin main
   ```

2. Identify unmerged commits:
   ```bash
   git log --oneline origin/main..<source-branch>
   ```

3. Review only the diff of unmerged commits:
   ```bash
   git diff origin/main..<source-branch>
   ```

**Rules:**

- **MUST** process only commits returned by `git log origin/main..<source-branch>`
- **MUST NOT** include already merged commits in summaries, PR descriptions, or commit lists
- **MUST NOT** rewrite, reprocess, or modify existing merged history
- **MUST NOT** create a PR if there are no unmerged commits

### PR Description Accuracy

The PR description **MUST** accurately and completely reflect the actual code changes.

**Mandatory requirements:**

1. **Derived from diff only**: All items in "What Changed" must come directly from `git diff origin/main..<source-branch>`
2. **No fabrication**: MUST NOT include inferred, assumed, or fabricated changes
3. **No exaggeration**: MUST NOT overstate the scope or impact of changes
4. **No omission**: MUST NOT omit significant changes visible in the diff
5. **Truthful summary**: The summary must match what the diff actually shows

**Verification checklist before PR creation:**

- [ ] Ran `git log origin/main..<source-branch>` to identify unmerged commits
- [ ] Ran `git diff origin/main..<source-branch> --stat` to verify changed files
- [ ] Each bullet in "What Changed" corresponds to actual changes in the diff
- [ ] No changes from previously merged PRs are mentioned
- [ ] PR title reflects the primary change type from unmerged commits only

**Example workflow:**

```bash
# 1. Fetch latest main
git fetch origin main

# 2. List unmerged commits
git log --oneline origin/main..dev
# Output: 
# abc1234 feat: add dbt_run_at column
# def5678 fix: update package sources

# 3. View summary of changes
git diff origin/main..dev --stat

# 4. Create PR based ONLY on these commits
gh pr create --base main --head dev --title "..." --body "..."
```

Notes:
- Copilot generates the commit message, PR title, and PR description.
- The developer reviews, adjusts if needed, and submits the PR.
- Always verify the target branch (`--base`) before submission.
- **PowerShell escaping**: When using `gh pr create` in PowerShell, use double backticks (``` `` ```) instead of single backticks for inline code in the PR body. Single backticks are escape characters in PowerShell and will be stripped.

---

## Write dbt Model

This section defines authoritative rules for generating dbt models in this project. All AI tools **MUST strictly follow** these instructions.

### Technology Stack

| Component       | Technology                          |
|-----------------|-------------------------------------|
| Query Engine    | AWS Athena                          |
| Storage Layer   | Amazon S3                           |
| Table Format    | Iceberg (std and cur layers only)   |
| Transformation  | dbt (dbt-core + dbt-athena)         |
| Architecture    | Lakehouse Medallion                 |

### Core Principles

1. **Strict layer separation** - Each layer has a single responsibility. NEVER skip layers.
2. **Raw data immutability** - NEVER modify data in the raw layer. Treat it as read-only.
3. **Iceberg for analytics layers** - std and cur layers MUST use Iceberg tables.
4. **Athena cost awareness** - Minimize data scanned. Use partition pruning, columnar formats, and snappy compression.
5. **No invented technologies** - Only use Athena, S3, Iceberg, and dbt. MUST NOT assume Delta or Hudi.
6. **ELT only** - dbt handles transformations only. MUST NOT include ingestion, orchestration, or CI/CD logic.

---

### Global Naming Convention

All model names MUST follow this pattern:

```
mdw_<layer>_<table_name>
```

**Additional naming rules:**
- Fact tables MUST include `ft` in the table name
- Dimension tables MUST include `dim` in the table name
- All names MUST use `snake_case`

**Examples:**

| Table Type | Layer | Example Name              |
|------------|-------|---------------------------|
| Raw        | raw   | `mdw_raw_sales`           |
| Raw        | raw   | `mdw_raw_customers`       |
| Staging    | stg   | `mdw_stg_sales`           |
| Staging    | stg   | `mdw_stg_customers`       |
| Dimension  | std   | `mdw_std_dim_customers`   |
| Dimension  | std   | `mdw_std_dim_products`    |
| Fact       | cur   | `mdw_cur_ft_sales`        |
| Aggregate  | cur   | `mdw_cur_daily_revenue`   |

---

### Data Storage Rules

| Layer | Storage Format         | Table Type            | Compression |
|-------|------------------------|-----------------------|-------------|
| raw   | Original source format | Athena external table | N/A         |
| stg   | Original source format | View                  | N/A         |
| std   | Parquet                | Iceberg               | Snappy      |
| cur   | Parquet                | Iceberg               | Snappy      |

**Iceberg requirements (std and cur):**
- MUST use Parquet file format
- MUST enable Snappy compression
- MUST apply partitioning for tables > 1GB
- SHOULD target file sizes of 128MB-256MB

---

### Partitioning Rules

**Partition column requirements:**
- Partition column name MUST be exactly: `partition`
- Partition value MUST be derived from a date column
- Partition format MUST be: `YYYYMMDD` (e.g., `20240115`)
- MUST use Hive-style partitioning in S3

**Partition column handling:**
- The `partition` column MUST be explicitly defined in the SELECT statement
- The `partition` column MUST be the **last column** in the SELECT
- Partition values MUST be generated using: `date_format(<date_column>, '%Y%m%d')`

---

### Layer Definitions

#### 1. Raw Layer (`raw`)

| Attribute              | Specification                                              |
|------------------------|------------------------------------------------------------|
| **Purpose**            | Expose external data from S3 as queryable tables           |
| **Responsibility**     | Define external table schema; no transformations           |
| **Storage Format**     | Original source format (CSV, JSON, Parquet)                |
| **Table Type**         | Athena external table                                      |
| **Folder Path**        | `models/raw/`                                              |
| **Naming Pattern**     | `mdw_raw_<entity>`                                         |
| **Materialization**    | `external`                                                 |
| **Allowed**            | Column definitions, data types, S3 location, file format   |
| **Forbidden**          | Any SQL transformations, filters, joins, calculations      |

**Example Model Name:** `mdw_raw_sales`

**Example schema.yml:**
```yaml
version: 2

sources:
  - name: grocery
    schema: raw
    tables:
      - name: mdw_raw_sales
        external:
          location: "s3://{{ env_var('S3_BUCKET') }}/raw/sales/"
          file_format: csv
          row_format: serde 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
        columns:
          - name: sales_id
            data_type: int
          - name: sales_date
            data_type: string
          - name: customer_id
            data_type: int
```

---

#### 2. Staging Layer (`stg`)

| Attribute              | Specification                                              |
|------------------------|------------------------------------------------------------|
| **Purpose**            | Clean, rename, and type-cast raw data                      |
| **Responsibility**     | 1:1 mapping with raw; light transformations only           |
| **Storage Format**     | N/A (view)                                                 |
| **Table Type**         | View                                                       |
| **Folder Path**        | `models/stg/`                                              |
| **Naming Pattern**     | `mdw_stg_<entity>`                                         |
| **Materialization**    | `view`                                                     |
| **Allowed**            | Column renaming, type casting, NULL handling, deduplication|
| **Forbidden**          | Joins, aggregations, business logic, calculated fields     |

**Example Model Name:** `mdw_stg_sales`

**Example SQL:**
```sql
-- models/stg/mdw_stg_sales.sql
with source as (
    select * from {{ source('grocery', 'mdw_raw_sales') }}
),

cleaned as (
    select
        cast(sales_id as bigint) as sales_id,
        cast(salesperson_id as bigint) as salesperson_id,
        cast(customer_id as bigint) as customer_id,
        cast(product_id as bigint) as product_id,
        cast(quantity as int) as quantity,
        cast(discount as decimal(10,2)) as discount,
        cast(total_price as decimal(10,2)) as total_price,
        cast(sales_date as timestamp) as sales_at,
        transaction_number
    from source
)

select * from cleaned
```

---

#### 3. Standardized Layer (`std`)

| Attribute              | Specification                                              |
|------------------------|------------------------------------------------------------|
| **Purpose**            | Apply business logic and create entity-centric models      |
| **Responsibility**     | Joins, business rules, derived columns, data enrichment    |
| **Storage Format**     | Parquet (via Iceberg)                                      |
| **Table Type**         | Iceberg table                                              |
| **Folder Path**        | `models/std/`                                              |
| **Naming Pattern**     | `mdw_std_dim_<entity>` (dimensions) or `mdw_std_<entity>`  |
| **Materialization**    | `table` (Iceberg)                                          |
| **Allowed**            | Joins, business calculations, surrogate keys, SCD logic    |
| **Forbidden**          | Aggregations, metrics, report-specific transformations     |

**Example Model Name (Dimension):** `mdw_std_dim_customers`

**Example SQL (Dimension):**
```sql
-- models/std/mdw_std_dim_customers.sql
{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with customers as (
    select * from {{ ref('mdw_stg_customers') }}
),

cities as (
    select * from {{ ref('mdw_stg_cities') }}
),

countries as (
    select * from {{ ref('mdw_stg_countries') }}
),

enriched as (
    select
        cu.customer_id,
        cu.first_name,
        cu.middle_initial,
        cu.last_name,
        cu.first_name || ' ' || cu.last_name as full_name,
        cu.address,
        ci.city_name,
        ci.zipcode,
        co.country_name,
        co.country_code
    from customers cu
    left join cities ci on cu.city_id = ci.city_id
    left join countries co on ci.country_id = co.country_id
)

select * from enriched
```

---

#### 4. Curated Layer (`cur`)

| Attribute              | Specification                                              |
|------------------------|------------------------------------------------------------|
| **Purpose**            | Provide analytics-ready, aggregated datasets               |
| **Responsibility**     | Metrics, KPIs, aggregations, denormalized reporting tables |
| **Storage Format**     | Parquet (via Iceberg)                                      |
| **Table Type**         | Iceberg table (partitioned)                                |
| **Folder Path**        | `models/cur/`                                              |
| **Naming Pattern**     | `mdw_cur_ft_<entity>` (facts) or `mdw_cur_<metric>`        |
| **Materialization**    | `table` (Iceberg) or `incremental` for fact tables         |
| **Allowed**            | Aggregations, window functions, metrics, final joins       |
| **Forbidden**          | Raw source references, business logic changes              |

**Example Model Name (Fact):** `mdw_cur_ft_sales`

**Example SQL (Fact with partitioning):**
```sql
-- models/cur/mdw_cur_ft_sales.sql
{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        partitioned_by=['partition']
    )
}}

with sales as (
    select * from {{ ref('mdw_stg_sales') }}
),

products as (
    select * from {{ ref('mdw_std_dim_products') }}
),

customers as (
    select * from {{ ref('mdw_std_dim_customers') }}
),

fact_sales as (
    select
        s.sales_id,
        s.transaction_number,
        s.customer_id,
        c.full_name as customer_name,
        s.product_id,
        p.product_name,
        p.category_name,
        s.salesperson_id,
        s.quantity,
        p.price as unit_price,
        s.discount,
        s.total_price,
        s.sales_at,
        date(s.sales_at) as sales_date,
        date_format(s.sales_at, '%Y%m%d') as partition
    from sales s
    left join products p on s.product_id = p.product_id
    left join customers c on s.customer_id = c.customer_id
)

select * from fact_sales
```

**Example SQL (Incremental Fact):**
```sql
-- models/cur/mdw_cur_ft_sales.sql
{{
    config(
        materialized='incremental',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        incremental_strategy='append',
        partitioned_by=['partition'],
        on_schema_change='fail'
    )
}}

with sales as (
    select * from {{ ref('mdw_stg_sales') }}
    {% if is_incremental() %}
    where sales_at > (select max(sales_at) from {{ this }})
    {% endif %}
),

-- ... rest of transformations ...

fact_sales as (
    select
        -- columns...
        date_format(s.sales_at, '%Y%m%d') as partition
    from sales s
    -- joins...
)

select * from fact_sales
```

---

### Athena + Iceberg Best Practices

#### Mandatory Rules

- **MUST use `{{ source() }}`** for raw layer references
- **MUST use `{{ ref() }}`** for all model references
- **MUST NOT use hardcoded table names** in SQL
- **MUST NOT use `SELECT *`** in stg, std, or cur layers (always list columns explicitly)
- **MUST specify `table_type='iceberg'`** for std and cur models

#### Materialization Guidelines

| Layer | Materialization       | Table Type | Partitioned |
|-------|-----------------------|------------|-------------|
| raw   | external              | External   | Optional    |
| stg   | view                  | View       | N/A         |
| std   | table                 | Iceberg    | Optional    |
| cur   | table or incremental  | Iceberg    | Required    |

#### Incremental Models (Iceberg)

**When to use:**
- Fact tables with append-only or slowly changing data
- Tables with a reliable timestamp column for filtering
- Large datasets (> 10M rows) where full refresh is expensive

**When NOT to use:**
- Dimension tables (use full refresh)
- Small tables (< 1M rows)
- Tables requiring complex merge logic

**Iceberg incremental strategies:**
- `append` - Add new rows only (recommended for fact tables)
- `merge` - Upsert based on unique key (for SCD Type 1)

#### Partitioning Strategies

| Strategy          | Use Case                                | Example                     |
|-------------------|----------------------------------------|-----------------------------|
| Daily partition   | High-volume transactional data         | `partition = '20240115'`    |
| Monthly partition | Medium-volume data, monthly reporting  | Derive from daily partition |
| No partition      | Small dimension tables (< 1GB)         | N/A                         |

**Partitioning rules:**
- MUST use single partition column named `partition`
- MUST format as `YYYYMMDD`
- MUST NOT over-partition (avoid > 10,000 partitions)

#### File Size Optimization

| Problem             | Impact                    | Solution                              |
|---------------------|---------------------------|---------------------------------------|
| Many small files    | Slow queries, high cost   | Use Iceberg compaction                |
| Very large files    | Memory pressure           | Target 128MB-256MB file size          |
| Too many partitions | Metadata overhead         | Use coarser partition granularity     |

#### Athena Anti-Patterns to Avoid

| Anti-Pattern                         | Why It's Bad                              | Correct Approach                    |
|--------------------------------------|-------------------------------------------|-------------------------------------|
| `SELECT *`                           | Scans all columns; increases cost         | List columns explicitly             |
| Missing partition filter             | Full table scan                           | Always filter on `partition`        |
| Unpartitioned large tables           | Full table scan on every query            | Add `partition` column              |
| Non-Iceberg tables in std/cur        | Missing ACID, compaction, time travel     | Use `table_type='iceberg'`          |
| Hardcoded S3 paths                   | Breaks portability                        | Use `{{ source() }}` or env vars    |
| `ORDER BY` without `LIMIT`           | Sorts entire dataset in memory            | Add `LIMIT` or remove sort          |
| Cross joins                          | Cartesian product; explodes data          | Use explicit join conditions        |

---

### Testing Requirements

| Layer | Required Tests                                            |
|-------|-----------------------------------------------------------|
| stg   | `unique`, `not_null` on primary keys                      |
| std   | `unique`, `not_null`, `relationships` for foreign keys    |
| cur   | `not_null` on key metrics, `accepted_values` where needed |

**Example schema.yml:**
```yaml
version: 2

models:
  - name: mdw_stg_sales
    columns:
      - name: sales_id
        tests:
          - unique
          - not_null
      - name: customer_id
        tests:
          - not_null
          - relationships:
              to: ref('mdw_stg_customers')
              field: customer_id

  - name: mdw_cur_ft_sales
    columns:
      - name: sales_id
        tests:
          - unique
          - not_null
      - name: total_price
        tests:
          - not_null
      - name: partition
        tests:
          - not_null
```

---

### Documentation Requirements

Every model MUST have a `schema.yml` entry with:
- Model description
- Column descriptions for all columns
- Tests for critical columns

**Example:**
```yaml
version: 2

models:
  - name: mdw_cur_ft_sales
    description: "Curated fact table containing enriched sales transactions partitioned by date."
    columns:
      - name: sales_id
        description: "Primary key. Unique identifier for each sale."
      - name: customer_id
        description: "Foreign key to mdw_std_dim_customers."
      - name: total_price
        description: "Final sale price after discounts."
      - name: partition
        description: "Partition key in YYYYMMDD format derived from sales_at."
```

---

### dbt Coding Standards

#### SQL Style Rules

1. **Use lowercase** for all SQL keywords (`select`, `from`, `where`)
2. **One column per line** in SELECT statements
3. **Use CTEs** instead of subqueries; name CTEs descriptively
4. **Indent with 4 spaces**, not tabs
5. **Trailing commas** after each column (except the last)
6. **Explicit column aliases** using `as`
7. **No trailing whitespace** at end of lines
8. **Partition column MUST be last** in SELECT statements

**Example formatting:**
```sql
with source as (
    select * from {{ source('grocery', 'mdw_raw_sales') }}
),

cleaned as (
    select
        cast(sales_id as bigint) as sales_id,
        cast(customer_id as bigint) as customer_id,
        cast(product_id as bigint) as product_id,
        cast(quantity as int) as quantity,
        cast(total_price as decimal(10,2)) as total_price,
        cast(sales_date as timestamp) as sales_at,
        date_format(cast(sales_date as timestamp), '%Y%m%d') as partition
    from source
    where quantity > 0
)

select * from cleaned
```

#### Jinja Usage Rules

- MUST use `{{ ref() }}` for all model references
- MUST use `{{ source() }}` for all raw/external table references
- MUST use `{{ config() }}` block at the top of the file
- SHOULD avoid complex Jinja logic in models; use macros instead
- MUST use `{% if is_incremental() %}` only in incremental models
- SHOULD use `{{ env_var() }}` for environment-specific values

#### Reusability and Modularization

- Create **macros** for repeated SQL patterns (e.g., partition generation, surrogate keys)
- Store macros in `macros/` directory
- Use **packages** (e.g., `dbt-utils`, `dbt-expectations`) for common utilities
- MUST NOT duplicate transformation logic across models

---

### dbt Project Structure

```
dbt_project/
├── dbt_project.yml
├── packages.yml
├── models/
│   ├── raw/
│   │   └── schema.yml
│   ├── stg/
│   │   ├── mdw_stg_sales.sql
│   │   ├── mdw_stg_customers.sql
│   │   ├── mdw_stg_products.sql
│   │   └── schema.yml
│   ├── std/
│   │   ├── mdw_std_dim_customers.sql
│   │   ├── mdw_std_dim_products.sql
│   │   └── schema.yml
│   └── cur/
│       ├── mdw_cur_ft_sales.sql
│       ├── mdw_cur_daily_revenue.sql
│       └── schema.yml
├── macros/
│   ├── generate_partition.sql
│   └── generate_surrogate_key.sql
├── seeds/
├── snapshots/
└── tests/
```

---

### Quick Reference Card

| Layer | Prefix         | Table Type | Materialization | Format  | Partitioned |
|-------|----------------|------------|-----------------|---------|-------------|
| raw   | `mdw_raw_`     | External   | external        | Source  | Optional    |
| stg   | `mdw_stg_`     | View       | view            | N/A     | N/A         |
| std   | `mdw_std_dim_` | Iceberg    | table           | Parquet | Optional    |
| cur   | `mdw_cur_ft_`  | Iceberg    | table/incremental | Parquet | Required    |

---

### Checklist Before Generating a Model

- [ ] Used correct naming pattern (`mdw_<layer>_<table_name>`)
- [ ] Included `ft` for fact tables or `dim` for dimension tables
- [ ] Placed file in correct folder (`models/<layer>/`)
- [ ] Used `{{ source() }}` or `{{ ref() }}` (no hardcoded tables)
- [ ] Listed all columns explicitly (no `SELECT *`)
- [ ] Added `partition` column (YYYYMMDD format) for cur layer
- [ ] Configured `table_type='iceberg'` for std and cur layers
- [ ] Added `schema.yml` with descriptions and tests
- [ ] Applied appropriate materialization
- [ ] Followed SQL style guidelines

---

## Write Terraform Infrastructure

This section defines **authoritative rules** for provisioning AWS infrastructure using Terraform. All AI tools **MUST strictly follow** these instructions when generating or reviewing Terraform code.

### Technology Stack

| Component | Technology |
|-----------|------------|
| Cloud Provider | AWS |
| Default Region | us-west-2 |
| IaC Tool | Terraform |
| State Backend | S3 + DynamoDB |

### Core Principles

1. **Infrastructure as Code** - All infrastructure MUST be defined in Terraform; manual AWS Console changes are forbidden
2. **Idempotency** - Configurations MUST produce the same result when applied multiple times
3. **Environment Isolation** - MUST maintain separate state files for each environment (dev, prod)
4. **Remote State** - MUST use S3 backend with DynamoDB for state locking
5. **Security First** - MUST follow least privilege; deny by default
6. **Version Control** - MUST version control all Terraform configurations in Git

---

### Mandatory Tagging Standard

All AWS resources **MUST** include the following tags:

```hcl
tags = {
  owner         = "sy.vuhuu"
  managed_by    = "it-cloud-aws"
  project       = var.project_name
  resource_type = "<resource-type>"
  env           = var.environment
  created_by    = "terraform"
  created_date  = "YYYYMMDD"
}
```

**Tag Definitions:**

| Tag Key | Description | Example Values |
|---------|-------------|----------------|
| `owner` | Team or individual responsible | `sy.vuhuu` |
| `managed_by` | Managing organization/team | `it-cloud-aws` |
| `project` | Project identifier | `mdw`, `data-platform` |
| `resource_type` | AWS resource type | `s3`, `iam-role`, `glue-database` |
| `env` | Deployment environment | `dev`, `prod` |
| `created_by` | Provisioning method | `terraform` |
| `created_date` | Creation date | `20251221` |

**Implementation Pattern:**
```hcl
locals {
  common_tags = {
    owner        = var.owner
    managed_by   = var.managed_by
    project      = var.project_name
    env          = var.environment
    created_by   = "terraform"
    created_date = formatdate("YYYYMMDD", timestamp())
  }
}

resource "aws_s3_bucket" "data_lake" {
  bucket = "${var.project_name}-${var.environment}-data-lake"

  tags = merge(local.common_tags, {
    resource_type = "s3"
  })
}
```

---

### Project Structure

```
infra/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── terraform.tfvars
│   │   ├── backend.tf
│   │   └── versions.tf
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       ├── backend.tf
│       └── versions.tf
├── modules/
│   ├── s3/
│   ├── iam/
│   └── glue/
└── README.md
```

**File Responsibilities:**

| File | Responsibility |
|------|----------------|
| `main.tf` | Resource definitions and module calls |
| `variables.tf` | Input variable declarations with descriptions |
| `outputs.tf` | Output value definitions |
| `versions.tf` | Terraform and provider version constraints |
| `backend.tf` | Remote state backend configuration |
| `terraform.tfvars` | Environment-specific variable values |
| `locals.tf` | Local values and computed expressions (optional) |

---

### AWS Resource Naming Conventions

All AWS resources **MUST** follow this standardized naming format:

```
<project>-<env>-<region>-<name>
```

#### Naming Components

| Component | Description | Rules |
|-----------|-------------|-------|
| `project` | Short project identifier | Lowercase, alphanumeric, typically 2-5 characters |
| `env` | Environment identifier | **Restricted values only:** `dev`, `prod` |
| `region` | AWS region code | Official AWS region format (e.g., `ap-southeast-1`, `us-east-1`) |
| `name` | Descriptive resource name | Lowercase, hyphens allowed, describes resource purpose |

#### Environment Rules

The `env` value **MUST** be exactly one of:
- `dev` - Development environment
- `prod` - Production environment

**MUST NOT** use other values such as: `test`, `staging`, `stg`, `qa`, `sandbox`, `uat`

#### Region Rules

The `region` value **MUST**:
- Use the official AWS region format (e.g., `ap-southeast-1`, `us-east-1`, `eu-west-1`)
- Match the actual region where the resource is deployed
- Be included in all resource names for multi-region clarity

#### General Rules

- **MUST** use lowercase letters, numbers, and hyphens only
- **MUST NOT** use underscores in AWS resource names (use hyphens)
- **MUST NOT** exceed AWS naming limits
- **MUST** maintain consistent component ordering: `project-env-region-name`

#### Scope of Enforcement

This naming convention **MUST** be applied consistently across:
- All AWS resources (S3, IAM, MWAA, Glue, Athena, EC2, VPC, Lambda, etc.)
- Infrastructure as Code (Terraform, CloudFormation)
- CI/CD pipelines and related configuration files
- Code examples, snippets, and generated templates

#### Correct Examples

| Resource Type | Example Name |
|---------------|--------------|
| S3 Bucket | `mdw-dev-ap-southeast-1-data-raw` |
| S3 Bucket | `mdw-prod-ap-southeast-1-mwaa-artifacts` |
| IAM Role | `mdw-prod-us-east-1-glue-crawler-role` |
| IAM Policy | `mdw-dev-ap-southeast-1-athena-access-policy` |
| MWAA Environment | `mdw-dev-ap-southeast-1-mwaa` |
| Athena Workgroup | `mdw-prod-ap-southeast-1-analytics` |
| Glue Crawler | `mdw-dev-ap-southeast-1-sales-crawler` |

#### Incorrect Examples (MUST NOT Use)

| Incorrect Name | Reason |
|----------------|--------|
| `mdw-ap-southeast-1-prod-mwaa` | Wrong order: region before env |
| `mdw-dev-mwaa` | Missing region component |
| `mwaa-mdw-prod` | Wrong order: name before project |
| `mdw-staging-ap-southeast-1-s3` | Invalid env value (`staging`) |
| `mdw_dev_ap_southeast_1_data` | Uses underscores instead of hyphens |

#### Exception: Glue Databases

Glue databases use underscores due to Athena/Hive naming requirements:

```
<project>_<env>_<region_underscored>_<purpose>
```

Example: `mdw_dev_ap_southeast_1_raw`

#### Clarification Requirement

If `project` or `region` cannot be inferred from context, Copilot **MUST** ask for clarification instead of guessing or using placeholder values.

---

### Provider and Backend Configuration

**Provider Configuration:**
```hcl
# versions.tf
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# main.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      owner      = var.owner
      managed_by = var.managed_by
      project    = var.project_name
      env        = var.environment
      created_by = "terraform"
    }
  }
}
```

**Backend Configuration:**
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket         = "mdw-terraform-state"
    key            = "env/dev/terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "mdw-terraform-locks"
  }
}
```

---

### Security Best Practices

#### IAM Least Privilege

- **MUST** grant minimum permissions required for functionality
- **MUST** scope permissions to specific resources where possible
- **MUST NOT** use `*` for resources unless absolutely necessary
- **MUST NOT** use AWS managed `AdministratorAccess` or `PowerUserAccess` policies

**Example:**
```hcl
# Good: Scoped permissions
data "aws_iam_policy_document" "glue_s3_access" {
  statement {
    sid    = "ReadRawData"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.raw.arn,
      "${aws_s3_bucket.raw.arn}/*"
    ]
  }
}

# Bad: Overly permissive
data "aws_iam_policy_document" "bad_example" {
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }
}
```

#### Credential Management

- **MUST NOT** hardcode credentials in Terraform files
- **MUST NOT** commit `.tfvars` files containing secrets to version control
- **MUST** use AWS IAM roles for service-to-service authentication
- **SHOULD** use AWS Secrets Manager or SSM Parameter Store for secrets

#### Encryption Standards

- **MUST** enable encryption at rest for S3 buckets
- **MUST** block public access to S3 buckets by default
- **SHOULD** use AWS KMS customer-managed keys for production

**Example:**
```hcl
resource "aws_s3_bucket_public_access_block" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_lake" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
```

---

### Terraform Coding Standards

#### Formatting Conventions

- **MUST** run `terraform fmt` before committing code
- **MUST** use 2-space indentation (Terraform default)
- **MUST** place meta-arguments (`count`, `for_each`, `depends_on`) first

#### Variable Standards

- **MUST** include `description` for all variables
- **MUST** specify `type` for all variables
- **SHOULD** include `validation` blocks for constrained values
- **SHOULD** provide `default` values where sensible

**Example:**
```hcl
variable "environment" {
  description = "Deployment environment. Valid values: dev, prod"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be 'dev' or 'prod'."
  }
}
```

#### Use of Locals

- **MUST** use `locals` for repeated values or complex expressions
- **MUST** use `locals` for tag maps used across multiple resources

**Example:**
```hcl
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    owner        = var.owner
    managed_by   = var.managed_by
    project      = var.project_name
    env          = var.environment
    created_by   = "terraform"
    created_date = formatdate("YYYYMMDD", timestamp())
  }
}
```

#### Avoiding Duplication

- **MUST** use `for_each` or `count` for similar resources
- **MUST** extract repeated patterns into modules
- **MUST NOT** copy-paste resource blocks with minor variations

---

### Operational Best Practices

#### Plan Before Apply

- **MUST** run `terraform plan` before every `terraform apply`
- **MUST** review plan output for unexpected changes
- **SHOULD** use `-out` flag to save plans for production

```bash
# Development
terraform plan
terraform apply

# Production
terraform plan -out=tfplan
terraform apply tfplan
```

#### Destroy Protection

- **MUST** use `prevent_destroy` for critical resources
- **MUST** enable deletion protection for production databases

```hcl
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.project_name}-terraform-state"

  lifecycle {
    prevent_destroy = true
  }
}
```

---

### Anti-Patterns to Avoid

| Anti-Pattern | Why It's Bad | Correct Approach |
|--------------|--------------|------------------|
| Hardcoded credentials | Security risk | Use IAM roles or environment variables |
| `resources = ["*"]` | Violates least privilege | Scope to specific ARNs |
| No remote state | State loss, no collaboration | Use S3 + DynamoDB backend |
| No version pinning | Unpredictable behavior | Pin Terraform and provider versions |
| Missing tags | Poor governance, cost tracking | Apply mandatory tags to all resources |
| Public S3 buckets | Data exposure risk | Block public access by default |
| `terraform apply` without plan | Unexpected changes | Always review plan first |
| Manual console changes | State drift | All changes via Terraform |

---

### Checklist Before Applying Terraform

- [ ] Ran `terraform fmt` and `terraform validate`
- [ ] Reviewed `terraform plan` output
- [ ] No unexpected resource destructions
- [ ] All resources have required tags
- [ ] Sensitive variables marked as sensitive
- [ ] No hardcoded credentials or account IDs
- [ ] S3 buckets have public access blocked
- [ ] IAM policies follow least privilege
- [ ] Documentation updated (if applicable)

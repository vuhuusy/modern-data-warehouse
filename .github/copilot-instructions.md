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

Notes:
- Copilot generates the commit message, PR title, and PR description.
- The developer reviews, adjusts if needed, and submits the PR.
- Always verify the target branch (`--base`) before submission.

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

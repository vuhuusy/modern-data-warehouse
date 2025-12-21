# Modern Data Warehouse

A modern data warehouse project for grocery sales analytics built on AWS using the Lakehouse Medallion architecture.

## Project Overview

This project implements a scalable data warehouse solution for analyzing grocery sales data. It leverages **AWS Athena** as the query engine, **Amazon S3** as the storage layer, and **dbt** for ELT transformations. The architecture follows the **Lakehouse Medallion** pattern with four distinct layers: raw, staging, standardized, and curated.

### Key Features

- **Serverless architecture** - No infrastructure to manage; pay only for queries executed
- **Iceberg table format** - ACID transactions, time travel, and efficient data compaction
- **Layered data modeling** - Clear separation of concerns across transformation stages
- **Cost-optimized** - Partition pruning, columnar storage, and compression reduce query costs

### Dataset

The project uses the **Grocery Sales Database**, a simulated retail dataset containing:

| Table        | Description                  | Granularity          |
|--------------|------------------------------|----------------------|
| `categories` | Product category definitions | One row per category |
| `cities`     | City-level geographic data   | One row per city     |
| `countries`  | Country-level metadata       | One row per country  |
| `customers`  | Customer master data         | One row per customer |
| `employees`  | Employee/salesperson data    | One row per employee |
| `products`   | Product catalog              | One row per product  |
| `sales`      | Sales transactions           | One row per transaction |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              Data Flow                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   Source Data (CSV)                                                          │
│         │                                                                    │
│         ▼                                                                    │
│   ┌───────────┐    ┌───────────┐    ┌───────────┐    ┌───────────┐         │
│   │    raw    │───▶│    stg    │───▶│    std    │───▶│    cur    │         │
│   │  (S3/CSV) │    │  (Views)  │    │ (Iceberg) │    │ (Iceberg) │         │
│   └───────────┘    └───────────┘    └───────────┘    └───────────┘         │
│         │                                                   │                │
│         │              AWS Athena (Query Engine)            │                │
│         └───────────────────────────────────────────────────┘                │
│                                                                              │
│                           Amazon S3 (Storage)                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Data Flow

1. **Source → raw**: CSV files are loaded into S3 and exposed as Athena external tables
2. **raw → stg**: Staging views clean, rename, and type-cast raw data
3. **stg → std**: Standardized Iceberg tables apply business logic and create dimensions
4. **std → cur**: Curated Iceberg tables provide analytics-ready facts and aggregations

---

## Technology Stack

| Component       | Technology                          | Purpose                              |
|-----------------|-------------------------------------|--------------------------------------|
| Query Engine    | AWS Athena                          | Serverless SQL query execution       |
| Storage Layer   | Amazon S3                           | Scalable object storage              |
| Table Format    | Apache Iceberg                      | ACID transactions, schema evolution  |
| Transformation  | dbt (dbt-core + dbt-athena)         | ELT transformations and modeling     |
| Infrastructure  | Terraform                           | Infrastructure as Code               |
| Architecture    | Lakehouse Medallion                 | Layered data modeling pattern        |

---

## Data Modeling Approach

The project follows the **Lakehouse Medallion architecture** with four layers, each with a specific responsibility.

### Raw Layer (`raw`)

| Attribute       | Specification                                    |
|-----------------|--------------------------------------------------|
| Purpose         | Expose source data from S3 as queryable tables   |
| Storage Format  | Original source format (CSV)                     |
| Table Type      | Athena external table                            |
| Materialization | `external`                                       |
| Transformations | None - read-only, immutable                      |

**Responsibilities:**
- Define external table schema pointing to S3 locations
- Preserve raw data exactly as received from source
- No filters, joins, or calculations allowed

### Staging Layer (`stg`)

| Attribute       | Specification                                    |
|-----------------|--------------------------------------------------|
| Purpose         | Clean, rename, and type-cast raw data            |
| Storage Format  | N/A (view)                                       |
| Table Type      | View                                             |
| Materialization | `view`                                           |
| Transformations | Column renaming, type casting, NULL handling     |

**Responsibilities:**
- 1:1 mapping with raw tables
- Standardize column names to `snake_case`
- Cast columns to appropriate data types
- Handle NULL values and deduplication

**Forbidden:** Joins, aggregations, business logic, calculated fields

### Standardized Layer (`std`)

| Attribute       | Specification                                    |
|-----------------|--------------------------------------------------|
| Purpose         | Apply business logic and create entity models    |
| Storage Format  | Parquet (via Iceberg)                            |
| Table Type      | Iceberg table                                    |
| Materialization | `table`                                          |
| Transformations | Joins, business rules, derived columns           |

**Responsibilities:**
- Create dimension tables (e.g., `mdw_std_dim_customers`)
- Apply business calculations and enrichment
- Implement surrogate keys and SCD logic
- Join staging tables to denormalize data

**Forbidden:** Aggregations, metrics, report-specific transformations

### Curated Layer (`cur`)

| Attribute       | Specification                                    |
|-----------------|--------------------------------------------------|
| Purpose         | Provide analytics-ready datasets                 |
| Storage Format  | Parquet (via Iceberg)                            |
| Table Type      | Iceberg table (partitioned)                      |
| Materialization | `table` or `incremental`                         |
| Transformations | Aggregations, metrics, window functions          |

**Responsibilities:**
- Create fact tables (e.g., `mdw_cur_ft_sales`)
- Calculate KPIs and business metrics
- Partition data for query performance
- Provide final datasets for BI and analytics

**Forbidden:** Raw source references, business logic changes

---

## Naming Conventions

All models follow a strict naming pattern:

```
mdw_<layer>_<table_name>
```

### Model Naming Rules

| Table Type | Layer | Naming Pattern              | Example                 |
|------------|-------|-----------------------------|-------------------------|
| Raw        | raw   | `mdw_raw_<entity>`          | `mdw_raw_sales`         |
| Staging    | stg   | `mdw_stg_<entity>`          | `mdw_stg_sales`         |
| Dimension  | std   | `mdw_std_dim_<entity>`      | `mdw_std_dim_customers` |
| Fact       | cur   | `mdw_cur_ft_<entity>`       | `mdw_cur_ft_sales`      |
| Aggregate  | cur   | `mdw_cur_<metric>`          | `mdw_cur_daily_revenue` |

### Column Naming Rules

- All column names MUST use `snake_case`
- Primary keys: `<entity>_id` (e.g., `customer_id`)
- Foreign keys: `<referenced_entity>_id` (e.g., `product_id`)
- Timestamps: `<action>_at` (e.g., `sales_at`, `created_at`)
- Dates: `<action>_date` (e.g., `sales_date`)
- Partition column: always named `partition`

---

## Partitioning Strategy

Partitioning is required for curated layer tables to optimize query performance and reduce costs.

### Partition Column Requirements

| Requirement        | Specification                                    |
|--------------------|--------------------------------------------------|
| Column name        | Must be exactly `partition`                      |
| Value format       | `YYYYMMDD` (e.g., `20240115`)                    |
| Source             | Derived from a date/timestamp column             |
| Position           | Must be the last column in SELECT                |
| Partitioning style | Hive-style partitioning in S3                    |

### Partition Generation

```sql
-- Generate partition value from timestamp
date_format(sales_at, '%Y%m%d') as partition
```

### When to Partition

| Scenario                    | Recommendation      |
|-----------------------------|---------------------|
| Fact tables (> 1GB)         | Always partition    |
| High-volume transactional   | Daily partition     |
| Medium-volume reporting     | Monthly partition   |
| Small dimension tables      | No partition needed |

### Partitioning Limits

- Avoid more than 10,000 partitions per table
- Target 100MB-1GB of data per partition
- Use coarser granularity for smaller datasets

---

## dbt Project Structure

```
dbt/
├── dbt_project.yml          # Project configuration
├── packages.yml             # Package dependencies
├── profiles.yml             # Connection profiles (local only)
├── models/
│   ├── raw/
│   │   └── schema.yml       # Source definitions for external tables
│   ├── stg/
│   │   ├── mdw_stg_sales.sql
│   │   ├── mdw_stg_customers.sql
│   │   ├── mdw_stg_products.sql
│   │   ├── mdw_stg_categories.sql
│   │   ├── mdw_stg_employees.sql
│   │   ├── mdw_stg_cities.sql
│   │   ├── mdw_stg_countries.sql
│   │   └── schema.yml
│   ├── std/
│   │   ├── mdw_std_dim_customers.sql
│   │   ├── mdw_std_dim_products.sql
│   │   ├── mdw_std_dim_employees.sql
│   │   └── schema.yml
│   └── cur/
│       ├── mdw_cur_ft_sales.sql
│       └── schema.yml
├── macros/
│   ├── generate_partition.sql
│   └── generate_surrogate_key.sql
├── seeds/
├── snapshots/
└── tests/
```

### Key Files

| File                | Purpose                                          |
|---------------------|--------------------------------------------------|
| `dbt_project.yml`   | Project name, version, and model configurations  |
| `packages.yml`      | External package dependencies (dbt-utils, etc.)  |
| `schema.yml`        | Model documentation, tests, and source definitions |

---

## How to Run dbt Models

### Prerequisites

1. Python 3.9+ installed
2. AWS credentials configured (`~/.aws/credentials` or environment variables)
3. S3 bucket with raw data uploaded
4. Athena workgroup configured

### Installation

```bash
# Create virtual environment
python -m venv .venv
source .venv/bin/activate  # Linux/Mac
.venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

### Configure dbt Profile

Create or update `~/.dbt/profiles.yml`:

```yaml
modern_data_warehouse:
  target: dev
  outputs:
    dev:
      type: athena
      s3_staging_dir: s3://<your-bucket>/athena-results/
      region_name: <aws-region>
      database: mdw_raw
      schema: stg
      work_group: primary
```

### Run dbt Commands

```bash
# Navigate to dbt project
cd dbt/

# Install packages
dbt deps

# Test connection
dbt debug

# Run all models
dbt run

# Run specific layer
dbt run --select stg.*
dbt run --select std.*
dbt run --select cur.*

# Run specific model
dbt run --select mdw_cur_ft_sales

# Run tests
dbt test

# Generate documentation
dbt docs generate
dbt docs serve
```

### Build Order

Models are built in dependency order:

1. **raw** → External tables (already exist in Athena)
2. **stg** → Staging views
3. **std** → Standardized Iceberg tables
4. **cur** → Curated Iceberg tables

---

## Best Practices

### SQL Style

- Use **lowercase** for all SQL keywords
- **One column per line** in SELECT statements
- Use **CTEs** instead of subqueries
- **Indent with 4 spaces**, not tabs
- **Explicit column aliases** using `as`
- **Partition column last** in SELECT statements

### dbt Conventions

- **Always use `{{ ref() }}`** for model references
- **Always use `{{ source() }}`** for raw table references
- **Never use hardcoded table names** in SQL
- **Never use `SELECT *`** in stg, std, or cur layers
- **Always specify `table_type='iceberg'`** for std and cur models

### Athena Cost Optimization

| Practice                     | Impact                                    |
|------------------------------|-------------------------------------------|
| List columns explicitly      | Reduces data scanned                      |
| Filter on partition column   | Enables partition pruning                 |
| Use Parquet + Snappy         | Efficient storage and compression         |
| Avoid `ORDER BY` without `LIMIT` | Prevents full dataset sorting         |
| Target 128MB-256MB files     | Optimal query performance                 |

### Testing Requirements

| Layer | Required Tests                                    |
|-------|---------------------------------------------------|
| stg   | `unique`, `not_null` on primary keys              |
| std   | `unique`, `not_null`, `relationships`             |
| cur   | `not_null` on key metrics, `accepted_values`      |

---

## Notes and Limitations

### Scope

- This project covers **ELT transformations only**
- Ingestion, orchestration, and CI/CD are out of scope
- No Delta or Hudi support - Iceberg only

### Athena Limitations

- External tables read all columns as `STRING` with OpenCSVSerDe
- Type casting must be done in the staging layer
- Iceberg tables require explicit `table_type='iceberg'` configuration

### Data Assumptions

- Source data is in CSV format with headers
- Date format: `yyyy-MM-dd HH:mm:ss.SSS`
- All foreign key relationships are valid (referential integrity assumed)

### File Organization

| Directory          | Purpose                                      |
|--------------------|----------------------------------------------|
| `dbt/`             | dbt project files                            |
| `scripts/database/`| Athena DDL scripts for raw layer tables      |
| `infra/modules/`   | Terraform modules for AWS infrastructure     |
| `docs/images/`     | Architecture diagrams and ERD                |
| `.github/`         | Copilot instructions and dataset documentation |

---

## References

- [dbt Documentation](https://docs.getdbt.com/)
- [dbt-athena Adapter](https://github.com/dbt-athena/dbt-athena)
- [AWS Athena Documentation](https://docs.aws.amazon.com/athena/)
- [Apache Iceberg](https://iceberg.apache.org/)
- [Lakehouse Architecture](https://www.databricks.com/glossary/medallion-architecture)

---

## License

This project is licensed under the terms specified in the [LICENSE](LICENSE) file.

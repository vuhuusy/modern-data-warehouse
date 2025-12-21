# Tech Stack

This document provides detailed technical specifications for all technologies used in the Modern Data Warehouse project.

---

## Overview

The project implements a **Lakehouse Medallion architecture** using AWS serverless services and open table formats.

```
┌─────────────────────────────────────────────────────────────────┐
│                        Tech Stack                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌─────────────┐    ┌─────────────┐    ┌─────────────┐         │
│   │     dbt     │───▶│   Athena    │───▶│   Iceberg   │         │
│   │ (Transform) │    │  (Query)    │    │  (Tables)   │         │
│   └─────────────┘    └─────────────┘    └─────────────┘         │
│                              │                  │                │
│                              ▼                  ▼                │
│                        ┌─────────────────────────┐              │
│                        │      Amazon S3          │              │
│                        │      (Storage)          │              │
│                        └─────────────────────────┘              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Query Engine: AWS Athena

| Property          | Value                                            |
|-------------------|--------------------------------------------------|
| Service           | AWS Athena                                       |
| Type              | Serverless interactive query service             |
| SQL Dialect       | Trino (formerly PrestoSQL)                       |
| Pricing Model     | Pay-per-query (based on data scanned)            |

### Key Features

- **Serverless** - No infrastructure to provision or manage
- **Federated queries** - Query data across multiple sources
- **Iceberg support** - Native integration with Apache Iceberg tables
- **ACID transactions** - Full transactional support via Iceberg

### Usage in Project

- Executes all dbt transformations
- Queries raw external tables (CSV in S3)
- Manages Iceberg tables in std and cur layers
- Supports incremental model updates

---

## Storage Layer: Amazon S3

| Property          | Value                                            |
|-------------------|--------------------------------------------------|
| Service           | Amazon S3                                        |
| Type              | Object storage                                   |
| Durability        | 99.999999999% (11 9's)                           |
| Availability      | 99.99%                                           |

### Storage Organization

```
s3://<bucket>/
├── raw/                    # Source data (CSV files)
│   ├── categories/
│   ├── cities/
│   ├── countries/
│   ├── customers/
│   ├── employees/
│   ├── products/
│   └── sales/
├── stg/                    # Staging layer (views - no physical storage)
├── std/                    # Standardized layer (Iceberg tables)
│   └── <table>/
│       ├── data/           # Parquet files
│       └── metadata/       # Iceberg metadata
├── cur/                    # Curated layer (Iceberg tables, partitioned)
│   └── <table>/
│       ├── data/
│       │   └── partition=YYYYMMDD/
│       └── metadata/
└── athena-results/         # Query results staging
```

### File Formats by Layer

| Layer | Format  | Compression | Notes                          |
|-------|---------|-------------|--------------------------------|
| raw   | CSV     | None        | Original source format         |
| stg   | N/A     | N/A         | Views (no physical storage)    |
| std   | Parquet | Snappy      | Iceberg-managed                |
| cur   | Parquet | Snappy      | Iceberg-managed, partitioned   |

---

## Table Format: Apache Iceberg

| Property          | Value                                            |
|-------------------|--------------------------------------------------|
| Format            | Apache Iceberg                                   |
| File Format       | Parquet                                          |
| Compression       | Snappy                                           |
| Catalog           | AWS Glue Data Catalog                            |

### Key Features

- **ACID transactions** - Serializable isolation for concurrent writes
- **Schema evolution** - Add, drop, rename columns without rewriting data
- **Time travel** - Query historical snapshots of data
- **Partition evolution** - Change partitioning without data migration
- **Hidden partitioning** - Partition pruning without exposing partition columns

### Iceberg Configuration in dbt

```yaml
# dbt model config for Iceberg tables
config(
    materialized='table',
    table_type='iceberg',
    format='parquet',
    write_compression='snappy',
    partitioned_by=['partition']  # For cur layer
)
```

### File Size Optimization

| Target              | Value                                          |
|---------------------|------------------------------------------------|
| Optimal file size   | 128MB - 256MB                                  |
| Max partitions      | < 10,000 per table                             |
| Compaction          | Iceberg auto-compaction enabled                |

---

## Transformation: dbt

| Property          | Value                                            |
|-------------------|--------------------------------------------------|
| Tool              | dbt (data build tool)                            |
| Version           | dbt-core 1.10.x                                  |
| Adapter           | dbt-athena 1.9.x                                 |
| Package Manager   | pip                                              |

### dbt Packages

| Package            | Purpose                                         |
|--------------------|-------------------------------------------------|
| dbt-utils          | Common utility macros                           |
| dbt-expectations   | Data quality testing (Great Expectations style) |

### Materialization by Layer

| Layer | Materialization | Table Type      | Partitioned |
|-------|-----------------|-----------------|-------------|
| raw   | external        | External table  | Optional    |
| stg   | view            | View            | N/A         |
| std   | table           | Iceberg         | Optional    |
| cur   | table/incremental | Iceberg       | Required    |

### dbt Project Structure

```
dbt/
├── dbt_project.yml      # Project configuration
├── packages.yml         # Package dependencies
├── models/
│   ├── raw/             # Source definitions
│   ├── stg/             # Staging views
│   ├── std/             # Standardized Iceberg tables
│   └── cur/             # Curated Iceberg tables
├── macros/              # Reusable SQL macros
├── tests/               # Custom data tests
└── seeds/               # Static reference data
```

---

## Architecture: Lakehouse Medallion

The project follows the **Medallion architecture** (also known as multi-hop architecture) with four layers.

### Layer Specifications

| Layer | Purpose                              | Storage        | Mutability  |
|-------|--------------------------------------|----------------|-------------|
| raw   | Ingest source data as-is             | S3 (CSV)       | Immutable   |
| stg   | Clean and standardize                | View           | N/A         |
| std   | Apply business logic, create dims    | Iceberg        | Mutable     |
| cur   | Analytics-ready facts and metrics    | Iceberg        | Mutable     |

### Data Flow

```
Source (CSV) → raw → stg → std → cur → Analytics/BI
                │      │     │     │
                │      │     │     └── Partitioned fact tables
                │      │     └── Dimension tables with business logic
                │      └── Type-cast views (no storage)
                └── External tables pointing to S3
```

### Transformation Rules by Layer

| Layer | Allowed                                    | Forbidden                           |
|-------|--------------------------------------------|-------------------------------------|
| raw   | Schema definition, S3 location             | Any SQL transformation              |
| stg   | Renaming, casting, NULL handling           | Joins, aggregations, business logic |
| std   | Joins, business rules, derived columns     | Aggregations, metrics               |
| cur   | Aggregations, metrics, window functions    | Raw source references               |

---

## Infrastructure: Terraform

| Property          | Value                                            |
|-------------------|--------------------------------------------------|
| Tool              | Terraform                                        |
| Provider          | AWS                                              |
| State Backend     | S3 (recommended)                                 |

### Managed Resources

| Resource              | Purpose                                      |
|-----------------------|----------------------------------------------|
| S3 Bucket             | Data storage for all layers                  |
| Glue Database         | Metadata catalog for Athena tables           |
| Glue Tables           | External table definitions for raw layer     |
| Athena Workgroup      | Query execution configuration                |
| IAM Roles/Policies    | Access control for Athena and S3             |

---

## Version Requirements

| Component         | Minimum Version | Recommended Version |
|-------------------|-----------------|---------------------|
| Python            | 3.9             | 3.11+               |
| dbt-core          | 1.7.0           | 1.10.x              |
| dbt-athena        | 1.7.0           | 1.9.x               |
| Terraform         | 1.0.0           | 1.5+                |
| AWS CLI           | 2.0.0           | 2.x                 |

---

## References

- [AWS Athena Documentation](https://docs.aws.amazon.com/athena/)
- [Apache Iceberg Specification](https://iceberg.apache.org/spec/)
- [dbt Documentation](https://docs.getdbt.com/)
- [dbt-athena Adapter](https://github.com/dbt-athena/dbt-athena)
- [Medallion Architecture](https://www.databricks.com/glossary/medallion-architecture)

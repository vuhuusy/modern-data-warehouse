# Standardized Layer Models

This directory contains standardized models that apply business logic and create entity-centric data models.

## Purpose

- Join staging tables to enrich data
- Apply business rules and calculations
- Create dimension tables for star schema
- Create transactional fact tables (no aggregations)

## Naming Convention

```
mdw_std_dim_<entity>.sql  # For dimension tables
mdw_std_ft_<entity>.sql   # For transactional fact tables
mdw_std_<entity>.sql      # For other standardized models
```

## Materialization

All standardized models are materialized as **Iceberg tables** with:
- Parquet file format
- Snappy compression

## Rules

- ✅ Joins between staging models
- ✅ Business calculations and derived columns
- ✅ Surrogate key generation
- ✅ SCD Type 2 via snapshots (point-in-time dimension joins)
- ✅ Transactional fact tables (denormalized, no aggregations)
- ❌ Aggregations or metrics (use cur layer)
- ❌ Report-specific transformations
- ❌ Direct references to raw sources

## Models

| Model | Type | Description |
|-------|------|-------------|
| `mdw_std_dim_customers` | Dimension | Customer dimension with SCD2 |
| `mdw_std_dim_products` | Dimension | Product dimension with SCD2 |
| `mdw_std_dim_employees` | Dimension | Employee dimension with SCD2 |
| `mdw_std_dim_date` | Dimension | Date dimension (generated) |
| `mdw_std_ft_sales` | Fact | Transactional sales fact table |

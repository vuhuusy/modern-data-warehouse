# Standardized Layer Models

This directory contains standardized models that apply business logic and create entity-centric data models.

## Purpose

- Join staging tables to enrich data
- Apply business rules and calculations
- Create dimension tables for star schema

## Naming Convention

```
mdw_std_dim_<entity>.sql  # For dimension tables
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
- ✅ SCD (Slowly Changing Dimension) logic
- ❌ Aggregations or metrics
- ❌ Report-specific transformations
- ❌ Direct references to raw sources

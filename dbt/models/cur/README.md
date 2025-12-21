# Curated Layer Models

This directory contains curated models that provide analytics-ready datasets.

## Purpose

- Create fact tables with denormalized data
- Calculate KPIs and business metrics
- Aggregate data for reporting and analytics

## Naming Convention

```
mdw_cur_ft_<entity>.sql   # For fact tables
mdw_cur_<metric>.sql      # For aggregate/metric tables
```

## Materialization

All curated models are materialized as **Iceberg tables** with:
- Parquet file format
- Snappy compression
- Partitioning by date (required for fact tables)

## Partitioning

Fact tables MUST include a `partition` column:
- Column name: `partition`
- Format: `YYYYMMDD`
- Position: Last column in SELECT
- Generated using: `date_format(<date_column>, '%Y%m%d')`

## Rules

- ✅ Aggregations and window functions
- ✅ Metrics and KPIs
- ✅ Final joins from std layer
- ✅ Partitioning for large tables
- ❌ Raw source references
- ❌ Business logic changes (should be in std)

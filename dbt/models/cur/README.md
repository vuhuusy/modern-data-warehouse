# Curated Layer Models

This directory contains curated models that provide analytics-ready, aggregated datasets.

## Purpose

- Aggregate transactional data from std layer
- Calculate KPIs and business metrics
- Create pre-aggregated tables for reporting and analytics

## Naming Convention

```
mdw_cur_<metric>.sql      # For aggregate/metric tables
mdw_cur_<dimension>_<granularity>.sql  # For dimensional aggregates
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
- ✅ References to std layer fact tables
- ✅ Partitioning for large tables
- ❌ Raw source references
- ❌ Business logic changes (should be in std)
- ❌ Transactional-level detail (use std layer)

## Models

| Model | Granularity | Description |
|-------|-------------|-------------|
| `mdw_cur_daily_sales` | Daily | Overall daily sales metrics |
| `mdw_cur_product_performance` | Daily × Product | Product-level daily performance |
| `mdw_cur_customer_summary` | Customer | Customer lifetime metrics |
| `mdw_cur_salesperson_performance` | Daily × Salesperson | Salesperson daily metrics |
| `mdw_cur_category_daily_sales` | Daily × Category | Category-level daily metrics |

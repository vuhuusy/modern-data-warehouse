# Staging Layer Models

This directory contains staging models that provide 1:1 mappings with raw source tables.

## Purpose

- Clean, rename, and type-cast raw data
- Standardize column names to `snake_case`
- Handle NULL values and basic data quality

## Naming Convention

```
mdw_stg_<entity>.sql
```

## Materialization

All staging models are materialized as **views**.

## Rules

- ✅ Column renaming and aliasing
- ✅ Type casting (`cast(column as type)`)
- ✅ NULL handling (`coalesce`, `nullif`)
- ✅ Basic deduplication
- ❌ Joins with other tables
- ❌ Aggregations
- ❌ Business logic or calculated fields

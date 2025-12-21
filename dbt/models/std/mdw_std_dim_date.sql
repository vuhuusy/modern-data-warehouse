-- models/std/mdw_std_dim_date.sql
-- Standardized date dimension for time-based analytics
-- Generates a date spine from 2018-01-01 to 2018-12-31
-- Includes handling for missing/unknown dates with a default Unknown record
-- Unknown record (date_key = 1900-01-01) ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with date_spine as (
    select
        sequence(
            date '2018-01-01',
            date '2018-12-31',
            interval '1' day
        ) as date_array
),

dates as (
    select
        date_value
    from date_spine
    cross join unnest(date_array) as t(date_value)
),

-- Unknown record for handling missing/null date references in fact tables
-- Uses 1900-01-01 as deterministic key to ensure stability across runs
unknown_record as (
    select
        date '1900-01-01' as date_key,
        cast('19000101' as varchar) as date_id,
        cast(-1 as bigint) as year,
        cast(-1 as bigint) as quarter,
        cast(-1 as bigint) as month,
        cast(-1 as bigint) as week_of_year,
        cast(-1 as bigint) as day_of_month,
        cast(-1 as bigint) as day_of_week,
        cast(-1 as bigint) as day_of_year,
        cast('Unknown' as varchar) as year_month,
        cast('Unknown' as varchar) as year_quarter,
        cast('Unknown' as varchar) as month_name,
        cast('Unknown' as varchar) as month_name_short,
        cast('Unknown' as varchar) as day_name,
        cast('Unknown' as varchar) as day_name_short,
        cast(null as boolean) as is_weekend,
        cast(null as date) as first_day_of_month,
        cast(null as date) as last_day_of_month,
        cast(null as date) as first_day_of_quarter,
        cast(null as date) as first_day_of_year
),

enriched as (
    select
        date(date_value) as date_key,
        date_format(date_value, '%Y%m%d') as date_id,
        year(date_value) as year,
        quarter(date_value) as quarter,
        month(date_value) as month,
        week(date_value) as week_of_year,
        day_of_month(date_value) as day_of_month,
        day_of_week(date_value) as day_of_week,
        day_of_year(date_value) as day_of_year,
        date_format(date_value, '%Y-%m') as year_month,
        date_format(date_value, '%Y-Q') || cast(quarter(date_value) as varchar) as year_quarter,
        date_format(date_value, '%M') as month_name,
        date_format(date_value, '%b') as month_name_short,
        date_format(date_value, '%W') as day_name,
        date_format(date_value, '%a') as day_name_short,
        case when day_of_week(date_value) in (6, 7) then true else false end as is_weekend,
        date(date_trunc('month', date_value)) as first_day_of_month,
        date(last_day_of_month(date_value)) as last_day_of_month,
        date(date_trunc('quarter', date_value)) as first_day_of_quarter,
        date(date_trunc('year', date_value)) as first_day_of_year
    from dates
),

-- Combine unknown record with enriched data
final as (
    select * from unknown_record
    union all
    select * from enriched
)

select
    date_key,
    date_id,
    year,
    quarter,
    month,
    week_of_year,
    day_of_month,
    day_of_week,
    day_of_year,
    year_month,
    year_quarter,
    month_name,
    month_name_short,
    day_name,
    day_name_short,
    is_weekend,
    first_day_of_month,
    last_day_of_month,
    first_day_of_quarter,
    first_day_of_year
from final

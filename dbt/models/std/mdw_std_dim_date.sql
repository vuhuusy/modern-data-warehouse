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
            date '2010-01-01',
            date '2030-12-31',
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
        cast('DATE000000' as varchar) as date_key,
        cast('NA' as varchar) as year,
        cast('NA' as varchar) as quarter,
        cast('NA' as varchar) as month,
        cast('NA' as varchar) as week_of_year,
        cast('NA' as varchar) as day_of_month,
        cast('NA' as varchar) as day_of_week,
        cast('NA' as varchar) as day_of_year,
        cast('NA' as varchar) as year_month,
        cast('NA' as varchar) as year_quarter,
        cast('NA' as varchar) as month_name,
        cast('NA' as varchar) as month_name_short,
        cast('NA' as varchar) as day_name,
        cast('NA' as varchar) as day_name_short,
        cast('NA' as varchar) as day_type,
        cast('NA' as varchar) as first_day_of_month,
        cast('NA' as varchar) as last_day_of_month,
        cast('NA' as varchar) as first_day_of_quarter,
        cast('NA' as varchar) as first_day_of_year
),

enriched as (
    select
        cast(date_format(date_value, '%Y%m%d') as varchar) as date_key,
        cast(year(date_value) as varchar) as year,
        cast(quarter(date_value) as varchar) as quarter,
        cast(month(date_value) as varchar) as month,
        cast(week(date_value) as varchar) as week_of_year,
        cast(day_of_month(date_value) as varchar) as day_of_month,
        cast(day_of_week(date_value) as varchar) as day_of_week,
        cast(day_of_year(date_value) as varchar) as day_of_year,
        cast(date_format(date_value, '%Y-%m') as varchar) as year_month,
        cast(date_format(date_value, '%Y-Q') || cast(quarter(date_value) as varchar) as varchar) as year_quarter,
        cast(date_format(date_value, '%M') as varchar) as month_name,
        cast(date_format(date_value, '%b') as varchar) as month_name_short,
        cast(date_format(date_value, '%W') as varchar) as day_name,
        cast(date_format(date_value, '%a') as varchar) as day_name_short,
        cast(case when day_of_week(date_value) in (6, 7) then 'Weekend' else 'Weekday' end as varchar) as day_type,
        cast(date_format(date_trunc('month', date_value), '%Y%m%d') as varchar) as first_day_of_month,
        cast(date_format(last_day_of_month(date_value), '%Y%m%d') as varchar) as last_day_of_month,
        cast(date_format(date_trunc('quarter', date_value), '%Y%m%d') as varchar) as first_day_of_quarter,
        cast(date_format(date_trunc('year', date_value), '%Y%m%d') as varchar) as first_day_of_year
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
    day_type,
    first_day_of_month,
    last_day_of_month,
    first_day_of_quarter,
    first_day_of_year
from final

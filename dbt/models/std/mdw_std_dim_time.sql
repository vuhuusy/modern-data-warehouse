-- models/std/mdw_std_dim_time.sql
-- Standardized time dimension for intraday analytics
-- Generates all minutes in a day (1,440 rows) for granular time analysis
-- Unknown record (time_key = TIME '00:00:00') ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with time_spine as (
    select
        sequence(0, 1439) as minute_array  -- 0 to 1439 minutes in a day
),

minutes as (
    select
        minute_value
    from time_spine
    cross join unnest(minute_array) as t(minute_value)
),

-- Unknown record for handling missing/null time references in fact tables
unknown_record as (
    select
        cast('00:00:00' as time) as time_key,
        cast('NA' as varchar) as hour_24,
        cast('NA' as varchar) as hour_12,
        cast('NA' as varchar) as minute,
        cast('NA' as varchar) as am_pm,
        cast('NA' as varchar) as time_of_day,
        cast('NA' as varchar) as hour_band,
        cast('NA' as varchar) as business_hour,
        cast('NA' as varchar) as display_24,
        cast('NA' as varchar) as display_12,
        current_timestamp as dbt_run_at
),

enriched as (
    select
        -- Time key in HH:MM:SS format
        cast(
            lpad(cast(minute_value / 60 as varchar), 2, '0') || ':' ||
            lpad(cast(minute_value % 60 as varchar), 2, '0') || ':00'
            as time
        ) as time_key,

        -- Hour attributes
        cast(minute_value / 60 as varchar) as hour_24,
        cast(case
            when minute_value / 60 = 0 then 12
            when minute_value / 60 > 12 then minute_value / 60 - 12
            else minute_value / 60
        end as varchar) as hour_12,

        -- Minute attribute
        cast(minute_value % 60 as varchar) as minute,

        -- AM/PM indicator
        cast(case when minute_value / 60 < 12 then 'AM' else 'PM' end as varchar) as am_pm,

        -- Time of day classification
        cast(case
            when minute_value / 60 >= 5 and minute_value / 60 < 12 then 'Morning'
            when minute_value / 60 >= 12 and minute_value / 60 < 17 then 'Afternoon'
            when minute_value / 60 >= 17 and minute_value / 60 < 21 then 'Evening'
            else 'Night'
        end as varchar) as time_of_day,

        -- Hour band for grouping
        cast(case
            when minute_value / 60 >= 0 and minute_value / 60 < 6 then '00:00-05:59'
            when minute_value / 60 >= 6 and minute_value / 60 < 12 then '06:00-11:59'
            when minute_value / 60 >= 12 and minute_value / 60 < 18 then '12:00-17:59'
            else '18:00-23:59'
        end as varchar) as hour_band,

        -- Business hours flag (9 AM - 6 PM)
        cast(case when minute_value / 60 >= 9 and minute_value / 60 < 18 then 'Business Hour' else 'Non-Business Hour' end as varchar) as business_hour,

        -- Display formats
        cast(lpad(cast(minute_value / 60 as varchar), 2, '0') || ':' ||
        lpad(cast(minute_value % 60 as varchar), 2, '0') as varchar) as display_24,

        cast(lpad(cast(case
            when minute_value / 60 = 0 then 12
            when minute_value / 60 > 12 then minute_value / 60 - 12
            else minute_value / 60
        end as varchar), 2, '0') || ':' ||
        lpad(cast(minute_value % 60 as varchar), 2, '0') || ' ' ||
        case when minute_value / 60 < 12 then 'AM' else 'PM' end as varchar) as display_12,

        -- Technical columns
        current_timestamp as dbt_run_at

    from minutes
)

select * from unknown_record
union all
select * from enriched

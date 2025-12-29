-- models/std/mdw_std_dim_time.sql
-- Standardized time dimension for intraday analytics
-- Generates all minutes in a day (1,440 rows) for granular time analysis
-- Unknown record (time_key = '99:99:99') ensures fact tables always have valid joins

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
        cast('99:99:99' as varchar) as time_key,
        cast(null as bigint) as hour_24,
        cast(null as bigint) as hour_12,
        cast(null as bigint) as minute,
        cast('Unknown' as varchar) as am_pm,
        cast('Unknown' as varchar) as time_of_day,
        cast('Unknown' as varchar) as hour_band,
        cast(null as boolean) as is_business_hour,
        cast('Unknown' as varchar) as time_display_24,
        cast('Unknown' as varchar) as time_display_12
),

enriched as (
    select
        -- Time key in HH:MM:SS format
        lpad(cast(minute_value / 60 as varchar), 2, '0') || ':' ||
        lpad(cast(minute_value % 60 as varchar), 2, '0') || ':00' as time_key,

        -- Hour attributes
        cast(minute_value / 60 as bigint) as hour_24,
        cast(case
            when minute_value / 60 = 0 then 12
            when minute_value / 60 > 12 then minute_value / 60 - 12
            else minute_value / 60
        end as bigint) as hour_12,

        -- Minute attribute
        cast(minute_value % 60 as bigint) as minute,

        -- AM/PM indicator
        case when minute_value / 60 < 12 then 'AM' else 'PM' end as am_pm,

        -- Time of day classification
        case
            when minute_value / 60 >= 5 and minute_value / 60 < 12 then 'Morning'
            when minute_value / 60 >= 12 and minute_value / 60 < 17 then 'Afternoon'
            when minute_value / 60 >= 17 and minute_value / 60 < 21 then 'Evening'
            else 'Night'
        end as time_of_day,

        -- Hour band for grouping
        case
            when minute_value / 60 >= 0 and minute_value / 60 < 6 then '00:00-05:59'
            when minute_value / 60 >= 6 and minute_value / 60 < 12 then '06:00-11:59'
            when minute_value / 60 >= 12 and minute_value / 60 < 18 then '12:00-17:59'
            else '18:00-23:59'
        end as hour_band,

        -- Business hours flag (9 AM - 6 PM)
        case when minute_value / 60 >= 9 and minute_value / 60 < 18 then true else false end as is_business_hour,

        -- Display formats
        lpad(cast(minute_value / 60 as varchar), 2, '0') || ':' ||
        lpad(cast(minute_value % 60 as varchar), 2, '0') as time_display_24,

        lpad(cast(case
            when minute_value / 60 = 0 then 12
            when minute_value / 60 > 12 then minute_value / 60 - 12
            else minute_value / 60
        end as varchar), 2, '0') || ':' ||
        lpad(cast(minute_value % 60 as varchar), 2, '0') || ' ' ||
        case when minute_value / 60 < 12 then 'AM' else 'PM' end as time_display_12

    from minutes
)

select * from unknown_record
union all
select * from enriched

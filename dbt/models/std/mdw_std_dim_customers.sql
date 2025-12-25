-- models/std/mdw_std_dim_customers.sql
-- Standardized customer dimension with geographic enrichment
-- Includes handling for missing/Unknown values with a default Unknown record
-- Unknown record (customer_id = 0) ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with customers as (
    select
        customer_id,
        first_name,
        middle_initial,
        last_name,
        city_id,
        address
    from {{ ref('mdw_stg_customers') }}
),

cities as (
    select
        city_id,
        city_name,
        zipcode,
        country_id
    from {{ ref('mdw_stg_cities') }}
),

countries as (
    select
        country_id,
        country_name,
        country_code
    from {{ ref('mdw_stg_countries') }}
),

-- Unknown record for handling missing/null customer references in fact tables
-- Uses 0 as deterministic surrogate key to ensure stability across runs
unknown_record as (
    select
        cast('0' as varchar) as customer_sk,
        cast('0' as varchar) as customer_id,
        cast('Unknown' as varchar) as first_name,
        cast('Unknown' as varchar) as middle_initial,
        cast('Unknown' as varchar) as last_name,
        cast('Unknown' as varchar) as full_name,
        cast('Unknown' as varchar) as address,
        cast('0' as varchar) as city_id,
        cast('Unknown' as varchar) as city_name,
        cast('Unknown' as varchar) as zipcode,
        cast('0' as varchar) as country_id,
        cast('Unknown' as varchar) as country_name,
        cast('Unknown' as varchar) as country_code
),

enriched as (
    select
        {{ generate_surrogate_key(["'mdw'", 'cu.customer_id']) }} as customer_sk,
        cu.customer_id,
        coalesce(cu.first_name, 'Unknown') as first_name,
        coalesce(cu.middle_initial, 'Unknown') as middle_initial,
        coalesce(cu.last_name, 'Unknown') as last_name,
        coalesce(
            cu.first_name, 'Unknown'
        ) || ' ' || coalesce(
            cu.last_name, 'Unknown'
        ) as full_name,
        coalesce(cu.address, 'Unknown') as address,
        coalesce(cu.city_id, cast('0' as varchar)) as city_id,
        coalesce(ci.city_name, 'Unknown') as city_name,
        coalesce(ci.zipcode, 'Unknown') as zipcode,
        coalesce(ci.country_id, cast('0' as varchar)) as country_id,
        coalesce(co.country_name, 'Unknown') as country_name,
        coalesce(co.country_code, 'Unknown') as country_code
    from customers cu
    left join cities ci on cu.city_id = ci.city_id
    left join countries co on ci.country_id = co.country_id
),

-- Combine Unknown record with enriched data
final as (
    select * from unknown_record
    union all
    select * from enriched
)

select
    customer_sk,
    customer_id,
    first_name,
    middle_initial,
    last_name,
    full_name,
    address,
    city_id,
    city_name,
    zipcode,
    country_id,
    country_name,
    country_code
from final

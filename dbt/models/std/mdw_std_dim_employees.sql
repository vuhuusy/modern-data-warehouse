-- models/std/mdw_std_dim_employees.sql
-- Standardized employee dimension with geographic enrichment
-- Includes handling for missing/Unknown values with a default Unknown record
-- Unknown record (employee_id = -1) ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with employees as (
    select
        employee_id,
        first_name,
        middle_initial,
        last_name,
        birth_date,
        gender,
        city_id,
        hire_date
    from {{ ref('mdw_stg_employees') }}
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

-- Unknown record for handling missing/null employee references in fact tables
-- Uses -1 as deterministic surrogate key to ensure stability across runs
unknown_record as (
    select
        cast('0' as varchar) as employee_sk,
        cast('0' as varchar) as employee_id,
        cast('Unknown' as varchar) as first_name,
        cast('Unknown' as varchar) as middle_initial,
        cast('Unknown' as varchar) as last_name,
        cast('Unknown' as varchar) as full_name,
        cast(null as date) as birth_date,
        cast('Unknown' as varchar) as gender,
        cast(null as date) as hire_date,
        cast('0' as varchar) as city_id,
        cast('Unknown' as varchar) as city_name,
        cast('Unknown' as varchar) as zipcode,
        cast('0' as varchar) as country_id,
        cast('Unknown' as varchar) as country_name,
        cast('Unknown' as varchar) as country_code
),

enriched as (
    select
        {{ generate_surrogate_key(["'mdw'", 'em.employee_id']) }} as employee_sk,
        em.employee_id,
        coalesce(em.first_name, 'Unknown') as first_name,
        coalesce(em.middle_initial, 'Unknown') as middle_initial,
        coalesce(em.last_name, 'Unknown') as last_name,
        coalesce(
            em.first_name, 'Unknown'
        ) || ' ' || coalesce(
            em.last_name, 'Unknown'
        ) as full_name,
        em.birth_date,
        coalesce(em.gender, 'Unknown') as gender,
        em.hire_date,
        coalesce(em.city_id, cast('0' as varchar)) as city_id,
        coalesce(ci.city_name, 'Unknown') as city_name,
        coalesce(ci.zipcode, 'Unknown') as zipcode,
        coalesce(ci.country_id, cast('0' as varchar)) as country_id,
        coalesce(co.country_name, 'Unknown') as country_name,
        coalesce(co.country_code, 'Unknown') as country_code
    from employees em
    left join cities ci on em.city_id = ci.city_id
    left join countries co on ci.country_id = co.country_id
),

-- Combine Unknown record with enriched data
final as (
    select * from unknown_record
    union all
    select * from enriched
)

select
    employee_sk,
    employee_id,
    first_name,
    middle_initial,
    last_name,
    full_name,
    birth_date,
    gender,
    hire_date,
    city_id,
    city_name,
    zipcode,
    country_id,
    country_name,
    country_code
from final

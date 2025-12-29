-- models/std/mdw_std_dim_employees.sql
-- Standardized employee dimension with SCD Type 2 support
-- Sources from snapshot table to preserve historical changes
-- Unknown record (employee_sk = 0) ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

-- Unknown record for handling missing/null employee references in fact tables
-- Uses 0 as deterministic surrogate key to ensure stability across runs
with unknown_record as (
    select
        cast('SK_EMP000000' as varchar) as employee_sk,
        cast('EMP000000' as varchar) as employee_id,
        cast('Unknown' as varchar) as first_name,
        cast('Unknown' as varchar) as middle_initial,
        cast('Unknown' as varchar) as last_name,
        cast('Unknown' as varchar) as full_name,
        cast(null as date) as birth_date,
        cast(null as integer) as age,
        cast('Unknown' as varchar) as gender,
        cast(null as date) as hire_date,
        cast('CITY000000' as varchar) as city_id,
        cast('Unknown' as varchar) as city_name,
        cast('Unknown' as varchar) as zipcode,
        cast('COUNTRY000000' as varchar) as country_id,
        cast('Unknown' as varchar) as country_name,
        cast('Unknown' as varchar) as country_code,
        cast('1900-01-01' as timestamp) as valid_from,
        cast('9999-12-31' as timestamp) as valid_to,
        cast(true as boolean) as is_current
),

-- Source from snapshot table with SCD Type 2 metadata
snapshot_data as (
    select
        employee_id,
        first_name,
        middle_initial,
        last_name,
        full_name,
        birth_date,
        age,
        gender,
        hire_date,
        city_id,
        city_name,
        zipcode,
        country_id,
        country_name,
        country_code,
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        case when dbt_valid_to is null then true else false end as is_current
    from {{ ref('snp_dim_employees') }}
),

-- Generate surrogate key including validity period for SCD2
enriched as (
    select
        {{ dbt_utils.generate_surrogate_key(["'mdw'", 'employee_id', 'valid_from']) }} as employee_sk,
        employee_id,
        first_name,
        middle_initial,
        last_name,
        full_name,
        birth_date,
        age,
        gender,
        hire_date,
        city_id,
        city_name,
        zipcode,
        country_id,
        country_name,
        country_code,
        valid_from,
        valid_to,
        is_current
    from snapshot_data
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
    age,
    gender,
    hire_date,
    city_id,
    city_name,
    zipcode,
    country_id,
    country_name,
    country_code,
    valid_from,
    valid_to,
    is_current
from final

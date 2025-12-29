-- models/std/mdw_std_dim_products.sql
-- Standardized product dimension with SCD Type 2 support
-- Sources from snapshot table to preserve historical changes
-- Unknown record (product_sk = 0) ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

-- Unknown record for handling missing/null product references in fact tables
-- Uses 0 as deterministic surrogate key to ensure stability across runs
with unknown_record as (
    select
        cast('SK_PROD000000' as varchar) as product_sk,
        cast('PROD000000' as varchar) as product_id,
        cast('Unknown' as varchar) as product_name,
        cast(null as decimal(10,2)) as price,
        cast('CAT000000' as varchar) as category_id,
        cast('Unknown' as varchar) as category_name,
        cast('Unknown' as varchar) as class,
        cast(null as date) as modify_date,
        cast('Unknown' as varchar) as resistant,
        cast('Unknown' as varchar) as allergic_type,
        cast(null as int) as vitality_days,
        cast('1900-01-01' as timestamp) as valid_from,
        cast('9999-12-31' as timestamp) as valid_to,
        cast(true as boolean) as is_current
),

-- Source from snapshot table with SCD Type 2 metadata
snapshot_data as (
    select
        product_id,
        product_name,
        price,
        category_id,
        category_name,
        class,
        modify_date,
        resistant,
        case 
            when upper(is_allergic) = 'TRUE' then 'Allergic'
            when upper(is_allergic) = 'FALSE' then 'Non-Allergic'
            else 'Unknown'
        end as allergic_type,
        vitality_days,
        dbt_valid_from as valid_from,
        dbt_valid_to as valid_to,
        case when dbt_valid_to is null then true else false end as is_current
    from {{ ref('snp_dim_products') }}
),

-- Generate surrogate key including validity period for SCD2
enriched as (
    select
        {{ dbt_utils.generate_surrogate_key(["'mdw'", 'product_id', 'valid_from']) }} as product_sk,
        product_id,
        product_name,
        price,
        category_id,
        category_name,
        class,
        modify_date,
        resistant,
        allergic_type,
        vitality_days,
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
    product_sk,
    product_id,
    product_name,
    price,
    category_id,
    category_name,
    class,
    modify_date,
    resistant,
    allergic_type,
    vitality_days,
    valid_from,
    valid_to,
    is_current
from final

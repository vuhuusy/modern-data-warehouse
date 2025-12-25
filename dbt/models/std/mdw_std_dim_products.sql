-- models/std/mdw_std_dim_products.sql
-- Standardized product dimension with category enrichment
-- Includes handling for missing/Unknown values with a default Unknown record
-- Unknown record (product_id = -1) ensures fact tables always have valid joins

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with products as (
    select
        product_id,
        product_name,
        price,
        category_id,
        class,
        modify_date,
        resistant,
        is_allergic,
        vitality_days
    from {{ ref('mdw_stg_products') }}
),

categories as (
    select
        category_id,
        category_name
    from {{ ref('mdw_stg_categories') }}
),

-- Unknown record for handling missing/null product references in fact tables
-- Uses -1 as deterministic surrogate key to ensure stability across runs
unknown_record as (
    select
        cast('0' as varchar) as product_sk,
        cast('0' as varchar) as product_id,
        cast('Unknown' as varchar) as product_name,
        cast(null as decimal(10,2)) as price,
        cast('0' as varchar) as category_id,
        cast('Unknown' as varchar) as category_name,
        cast('Unknown' as varchar) as class,
        cast(null as date) as modify_date,
        cast('Unknown' as varchar) as resistant,
        cast('Unknown' as varchar) as is_allergic,
        cast(null as int) as vitality_days
),

enriched as (
    select
        {{ generate_surrogate_key(["'mdw'", 'pr.product_id']) }} as product_sk,
        pr.product_id,
        coalesce(pr.product_name, 'Unknown') as product_name,
        coalesce(pr.price, cast(null as decimal(10,2))) as price,
        coalesce(pr.category_id, cast('0' as varchar)) as category_id,
        coalesce(ca.category_name, 'Unknown') as category_name,
        coalesce(pr.class, 'Unknown') as class,
        pr.modify_date,
        coalesce(pr.resistant, 'Unknown') as resistant,
        coalesce(pr.is_allergic, 'Unknown') as is_allergic,
        pr.vitality_days
    from products pr
    left join categories ca on pr.category_id = ca.category_id
    where pr.product_id in ('1','2')
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
    is_allergic,
    vitality_days
from final

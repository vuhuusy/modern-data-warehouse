-- models/stg/mdw_stg_products.sql
-- Staging view for products
-- Cleans and type-casts raw product data

with source as (
    select * from {{ source('grocery', 'products') }}
),

cleaned as (
    select
        cast(nullif(trim(productid), '') as varchar) as product_id,
        nullif(trim(productname), '') as product_name,
        cast(nullif(trim(price), '') as decimal(10,4)) as price,
        cast(nullif(trim(categoryid), '') as varchar) as category_id,
        nullif(trim(class), '') as class,
        cast(cast(nullif(trim(modifydate), '') as timestamp) as date) as modify_date,
        nullif(trim(resistant), '') as resistant,
        nullif(trim(isallergic), '') as is_allergic,
        cast(nullif(trim(vitalitydays), '') as decimal(10,1)) as vitality_days
    from source
)

select * from cleaned

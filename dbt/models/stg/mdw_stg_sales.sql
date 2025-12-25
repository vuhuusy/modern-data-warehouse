-- models/stg/mdw_stg_sales.sql
-- Staging view for sales transactions
-- Cleans and type-casts raw sales data

with source as (
    select * from {{ source('grocery', 'sales') }}
    where partition = '{{ var("partition") }}'
),

cleaned as (
    select
        cast(nullif(trim(salesid), '') as varchar) as sales_id,
        cast(nullif(trim(salespersonid), '') as varchar) as salesperson_id,
        cast(nullif(trim(customerid), '') as varchar) as customer_id,
        cast(nullif(trim(productid), '') as varchar) as product_id,
        cast(nullif(trim(quantity), '') as int) as quantity,
        coalesce(cast(nullif(trim(discount), '') as decimal(10,2)), 0) as discount,
        cast(nullif(trim(totalprice), '') as decimal(10,4)) as total_price,
        cast(nullif(trim(salesdate), '') as timestamp) as sales_at,
        nullif(trim(transactionnumber), '') as transaction_number,
        partition
    from source
)

select * from cleaned

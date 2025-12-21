-- models/stg/mdw_stg_sales.sql
-- Staging view for sales transactions
-- Cleans and type-casts raw sales data

with source as (
    select * from {{ source('grocery', 'sales') }}
),

cleaned as (
    select
        cast(nullif(trim(salesid), '') as bigint) as sales_id,
        cast(nullif(trim(salespersonid), '') as bigint) as salesperson_id,
        cast(nullif(trim(customerid), '') as bigint) as customer_id,
        cast(nullif(trim(productid), '') as bigint) as product_id,
        cast(nullif(trim(quantity), '') as int) as quantity,
        cast(nullif(trim(discount), '') as decimal(10,2)) as discount,
        cast(nullif(trim(totalprice), '') as decimal(10,4)) as total_price,
        cast(nullif(trim(salesdate), '') as timestamp) as sales_at,
        nullif(trim(transactionnumber), '') as transaction_number
    from source
)

select * from cleaned

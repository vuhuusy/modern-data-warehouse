-- models/stg/mdw_stg_sales.sql
-- Staging table for sales transactions
-- Cleans and type-casts raw sales data
-- Incremental with merge for idempotent daily loads

{{
    config(
        materialized='incremental',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        incremental_strategy='merge',
        unique_key='sales_id',
        partitioned_by=['partition'],
        on_schema_change='fail'
    )
}}

with source as (
    select * from {{ source('grocery', 'sales') }}
    {% if is_incremental() %}
    where partition = '{{ var("partition") }}'
    {% endif %}
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

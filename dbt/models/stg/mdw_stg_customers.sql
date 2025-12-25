-- models/stg/mdw_stg_customers.sql
-- Staging view for customers
-- Cleans and type-casts raw customer data

with source as (
    select * from {{ source('grocery', 'customers') }}
),

cleaned as (
    select
        cast(nullif(trim(customerid), '') as varchar) as customer_id,
        nullif(trim(firstname), '') as first_name,
        nullif(trim(middleinitial), '') as middle_initial,
        nullif(trim(lastname), '') as last_name,
        cast(nullif(trim(cityid), '') as varchar) as city_id,
        nullif(trim(address), '') as address
    from source
)

select * from cleaned

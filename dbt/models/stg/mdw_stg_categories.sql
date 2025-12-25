-- models/stg/mdw_stg_categories.sql
-- Staging view for product categories
-- Cleans and type-casts raw category data

with source as (
    select * from {{ source('grocery', 'categories') }}
),

cleaned as (
    select
        cast(nullif(trim(categoryid), '') as varchar) as category_id,
        nullif(trim(categoryname), '') as category_name
    from source
)

select * from cleaned

-- models/stg/mdw_stg_countries.sql
-- Staging view for countries
-- Cleans and type-casts raw country data

with source as (
    select * from {{ source('grocery', 'countries') }}
),

cleaned as (
    select
        cast(nullif(trim(countryid), '') as varchar) as country_id,
        nullif(trim(countryname), '') as country_name,
        nullif(trim(countrycode), '') as country_code
    from source
)

select * from cleaned

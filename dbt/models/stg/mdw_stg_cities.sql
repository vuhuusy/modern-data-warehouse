-- models/stg/mdw_stg_cities.sql
-- Staging view for cities
-- Cleans and type-casts raw city data

with source as (
    select * from {{ source('grocery', 'cities') }}
),

cleaned as (
    select
        cast(nullif(trim(cityid), '') as bigint) as city_id,
        nullif(trim(cityname), '') as city_name,
        nullif(trim(zipcode), '') as zipcode,
        cast(nullif(trim(countryid), '') as bigint) as country_id
    from source
)

select * from cleaned

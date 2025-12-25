-- snapshots/snp_dim_customers.sql
-- SCD Type 2 snapshot for customer dimension
-- Tracks historical changes to customer attributes over time

{% snapshot snp_dim_customers %}

{{
    config(
        target_schema='mdw_snp',
        unique_key='customer_id',
        strategy='check',
        check_cols=['first_name', 'middle_initial', 'last_name', 'address', 'city_id', 'city_name', 'zipcode', 'country_id', 'country_name', 'country_code'],
        invalidate_hard_deletes=True
    )
}}

with customers as (
    select
        customer_id,
        first_name,
        middle_initial,
        last_name,
        city_id,
        address
    from {{ ref('mdw_stg_customers') }}
),

cities as (
    select
        city_id,
        city_name,
        zipcode,
        country_id
    from {{ ref('mdw_stg_cities') }}
),

countries as (
    select
        country_id,
        country_name,
        country_code
    from {{ ref('mdw_stg_countries') }}
),

enriched as (
    select
        cu.customer_id,
        coalesce(cu.first_name, 'Unknown') as first_name,
        coalesce(cu.middle_initial, 'Unknown') as middle_initial,
        coalesce(cu.last_name, 'Unknown') as last_name,
        coalesce(
            cu.first_name, 'Unknown'
        ) || ' ' || coalesce(
            cu.last_name, 'Unknown'
        ) as full_name,
        coalesce(cu.address, 'Unknown') as address,
        coalesce(cu.city_id, cast('0' as varchar)) as city_id,
        coalesce(ci.city_name, 'Unknown') as city_name,
        coalesce(ci.zipcode, 'Unknown') as zipcode,
        coalesce(ci.country_id, cast('0' as varchar)) as country_id,
        coalesce(co.country_name, 'Unknown') as country_name,
        coalesce(co.country_code, 'Unknown') as country_code
    from customers cu
    left join cities ci on cu.city_id = ci.city_id
    left join countries co on ci.country_id = co.country_id
)

select * from enriched

{% endsnapshot %}

-- snapshots/snp_dim_employees.sql
-- SCD Type 2 snapshot for employee dimension
-- Tracks historical changes to employee attributes over time

{% snapshot snp_dim_employees %}

{{
    config(
        target_schema='mdw_snp',
        unique_key='employee_id',
        strategy='check',
        check_cols=['city_id', 'city_name', 'zipcode', 'country_id', 'country_name', 'country_code'],
        invalidate_hard_deletes=True
    )
}}

with employees as (
    select
        employee_id,
        first_name,
        middle_initial,
        last_name,
        birth_date,
        gender,
        city_id,
        hire_date
    from {{ ref('mdw_stg_employees') }}
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
        em.employee_id,
        coalesce(em.first_name, 'Unknown') as first_name,
        coalesce(em.middle_initial, 'Unknown') as middle_initial,
        coalesce(em.last_name, 'Unknown') as last_name,
        coalesce(
            em.first_name, 'Unknown'
        ) || ' ' || coalesce(
            em.last_name, 'Unknown'
        ) as full_name,
        em.birth_date,
        date_diff('year', em.birth_date, date('2018-12-31')) as age,
        coalesce(em.gender, 'Unknown') as gender,
        em.hire_date,
        coalesce(em.city_id, cast('0' as varchar)) as city_id,
        coalesce(ci.city_name, 'Unknown') as city_name,
        coalesce(ci.zipcode, 'Unknown') as zipcode,
        coalesce(ci.country_id, cast('0' as varchar)) as country_id,
        coalesce(co.country_name, 'Unknown') as country_name,
        coalesce(co.country_code, 'Unknown') as country_code
    from employees em
    left join cities ci on em.city_id = ci.city_id
    left join countries co on ci.country_id = co.country_id
)

select * from enriched

{% endsnapshot %}

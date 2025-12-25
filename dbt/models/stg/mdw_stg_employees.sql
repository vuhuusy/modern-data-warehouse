-- models/stg/mdw_stg_employees.sql
-- Staging view for employees/salespersons
-- Cleans and type-casts raw employee data

with source as (
    select * from {{ source('grocery', 'employees') }}
),

cleaned as (
    select
        cast(nullif(trim(employeeid), '') as varchar) as employee_id,
        nullif(trim(firstname), '') as first_name,
        nullif(trim(middleinitial), '') as middle_initial,
        nullif(trim(lastname), '') as last_name,
        cast(cast(nullif(trim(birthdate), '') as timestamp) as date) as birth_date,
        nullif(trim(gender), '') as gender,
        cast(nullif(trim(cityid), '') as varchar) as city_id,
        cast(cast(nullif(trim(hiredate), '') as timestamp) as date) as hire_date
    from source
)

select * from cleaned

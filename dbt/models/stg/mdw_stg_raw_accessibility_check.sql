-- Simple model to verify raw source tables are accessible
-- This model performs a UNION ALL of counts from each raw table
-- A successful run confirms all raw external tables are queryable

with categories_check as (
    select
        'categories' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'categories') }}
),

countries_check as (
    select
        'countries' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'countries') }}
),

cities_check as (
    select
        'cities' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'cities') }}
),

customers_check as (
    select
        'customers' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'customers') }}
),

employees_check as (
    select
        'employees' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'employees') }}
),

products_check as (
    select
        'products' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'products') }}
),

sales_check as (
    select
        'sales' as table_name,
        count(*) as row_count
    from {{ source('grocery', 'sales') }}
),

combined as (
    select * from categories_check
    union all
    select * from countries_check
    union all
    select * from cities_check
    union all
    select * from customers_check
    union all
    select * from employees_check
    union all
    select * from products_check
    union all
    select * from sales_check
)

select
    table_name,
    row_count,
    case when row_count > 0 then 'ACCESSIBLE' else 'EMPTY' end as status
from combined
-- models/cur/mdw_cur_ft_sales.sql
-- Curated sales fact table with denormalized dimensions
-- Partitioned by sales date for optimal query performance

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        partitioned_by=['partition']
    )
}}

with sales as (
    select
        sales_id,
        salesperson_id,
        customer_id,
        product_id,
        quantity,
        discount,
        total_price,
        sales_at,
        transaction_number
    from {{ ref('mdw_stg_sales') }}
),

products as (
    select
        product_id,
        product_name,
        price,
        category_id,
        category_name,
        class,
        is_allergic,
        vitality_days
    from {{ ref('mdw_std_dim_products') }}
),

customers as (
    select
        customer_id,
        full_name as customer_name,
        city_name as customer_city,
        country_name as customer_country,
        country_code as customer_country_code
    from {{ ref('mdw_std_dim_customers') }}
),

employees as (
    select
        employee_id,
        full_name as salesperson_name,
        city_name as salesperson_city,
        country_name as salesperson_country
    from {{ ref('mdw_std_dim_employees') }}
),

fact_sales as (
    select
        -- Transaction identifiers
        s.sales_id,
        s.transaction_number,

        -- Customer dimension
        s.customer_id,
        c.customer_name,
        c.customer_city,
        c.customer_country,
        c.customer_country_code,

        -- Product dimension
        s.product_id,
        p.product_name,
        p.category_id,
        p.category_name,
        p.class as product_class,
        p.is_allergic as product_is_allergic,
        p.vitality_days as product_vitality_days,

        -- Salesperson dimension
        s.salesperson_id,
        e.salesperson_name,
        e.salesperson_city,
        e.salesperson_country,

        -- Measures
        s.quantity,
        p.price as unit_price,
        coalesce(s.discount, cast(0 as decimal(10,2))) as discount,
        s.total_price,
        p.price * s.quantity as gross_amount,
        s.total_price - coalesce(s.discount, cast(0 as decimal(10,2))) as net_amount,

        -- Time attributes
        s.sales_at,
        date(s.sales_at) as sales_date,
        year(s.sales_at) as sales_year,
        month(s.sales_at) as sales_month,
        day(s.sales_at) as sales_day,

        -- Partition key (MUST be last)
        date_format(s.sales_at, '%Y%m%d') as partition
    from sales s
    left join products p on s.product_id = p.product_id
    left join customers c on s.customer_id = c.customer_id
    left join employees e on s.salesperson_id = e.employee_id
)

select * from fact_sales

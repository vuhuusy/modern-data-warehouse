-- models/std/mdw_std_ft_sales.sql
-- Standardized sales fact table with denormalized dimensions
-- Supports SCD Type 2: joins to dimension version valid at transaction time
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

-- Get dimension records with SCD2 validity periods
products as (
    select
        product_sk,
        product_id,
        product_name,
        price,
        category_id,
        category_name,
        class,
        is_allergic,
        vitality_days,
        valid_from,
        valid_to,
        is_current
    from {{ ref('mdw_std_dim_products') }}
),

customers as (
    select
        customer_sk,
        customer_id,
        full_name as customer_name,
        city_name as customer_city,
        country_name as customer_country,
        country_code as customer_country_code,
        valid_from,
        valid_to,
        is_current
    from {{ ref('mdw_std_dim_customers') }}
),

employees as (
    select
        employee_sk,
        employee_id,
        full_name as salesperson_name,
        city_name as salesperson_city,
        country_name as salesperson_country,
        valid_from,
        valid_to,
        is_current
    from {{ ref('mdw_std_dim_employees') }}
),

dates as (
    select
        date_key,
        date_id,
        year,
        quarter,
        month,
        week_of_year,
        day_of_month,
        day_of_week,
        month_name,
        day_name,
        is_weekend
    from {{ ref('mdw_std_dim_date') }}
),

fact_sales as (
    select
        -- Surrogate keys for dimension relationships
        coalesce(c.customer_sk, '0') as customer_sk,
        coalesce(p.product_sk, '0') as product_sk,
        coalesce(e.employee_sk, '0') as employee_sk,
        coalesce(d.date_key, date '1900-01-01') as date_key,

        -- Transaction identifiers
        s.sales_id,
        s.transaction_number,

        -- Customer dimension (natural key + attributes)
        coalesce(s.customer_id, '0') as customer_id,
        coalesce(c.customer_name, 'Unknown') as customer_name,
        coalesce(c.customer_city, 'Unknown') as customer_city,
        coalesce(c.customer_country, 'Unknown') as customer_country,
        coalesce(c.customer_country_code, 'Unknown') as customer_country_code,

        -- Product dimension (natural key + attributes)
        coalesce(s.product_id, '0') as product_id,
        coalesce(p.product_name, 'Unknown') as product_name,
        coalesce(p.category_id, '0') as category_id,
        coalesce(p.category_name, 'Unknown') as category_name,
        coalesce(p.class, 'Unknown') as product_class,
        coalesce(p.is_allergic, 'Unknown') as product_is_allergic,
        coalesce(p.vitality_days, 0) as product_vitality_days,

        -- Salesperson/Employee dimension (natural key + attributes)
        coalesce(s.salesperson_id, '0') as salesperson_id,
        coalesce(e.salesperson_name, 'Unknown') as salesperson_name,
        coalesce(e.salesperson_city, 'Unknown') as salesperson_city,
        coalesce(e.salesperson_country, 'Unknown') as salesperson_country,

        -- Date dimension attributes
        coalesce(d.date_id, 0) as date_id,
        coalesce(d.year, 0) as sales_year,
        coalesce(d.quarter, 0) as sales_quarter,
        coalesce(d.month, 0) as sales_month,
        coalesce(d.week_of_year, 0) as sales_week,
        coalesce(d.day_of_month, 0) as sales_day,
        coalesce(d.day_of_week, 0) as sales_day_of_week,
        coalesce(d.month_name, 'Unknown') as sales_month_name,
        coalesce(d.day_name, 'Unknown') as sales_day_name,
        coalesce(d.is_weekend, false) as is_weekend_sale,

        -- Measures
        coalesce(s.quantity, 0) as quantity,
        coalesce(p.price, cast(0 as decimal(10,2))) as unit_price,
        coalesce(s.discount, cast(0 as decimal(10,2))) as discount,
        coalesce(s.total_price, cast(0 as decimal(10,4))) as total_price,
        coalesce(p.price, cast(0 as decimal(10,2))) * coalesce(s.quantity, 0) as gross_amount,
        coalesce(s.total_price, cast(0 as decimal(10,4))) - coalesce(s.discount, cast(0 as decimal(10,2))) as net_amount,

        -- Time attributes
        s.sales_at,
        date(s.sales_at) as sales_date,

        -- Partition key (MUST be last)
        date_format(s.sales_at, '%Y%m%d') as partition
    from sales s
    -- SCD Type 2 join: get dimension version valid at transaction time
    left join products p
        on s.product_id = p.product_id
        and s.sales_at >= p.valid_from
        and s.sales_at < p.valid_to
    left join customers c
        on s.customer_id = c.customer_id
        and s.sales_at >= c.valid_from
        and s.sales_at < c.valid_to
    left join employees e
        on s.salesperson_id = e.employee_id
        and s.sales_at >= e.valid_from
        and s.sales_at < e.valid_to
    left join dates d
        on date(s.sales_at) = d.date_key
)

select * from fact_sales

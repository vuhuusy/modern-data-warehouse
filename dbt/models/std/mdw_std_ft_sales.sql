-- models/std/mdw_std_ft_sales.sql
-- Standardized sales fact table (normalized star schema)
-- Contains only surrogate keys, natural keys, degenerate dimensions, and measures
-- Dimension attributes should be retrieved via joins to dim tables
-- Supports SCD Type 2: surrogate keys point to dimension version valid at transaction time
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

-- Get dimension surrogate keys with SCD2 validity periods
products as (
    select
        product_sk,
        product_id,
        price,
        valid_from,
        valid_to
    from {{ ref('mdw_std_dim_products') }}
),

customers as (
    select
        customer_sk,
        customer_id,
        valid_from,
        valid_to
    from {{ ref('mdw_std_dim_customers') }}
),

employees as (
    select
        employee_sk,
        employee_id,
        valid_from,
        valid_to
    from {{ ref('mdw_std_dim_employees') }}
),

dates as (
    select
        date_key
    from {{ ref('mdw_std_dim_date') }}
    where date_key != 'DATE000000'  -- Exclude unknown record for join
),

times as (
    select
        time_key
    from {{ ref('mdw_std_dim_time') }}
    where time_key != 'TIME000000'  -- Exclude unknown record for join
),

fact_sales as (
    select
        -- Surrogate keys (FK to dimensions for star schema joins)
        coalesce(c.customer_sk, 'SK_CUST000000') as customer_sk,
        coalesce(p.product_sk, 'SK_PROD000000') as product_sk,
        coalesce(e.employee_sk, 'SK_EMP000000') as employee_sk,
        coalesce(d.date_key, 'DATE000000') as date_key,
        coalesce(t.time_key, 'TIME000000') as time_key,

        -- Degenerate dimensions (transaction-level identifiers)
        s.sales_id,
        s.transaction_number,

        -- Measures
        coalesce(s.quantity, 0) as quantity,
        coalesce(p.price, cast(0 as decimal(10,2))) as unit_price,
        coalesce(s.discount, cast(0 as decimal(10,2))) as discount_rate,
        coalesce(p.price, cast(0 as decimal(10,2))) * coalesce(s.quantity, 0) as gross_amount,
        coalesce(p.price, cast(0 as decimal(10,2))) * coalesce(s.quantity, 0) * coalesce(s.discount, cast(0 as decimal(10,2))) as discount_amount,
        coalesce(p.price, cast(0 as decimal(10,2))) * coalesce(s.quantity, 0) * (1 - coalesce(s.discount, cast(0 as decimal(10,2)))) as net_amount,

        -- Partition key (MUST be last)
        date_format(s.sales_at, '%Y%m%d') as partition
    from sales s
    -- SCD Type 2 join: get dimension surrogate key valid at transaction time
    left join products p
        on s.product_id = p.product_id
        and s.sales_at >= p.valid_from
        and (s.sales_at < p.valid_to or p.valid_to is null)
    left join customers c
        on s.customer_id = c.customer_id
        and s.sales_at >= c.valid_from
        and (s.sales_at < c.valid_to or c.valid_to is null)
    left join employees e
        on s.salesperson_id = e.employee_id
        and s.sales_at >= e.valid_from
        and (s.sales_at < e.valid_to or e.valid_to is null)
    left join dates d
        on date_format(s.sales_at, '%Y%m%d') = d.date_key
    left join times t
        on date_format(s.sales_at, '%H:%i:00') = t.time_key
)

select * from fact_sales

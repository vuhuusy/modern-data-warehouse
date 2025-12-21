-- models/std/mdw_std_ft_sales.sql
-- Standardized sales fact table at transaction grain
-- Business process: Point-of-sale grocery transactions
-- Grain: One row per sales transaction (identified by sales_id)
-- Handles unknown dimension references using surrogate key lookup

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
    where sales_id is not null
      and sales_at is not null
),

-- Deduplicate sales by sales_id, keeping the latest record
deduplicated_sales as (
    select
        sales_id,
        salesperson_id,
        customer_id,
        product_id,
        quantity,
        discount,
        total_price,
        sales_at,
        transaction_number,
        row_number() over (
            partition by sales_id
            order by sales_at desc
        ) as row_num
    from sales
),

filtered_sales as (
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
    from deduplicated_sales
    where row_num = 1
      and quantity > 0
      and total_price >= 0
),

-- Dimension lookups with Unknown handling
dim_products as (
    select
        product_sk,
        product_id,
        price
    from {{ ref('mdw_std_dim_products') }}
),

dim_customers as (
    select
        customer_sk,
        customer_id
    from {{ ref('mdw_std_dim_customers') }}
),

dim_employees as (
    select
        employee_sk,
        employee_id
    from {{ ref('mdw_std_dim_employees') }}
),

dim_date as (
    select
        date_key,
        date_id
    from {{ ref('mdw_std_dim_date') }}
),

-- Unknown dimension keys for fallback
unknown_product as (
    select product_sk, product_id, price
    from dim_products
    where product_id = -1
),

unknown_customer as (
    select customer_sk, customer_id
    from dim_customers
    where customer_id = -1
),

unknown_employee as (
    select employee_sk, employee_id
    from dim_employees
    where employee_id = -1
),

unknown_date as (
    select date_key, date_id
    from dim_date
    where date_key = date '1900-01-01'
),

fact_sales as (
    select
        -- Surrogate key for fact row
        {{ generate_surrogate_key(["'mdw_ft_sales'", 's.sales_id']) }} as sales_sk,

        -- Natural key
        s.sales_id,
        s.transaction_number,

        -- Dimension foreign keys (surrogate keys)
        coalesce(p.product_sk, up.product_sk) as product_sk,
        coalesce(c.customer_sk, uc.customer_sk) as customer_sk,
        coalesce(e.employee_sk, ue.employee_sk) as employee_sk,
        coalesce(d.date_key, ud.date_key) as date_key,

        -- Dimension natural keys (for backward compatibility and debugging)
        coalesce(s.product_id, cast(-1 as bigint)) as product_id,
        coalesce(s.customer_id, cast(-1 as bigint)) as customer_id,
        coalesce(s.salesperson_id, cast(-1 as bigint)) as salesperson_id,

        -- Measures (additive)
        s.quantity,
        coalesce(p.price, cast(null as decimal(10,2))) as unit_price,
        s.discount,
        s.total_price,
        case
            when p.price is not null and s.quantity is not null
            then cast(p.price * s.quantity as decimal(10,4))
            else cast(null as decimal(10,4))
        end as gross_amount,

        -- Time attributes
        s.sales_at,
        coalesce(date(s.sales_at), date '1900-01-01') as sales_date,

        -- Partition key (MUST be last)
        coalesce(date_format(s.sales_at, '%Y%m%d'), '19000101') as partition

    from filtered_sales s
    left join dim_products p on s.product_id = p.product_id
    left join dim_customers c on s.customer_id = c.customer_id
    left join dim_employees e on s.salesperson_id = e.employee_id
    left join dim_date d on date(s.sales_at) = d.date_key
    cross join unknown_product up
    cross join unknown_customer uc
    cross join unknown_employee ue
    cross join unknown_date ud
)

select
    sales_sk,
    sales_id,
    transaction_number,
    product_sk,
    customer_sk,
    employee_sk,
    date_key,
    product_id,
    customer_id,
    salesperson_id,
    quantity,
    unit_price,
    discount,
    total_price,
    gross_amount,
    sales_at,
    sales_date,
    partition
from fact_sales

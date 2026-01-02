-- models/cur/mdw_cur_salesperson_performance.sql
-- Salesperson performance metrics aggregated by date
-- Joins fact table with employee and date dimensions for attributes
-- Incremental by partition for efficient daily loads

{{
    config(
        materialized='incremental',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        incremental_strategy='merge',
        unique_key=['date_key', 'salesperson_sk'],
        partitioned_by=['partition'],
        on_schema_change='fail'
    )
}}

with fact_sales as (
    select
        sales_id,
        customer_sk,
        product_sk,
        employee_sk,
        date_key,
        quantity,
        discount_rate,
        gross_amount,
        discount_amount,
        net_amount
    from {{ ref('mdw_std_ft_sales') }}
    {% if is_incremental() %}
    where partition = '{{ var("partition") }}'
    {% endif %}
),

dim_employees as (
    select
        employee_sk,
        employee_id,
        full_name,
        city_name,
        country_name,
        country_code
    from {{ ref('mdw_std_dim_employees') }}
),

dim_products as (
    select
        product_sk,
        category_id
    from {{ ref('mdw_std_dim_products') }}
),

dim_date as (
    select
        date_key,
        year,
        quarter,
        month,
        year_month,
        month_name,
        day_name,
        day_type
    from {{ ref('mdw_std_dim_date') }}
),

salesperson_daily_metrics as (
    select
        -- Date attributes
        f.date_key,
        d.year,
        d.quarter,
        d.month,
        d.year_month,
        d.month_name,
        d.day_name,
        d.day_type,

        -- Salesperson attributes
        e.employee_sk as salesperson_sk,
        e.employee_id as salesperson_id,
        e.full_name as salesperson_name,
        e.city_name as salesperson_city,
        e.country_name as salesperson_country,
        e.country_code as salesperson_country_code,

        -- Transaction metrics
        count(distinct f.sales_id) as total_transactions,
        count(distinct f.customer_sk) as unique_customers_served,
        count(distinct f.product_sk) as unique_products_sold,
        count(distinct p.category_id) as unique_categories_sold,

        -- Volume metrics
        sum(f.quantity) as total_quantity_sold,

        -- Revenue metrics
        sum(f.gross_amount) as gross_revenue,
        sum(f.discount_amount) as total_discounts_given,
        sum(f.net_amount) as net_revenue,

        -- Average metrics
        avg(f.net_amount) as avg_transaction_value,
        avg(f.quantity) as avg_quantity_per_transaction,
        avg(f.discount_rate) as avg_discount_rate,

        -- Technical columns
        current_timestamp as dbt_run_at,

        -- Partition key (MUST be last)
        date_format(f.date_key, '%Y%m%d') as partition
    from fact_sales f
    left join dim_employees e on f.employee_sk = e.employee_sk
    left join dim_products p on f.product_sk = p.product_sk
    left join dim_date d on f.date_key = d.date_key
    group by
        f.date_key,
        d.year,
        d.quarter,
        d.month,
        d.year_month,
        d.month_name,
        d.day_name,
        d.day_type,
        e.employee_sk,
        e.employee_id,
        e.full_name,
        e.city_name,
        e.country_name,
        e.country_code
)

select
    date_key,
    year,
    quarter,
    month,
    year_month,
    month_name,
    day_name,
    day_type,
    salesperson_sk,
    salesperson_id,
    salesperson_name,
    salesperson_city,
    salesperson_country,
    salesperson_country_code,
    total_transactions,
    unique_customers_served,
    unique_products_sold,
    unique_categories_sold,
    total_quantity_sold,
    gross_revenue,
    total_discounts_given,
    net_revenue,
    avg_transaction_value,
    avg_quantity_per_transaction,
    avg_discount_rate,
    dbt_run_at,
    partition
from salesperson_daily_metrics

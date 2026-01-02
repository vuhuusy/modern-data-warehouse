-- models/cur/mdw_cur_daily_sales.sql
-- Daily aggregated sales metrics for trend analysis
-- Joins fact table with date dimension for date attributes
-- Incremental by partition for efficient daily loads

{{
    config(
        materialized='incremental',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        incremental_strategy='merge',
        unique_key='date_key',
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
        unit_price,
        discount_rate,
        gross_amount,
        discount_amount,
        net_amount
    from {{ ref('mdw_std_ft_sales') }}
    {% if is_incremental() %}
    where partition = '{{ var("partition") }}'
    {% endif %}
),

dim_date as (
    select
        date_key,
        year,
        quarter,
        month,
        year_month,
        year_quarter,
        month_name,
        day_name,
        day_type
    from {{ ref('mdw_std_dim_date') }}
),

daily_aggregates as (
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

        -- Transaction counts
        count(distinct f.sales_id) as total_transactions,
        count(distinct f.customer_sk) as unique_customers,
        count(distinct f.product_sk) as unique_products,
        count(distinct f.employee_sk) as active_salespersons,

        -- Volume metrics
        sum(f.quantity) as total_quantity_sold,

        -- Revenue metrics
        sum(f.gross_amount) as gross_revenue,
        sum(f.discount_amount) as total_discounts,
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
    left join dim_date d on f.date_key = d.date_key
    group by
        f.date_key,
        d.year,
        d.quarter,
        d.month,
        d.year_month,
        d.month_name,
        d.day_name,
        d.day_type
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
    total_transactions,
    unique_customers,
    unique_products,
    active_salespersons,
    total_quantity_sold,
    gross_revenue,
    total_discounts,
    net_revenue,
    avg_transaction_value,
    avg_quantity_per_transaction,
    avg_discount_rate,
    dbt_run_at,
    partition
from daily_aggregates

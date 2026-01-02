-- models/cur/mdw_cur_product_performance.sql
-- Product-level performance metrics aggregated by date
-- Joins fact table with product and date dimensions for attributes
-- Incremental by partition for efficient daily loads

{{
    config(
        materialized='incremental',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        incremental_strategy='merge',
        unique_key=['date_key', 'product_sk'],
        partitioned_by=['partition'],
        on_schema_change='fail'
    )
}}

with fact_sales as (
    select
        sales_id,
        customer_sk,
        product_sk,
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

dim_products as (
    select
        product_sk,
        product_id,
        product_name,
        category_id,
        category_name,
        class as product_class,
        allergic_type
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

product_daily_metrics as (
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

        -- Product attributes
        p.product_sk,
        p.product_id,
        p.product_name,
        p.category_id,
        p.category_name,
        p.product_class,
        p.allergic_type,

        -- Transaction metrics
        count(distinct f.sales_id) as total_transactions,
        count(distinct f.customer_sk) as unique_customers,

        -- Volume metrics
        sum(f.quantity) as total_quantity_sold,

        -- Revenue metrics
        sum(f.gross_amount) as gross_revenue,
        sum(f.discount_amount) as total_discounts,
        sum(f.net_amount) as net_revenue,

        -- Average metrics
        avg(f.net_amount) as avg_transaction_value,
        avg(f.quantity) as avg_quantity_per_transaction,
        min(f.unit_price) as min_unit_price,
        max(f.unit_price) as max_unit_price,

        -- Technical columns
        current_timestamp as dbt_run_at,

        -- Partition key (MUST be last)
        date_format(f.date_key, '%Y%m%d') as partition
    from fact_sales f
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
        p.product_sk,
        p.product_id,
        p.product_name,
        p.category_id,
        p.category_name,
        p.product_class,
        p.allergic_type
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
    product_sk,
    product_id,
    product_name,
    category_id,
    category_name,
    product_class,
    allergic_type,
    total_transactions,
    unique_customers,
    total_quantity_sold,
    gross_revenue,
    total_discounts,
    net_revenue,
    avg_transaction_value,
    avg_quantity_per_transaction,
    min_unit_price,
    max_unit_price,
    dbt_run_at,
    partition
from product_daily_metrics

-- models/cur/mdw_cur_category_daily_sales.sql
-- Category-level daily sales metrics for category management
-- Enables category performance comparison and trend analysis

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        partitioned_by=['partition']
    )
}}

with fact_sales as (
    select
        sales_id,
        sales_date,
        category_id,
        category_name,
        product_id,
        customer_id,
        quantity,
        discount,
        total_price,
        gross_amount,
        net_amount
    from {{ ref('mdw_std_ft_sales') }}
),

category_daily_metrics as (
    select
        sales_date,
        category_id,
        category_name,

        -- Transaction metrics
        count(distinct sales_id) as total_transactions,
        count(distinct customer_id) as unique_customers,
        count(distinct product_id) as unique_products_sold,

        -- Volume metrics
        sum(quantity) as total_quantity_sold,

        -- Revenue metrics
        sum(gross_amount) as gross_revenue,
        sum(discount) as total_discounts,
        sum(total_price) as total_revenue,
        sum(net_amount) as net_revenue,

        -- Average metrics
        avg(total_price) as avg_transaction_value,
        avg(quantity) as avg_quantity_per_transaction,

        -- Partition key (MUST be last)
        date_format(sales_date, '%Y%m%d') as partition
    from fact_sales
    group by
        sales_date,
        category_id,
        category_name
)

select * from category_daily_metrics

-- models/cur/mdw_cur_product_performance.sql
-- Product-level performance metrics aggregated by date
-- Enables product ranking and category analysis

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
        product_id,
        product_name,
        category_id,
        category_name,
        product_class,
        customer_id,
        quantity,
        unit_price,
        discount,
        total_price,
        gross_amount,
        net_amount
    from {{ ref('mdw_cur_ft_sales') }}
),

product_daily_metrics as (
    select
        sales_date,
        product_id,
        product_name,
        category_id,
        category_name,
        product_class,

        -- Transaction metrics
        count(distinct sales_id) as total_transactions,
        count(distinct customer_id) as unique_customers,

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
        min(unit_price) as min_unit_price,
        max(unit_price) as max_unit_price,

        -- Partition key (MUST be last)
        date_format(sales_date, '%Y%m%d') as partition
    from fact_sales
    group by
        sales_date,
        product_id,
        product_name,
        category_id,
        category_name,
        product_class
)

select * from product_daily_metrics

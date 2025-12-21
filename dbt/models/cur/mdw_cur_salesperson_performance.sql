-- models/cur/mdw_cur_salesperson_performance.sql
-- Salesperson performance metrics aggregated by date
-- Enables sales team analysis and performance tracking

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
        salesperson_id,
        salesperson_name,
        salesperson_city,
        salesperson_country,
        customer_id,
        product_id,
        category_id,
        quantity,
        discount,
        total_price,
        gross_amount,
        net_amount
    from {{ ref('mdw_cur_ft_sales') }}
),

salesperson_daily_metrics as (
    select
        sales_date,
        salesperson_id,
        salesperson_name,
        salesperson_city,
        salesperson_country,

        -- Transaction metrics
        count(distinct sales_id) as total_transactions,
        count(distinct customer_id) as unique_customers_served,
        count(distinct product_id) as unique_products_sold,
        count(distinct category_id) as unique_categories_sold,

        -- Volume metrics
        sum(quantity) as total_quantity_sold,

        -- Revenue metrics
        sum(gross_amount) as gross_revenue,
        sum(discount) as total_discounts_given,
        sum(total_price) as total_revenue,
        sum(net_amount) as net_revenue,

        -- Average metrics
        avg(total_price) as avg_transaction_value,
        avg(quantity) as avg_quantity_per_transaction,
        avg(discount) as avg_discount_per_transaction,

        -- Partition key (MUST be last)
        date_format(sales_date, '%Y%m%d') as partition
    from fact_sales
    group by
        sales_date,
        salesperson_id,
        salesperson_name,
        salesperson_city,
        salesperson_country
)

select * from salesperson_daily_metrics

-- models/cur/mdw_cur_daily_sales.sql
-- Daily aggregated sales metrics for trend analysis
-- Partitioned by date for efficient time-series queries

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
        customer_id,
        product_id,
        category_id,
        salesperson_id,
        quantity,
        unit_price,
        discount,
        total_price,
        gross_amount,
        net_amount
    from {{ ref('mdw_std_ft_sales') }}
),

daily_aggregates as (
    select
        sales_date,

        -- Transaction counts
        count(distinct sales_id) as total_transactions,
        count(distinct customer_id) as unique_customers,
        count(distinct product_id) as unique_products,
        count(distinct salesperson_id) as active_salespersons,

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
        avg(discount) as avg_discount_per_transaction,

        -- Partition key (MUST be last)
        date_format(sales_date, '%Y%m%d') as partition
    from fact_sales
    group by sales_date
)

select * from daily_aggregates

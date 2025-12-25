-- models/cur/mdw_cur_customer_summary.sql
-- Customer-level summary metrics for segmentation and lifetime value analysis
-- Non-partitioned (small dimension-like aggregate)

{{
    config(
        materialized='table',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy'
    )
}}

with fact_sales as (
    select
        sales_id,
        sales_date,
        customer_id,
        customer_name,
        customer_city,
        customer_country,
        customer_country_code,
        product_id,
        category_id,
        category_name,
        quantity,
        discount,
        total_price,
        gross_amount,
        net_amount
    from {{ ref('mdw_std_ft_sales') }}
),

customer_metrics as (
    select
        customer_id,
        customer_name,
        customer_city,
        customer_country,
        customer_country_code,

        -- Activity metrics
        min(sales_date) as first_purchase_date,
        max(sales_date) as last_purchase_date,
        date_diff('day', min(sales_date), max(sales_date)) as customer_tenure_days,

        -- Transaction metrics
        count(distinct sales_id) as total_transactions,
        count(distinct sales_date) as active_days,
        count(distinct product_id) as unique_products_purchased,
        count(distinct category_id) as unique_categories_purchased,

        -- Volume metrics
        sum(quantity) as total_quantity_purchased,

        -- Revenue metrics (Customer Lifetime Value components)
        sum(gross_amount) as lifetime_gross_revenue,
        sum(discount) as lifetime_discounts,
        sum(total_price) as lifetime_revenue,
        sum(net_amount) as lifetime_net_revenue,

        -- Average metrics
        avg(total_price) as avg_transaction_value,
        avg(quantity) as avg_quantity_per_transaction,

        -- Frequency metrics
        cast(count(distinct sales_id) as double) / nullif(count(distinct sales_date), 0) as avg_transactions_per_active_day
    from fact_sales
    group by
        customer_id,
        customer_name,
        customer_city,
        customer_country,
        customer_country_code
)

select * from customer_metrics

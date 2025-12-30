-- models/cur/mdw_cur_customer_summary.sql
-- Customer-level summary metrics for segmentation and lifetime value analysis
-- Joins fact table with customer dimension for customer attributes
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
        customer_sk,
        product_sk,
        date_key,
        quantity,
        gross_amount,
        discount_amount,
        net_amount
    from {{ ref('mdw_std_ft_sales') }}
    where partition = '{{ var("partition") }}'
),

dim_customers as (
    select
        customer_sk,
        customer_id,
        full_name,
        city_name,
        country_name,
        country_code
    from {{ ref('mdw_std_dim_customers') }}
),

dim_products as (
    select
        product_sk,
        category_id
    from {{ ref('mdw_std_dim_products') }}
),

customer_metrics as (
    select
        -- Customer attributes
        c.customer_sk,
        c.customer_id,
        c.full_name as customer_name,
        c.city_name as customer_city,
        c.country_name as customer_country,
        c.country_code as customer_country_code,

        -- Activity metrics
        min(f.date_key) as first_purchase_date,
        max(f.date_key) as last_purchase_date,
        date_diff('day', min(f.date_key), max(f.date_key)) as customer_tenure_days,

        -- Transaction metrics
        count(distinct f.sales_id) as total_transactions,
        count(distinct f.date_key) as active_days,
        count(distinct f.product_sk) as unique_products_purchased,
        count(distinct p.category_id) as unique_categories_purchased,

        -- Volume metrics
        sum(f.quantity) as total_quantity_purchased,

        -- Revenue metrics (Customer Lifetime Value components)
        sum(f.gross_amount) as lifetime_gross_revenue,
        sum(f.discount_amount) as lifetime_discounts,
        sum(f.net_amount) as lifetime_net_revenue,

        -- Average metrics
        avg(f.net_amount) as avg_transaction_value,
        avg(f.quantity) as avg_quantity_per_transaction,

        -- Frequency metrics
        cast(count(distinct f.sales_id) as double) / nullif(count(distinct f.date_key), 0) as avg_transactions_per_active_day
    from fact_sales f
    left join dim_customers c on f.customer_sk = c.customer_sk
    left join dim_products p on f.product_sk = p.product_sk
    group by
        c.customer_sk,
        c.customer_id,
        c.full_name,
        c.city_name,
        c.country_name,
        c.country_code
)

select
    customer_sk,
    customer_id,
    customer_name,
    customer_city,
    customer_country,
    customer_country_code,
    first_purchase_date,
    last_purchase_date,
    customer_tenure_days,
    total_transactions,
    active_days,
    unique_products_purchased,
    unique_categories_purchased,
    total_quantity_purchased,
    lifetime_gross_revenue,
    lifetime_discounts,
    lifetime_net_revenue,
    avg_transaction_value,
    avg_quantity_per_transaction,
    avg_transactions_per_active_day
from customer_metrics

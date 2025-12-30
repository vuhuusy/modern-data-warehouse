-- models/cur/mdw_cur_customer_summary.sql
-- Customer-level summary metrics for segmentation and lifetime value analysis
-- Incremental with merge: only processes customers with activity in new partition
-- Merges new metrics with existing summary to maintain lifetime totals
-- Uses ARRAY to store distinct product/category for accurate merge
-- Full refresh: scans entire fact table (use sparingly)
-- Incremental: scans only new partition, merges with existing summary

{{
    config(
        materialized='incremental',
        table_type='iceberg',
        format='parquet',
        write_compression='snappy',
        incremental_strategy='merge',
        unique_key='customer_sk',
        on_schema_change='fail'
    )
}}

with new_partition_sales as (
    -- Only get sales from the new partition (incremental) or all sales (full refresh)
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
    {% if is_incremental() %}
    where partition = '{{ var("partition") }}'
    {% endif %}
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

-- Calculate metrics from new partition only
-- Use array_agg for distinct tracking
new_customer_metrics as (
    select
        f.customer_sk,
        min(f.date_key) as new_first_purchase_date,
        max(f.date_key) as new_last_purchase_date,
        count(distinct f.sales_id) as new_transactions,
        count(distinct f.date_key) as new_active_days,
        array_agg(distinct f.product_sk) as new_product_sks,
        array_agg(distinct p.category_id) as new_category_ids,
        sum(f.quantity) as new_quantity,
        sum(f.gross_amount) as new_gross_revenue,
        sum(f.discount_amount) as new_discounts,
        sum(f.net_amount) as new_net_revenue
    from new_partition_sales f
    left join dim_products p on f.product_sk = p.product_sk
    group by f.customer_sk
),

{% if is_incremental() %}
-- Get existing summary for customers with new activity
existing_summary as (
    select *
    from {{ this }}
    where customer_sk in (select customer_sk from new_customer_metrics)
),

-- Merge existing + new metrics
merged_metrics as (
    select
        n.customer_sk,
        -- Take min of existing and new first purchase date
        least(coalesce(e.first_purchase_date, n.new_first_purchase_date), n.new_first_purchase_date) as first_purchase_date,
        -- Take max of existing and new last purchase date
        greatest(coalesce(e.last_purchase_date, n.new_last_purchase_date), n.new_last_purchase_date) as last_purchase_date,
        -- Sum totals
        coalesce(e.total_transactions, 0) + n.new_transactions as total_transactions,
        coalesce(e.active_days, 0) + n.new_active_days as active_days,
        -- Merge arrays using array_union for accurate distinct counts
        array_distinct(concat(coalesce(e.purchased_product_sks, array[]), n.new_product_sks)) as purchased_product_sks,
        array_distinct(concat(coalesce(e.purchased_category_ids, array[]), n.new_category_ids)) as purchased_category_ids,
        coalesce(e.total_quantity_purchased, 0) + n.new_quantity as total_quantity_purchased,
        coalesce(e.lifetime_gross_revenue, cast(0 as decimal(18,2))) + n.new_gross_revenue as lifetime_gross_revenue,
        coalesce(e.lifetime_discounts, cast(0 as decimal(18,2))) + n.new_discounts as lifetime_discounts,
        coalesce(e.lifetime_net_revenue, cast(0 as decimal(18,2))) + n.new_net_revenue as lifetime_net_revenue
    from new_customer_metrics n
    left join existing_summary e on n.customer_sk = e.customer_sk
)
{% else %}
-- Full refresh: calculate all metrics from scratch
merged_metrics as (
    select
        customer_sk,
        min(new_first_purchase_date) as first_purchase_date,
        max(new_last_purchase_date) as last_purchase_date,
        sum(new_transactions) as total_transactions,
        sum(new_active_days) as active_days,
        flatten(array_agg(new_product_sks)) as purchased_product_sks,
        flatten(array_agg(new_category_ids)) as purchased_category_ids,
        sum(new_quantity) as total_quantity_purchased,
        sum(new_gross_revenue) as lifetime_gross_revenue,
        sum(new_discounts) as lifetime_discounts,
        sum(new_net_revenue) as lifetime_net_revenue
    from new_customer_metrics
    group by customer_sk
)
{% endif %}

select
    m.customer_sk,
    c.customer_id,
    c.full_name as customer_name,
    c.city_name as customer_city,
    c.country_name as customer_country,
    c.country_code as customer_country_code,
    m.first_purchase_date,
    m.last_purchase_date,
    date_diff('day', m.first_purchase_date, m.last_purchase_date) as customer_tenure_days,
    m.total_transactions,
    m.active_days,
    -- Store arrays for merge capability
    m.purchased_product_sks,
    m.purchased_category_ids,
    -- Calculate cardinality for reporting
    cardinality(m.purchased_product_sks) as unique_products_purchased,
    cardinality(m.purchased_category_ids) as unique_categories_purchased,
    m.total_quantity_purchased,
    m.lifetime_gross_revenue,
    m.lifetime_discounts,
    m.lifetime_net_revenue,
    cast(m.lifetime_net_revenue as double) / nullif(m.total_transactions, 0) as avg_transaction_value,
    cast(m.total_quantity_purchased as double) / nullif(m.total_transactions, 0) as avg_quantity_per_transaction,
    cast(m.total_transactions as double) / nullif(m.active_days, 0) as avg_transactions_per_active_day
from merged_metrics m
left join dim_customers c on m.customer_sk = c.customer_sk

-- snapshots/snp_dim_products.sql
-- SCD Type 2 snapshot for product dimension
-- Tracks historical changes to product attributes over time

{% snapshot snp_dim_products %}

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='check',
        check_cols=['product_name', 'price', 'category_id', 'class', 'resistant', 'is_allergic', 'vitality_days'],
        invalidate_hard_deletes=True
    )
}}

with products as (
    select
        product_id,
        product_name,
        price,
        category_id,
        class,
        modify_date,
        resistant,
        is_allergic,
        vitality_days
    from {{ ref('mdw_stg_products') }}
),

categories as (
    select
        category_id,
        category_name
    from {{ ref('mdw_stg_categories') }}
),

enriched as (
    select
        pr.product_id,
        coalesce(pr.product_name, 'Unknown') as product_name,
        coalesce(pr.price, cast(null as decimal(10,2))) as price,
        coalesce(pr.category_id, cast('0' as varchar)) as category_id,
        coalesce(ca.category_name, 'Unknown') as category_name,
        coalesce(pr.class, 'Unknown') as class,
        pr.modify_date,
        coalesce(pr.resistant, 'Unknown') as resistant,
        coalesce(pr.is_allergic, 'Unknown') as is_allergic,
        pr.vitality_days
    from products pr
    left join categories ca on pr.category_id = ca.category_id
)

select * from enriched

{% endsnapshot %}

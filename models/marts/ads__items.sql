with
items as (
    select *
    from {{ ref('int_items_exchanged') }}
),

items_aggregated as (
    select
        date_day,
        key_name,
        item_id,
        item_name,
        currency_code_final,

        sum(items_viewed) as items_viewed,
        sum(items_viewed_in_list) as items_viewed_in_list,
        sum(items_added_to_cart) as items_added_to_cart,
        sum(items_checked_out) as items_checked_out,
        sum(items_purchased) as items_purchased,
        sum(item_revenue_final) as item_revenue_final
    from items
    {{ dbt_utils.group_by(n=5) }}
)

select * from items_aggregated

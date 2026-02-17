with
source as (
    select *
    from {{ source('google_analytics', 'items') }}
),

renamed as (
    select
       {{ adapter.quote('date') }} as date_day,
       
       property_id as property_id,
       item_id as item_id,
       
       upper(config_group) as key_name,
       item_name as item_name,

       currency_code as analytics_currency,

       coalesce(items_viewed, 0) as items_viewed,
       coalesce(items_viewed_in_list, 0) as items_viewed_in_list,
       coalesce(items_added_to_cart, 0) as items_added_to_cart,
       coalesce(items_checked_out, 0) as items_checked_out,
       coalesce(items_purchased, 0) as items_purchased,
       round(cast(coalesce(item_revenue, 0) as numeric), 2) as item_revenue
    from source
)

select * from renamed

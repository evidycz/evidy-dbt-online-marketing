{{ config(enabled=var('ads__meta_ads_enabled', True)) }}

with
source as (
    select *
    from {{ source('meta_ads', 'campaigns__action_values') }}
),

filtered as (
    select
        _dlt_parent_id as parent_row_id,

        action_type as event_name,
        round(cast({{ adapter.quote('value') }} as float64), 2) as event_value
    from source
    where action_type in ('view_content', 'add_to_cart', 'initiate_checkout', 'purchase')
)

select * from filtered

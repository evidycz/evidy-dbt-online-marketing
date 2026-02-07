{{ config(enabled=var('ads__meta_ads_enabled', True)) }}

with source as (
    select *
    from {{ source('meta_ads', 'campaigns__actions') }}
),

filtered as (
    select
        _dlt_parent_id as parent_row_id,

        action_type as event_name,
        round(cast({{ adapter.quote('value') }} as float64), 2) as event_count
    from source
    where action_type in ('view_content', 'add_to_cart', 'initiate_checkout', 'purchase')
)

select * from filtered
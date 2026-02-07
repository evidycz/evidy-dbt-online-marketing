{{ config(enabled=var('ads__meta_ads_enabled', True)) }}

with
event_count as (
    select *
    from {{ ref('base_meta_ads__campaigns__actions') }}
),

event_value as (
    select *
    from {{ ref('base_meta_ads__campaigns__action_values') }}
),

joined as (
    select
        event_count.*,
        event_value.event_value
    from event_count
    left join event_value
        on event_count.parent_row_id = event_value.parent_row_id
        and event_count.event_name = event_value.event_name
)

select * from joined

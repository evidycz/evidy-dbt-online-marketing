with
events as (
    select *
    from {{ ref('int_events_exchanged') }}
),

events_aggregated as (
    select
        date_day,
        key_name,
        source_medium,
        event_name,
        currency_code_final,

        sum(event_count) as event_count,
        sum(event_value_final) as event_value_final
    from events
    {{ dbt_utils.group_by(n=5) }}
)

select * from events_aggregated

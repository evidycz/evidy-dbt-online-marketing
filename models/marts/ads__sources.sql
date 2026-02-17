with
sources as (
    select *
    from {{ ref('int_sources_exchanged') }}
),

costs as (
    select
        date_day,
        key_name,
        source_medium,
        cost_final
    from {{ ref('int_unioned_ads') }}
),

sources_aggregated as (
    select
        date_day,
        key_name,
        source_medium,
        currency_code_final as currency_code,

        sum(sessions) as sessions,
        sum(engaged_sessions) as engaged_sessions,
        sum(total_users) as total_users,
        sum(new_users) as new_users,
        sum(purchases) as purchases,
        sum(revenue_final) as revenue_final
    from sources
    {{ dbt_utils.group_by(n=4) }}
),

costs_aggregated as (
    select
        date_day,
        key_name,
        source_medium,
        sum(cost_final) as ads_cost_final
    from costs
    {{ dbt_utils.group_by(n=3) }}
),

sources_joined_costs as (
    select
        sources_aggregated.*,
        costs_aggregated.ads_cost_final
    from sources_aggregated
    left join costs_aggregated
        on sources_aggregated.date_day = costs_aggregated.date_day
        and sources_aggregated.key_name = costs_aggregated.key_name
        and sources_aggregated.source_medium = costs_aggregated.source_medium
)

select * from sources_joined_costs
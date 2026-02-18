with
campaigns as (
    select *
    from {{ ref('int_unioned_ads') }}
),

sources as (
    select *
    from {{ ref('int_sources_exchanged') }}
),

sources_aggregated as (
    select
        campaign_id,
        date_day,
        key_name,
        source_medium,

        currency_code_final,

        sum(sessions) as sessions,
        sum(engaged_sessions) as engaged_sessions,
        sum(total_users) as total_users,
        sum(new_users) as new_users,
        sum(purchases) as purchases,
        sum(revenue_final) as revenue_final
    from sources
    {{ dbt_utils.group_by(n=5) }}
),

campaigns_joined_sources as (
    select
        campaigns.*,

        coalesce(sessions, 0) as sessions,
        coalesce(engaged_sessions, 0) as engaged_sessions,
        coalesce(total_users, 0) as total_users,
        coalesce(new_users, 0) as new_users,
        coalesce(purchases, 0) as purchases,
        coalesce(revenue_final, 0) as revenue_final
    from campaigns
    left join sources_aggregated
        on campaigns.campaign_id = sources_aggregated.campaign_id
        and campaigns.source_medium = sources_aggregated.source_medium
        and campaigns.key_name = sources_aggregated.key_name
        and campaigns.date_day = sources_aggregated.date_day
)

select * from campaigns_joined_sources
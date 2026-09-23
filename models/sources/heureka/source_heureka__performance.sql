{# Off by default: unlike the other platforms, most clients have no Heureka dataset. #}
{{ config(enabled=var('ads__heureka_ads_enabled', False)) }}

with
source as (
    select *
    from {{ source('heureka', 'performance') }}
),

{# The raw table is per product, click source and bidded position; ads report one row per portal and day. #}
aggregated as (
    select
        {{ adapter.quote('date') }} as date_day,
        account_id,
        portal,
        currency_code,
        config_group,
        system_name,
        source_medium,

        sum(visits_total) as visits,
        sum(orders_total) as orders,
        sum(revenue_total) as revenue,
        {# Excluding VAT, the figure the Heureka admin shows as "Náklady". #}
        sum(costs_without_vat_total) as costs
    from source
    {{ dbt_utils.group_by(n=7) }}
),

renamed as (

    select
        date_day,

        account_id as account_id,

        case portal
            when 'cz' then 'heureka.cz_cpc'
            when 'sk' then 'heureka.sk_cpc'
            when 'hu' then 'arukereso.hu_cpc'
            else 'heureka.unknown_cpc'
        end as campaign_id,

        currency_code as system_currency,

        upper(config_group) as key_name,
        upper(system_name) as system_name,
        lower(source_medium) as source_medium,

        case portal
            when 'cz' then 'heureka.cz'
            when 'sk' then 'heureka.sk'
            when 'hu' then 'arukereso.hu'
            else 'heureka'
        end as campaign_name,
        'unknown' as campaign_status,

        0 as impressions,
        coalesce(visits, 0) as clicks,
        coalesce(orders, 0) as conversions,
        coalesce(revenue, 0) as conversion_value,
        round(cast(coalesce(costs, 0) as numeric), 2) as cost

    from aggregated
)

select * from renamed

{{ config(enabled=var('ads__glami_ads_enabled', True)) }}

with
source as (
    select *
    from {{ source('glami', 'categories') }}
),

renamed as (

    select
        {{ adapter.quote('date') }} as date_day,

        account_id as account_id,
        replace(replace(lower(source_medium), ' ', ''), '/', '_')  as campaign_id,

        currency_code as system_currency,

        upper(config_group) as key_name,
        upper(_config_name) as system_name,
        lower(source_medium) as source_medium,
        'glami' as campaign_name,
        'unknown' as campaign_status,

        0 as impressions,
        coalesce(exit_clicks, 0) as clicks,
        coalesce(orders, 0) as conversions,
        coalesce(gmv, 0) as conversion_value,
        round(cast(coalesce(costs, 0) as numeric), 2) as cost

    from source
)

select * from renamed
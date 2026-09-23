{# Off by default: unlike the other platforms, most clients have no Srovnáme.cz dataset. #}
{{ config(enabled=var('ads__srovname_ads_enabled', False)) }}

with
source as (
    select *
    from {{ source('srovname', 'performance') }}
),

{# Already one row per shop and day; Srovnáme.cz has no campaigns, so the shop is the campaign. #}
renamed as (

    select
        {{ adapter.quote('date') }} as date_day,

        account_id as account_id,
        'srovname.cz_cpc' as campaign_id,

        currency_code as system_currency,

        upper(config_group) as key_name,
        upper(system_name) as system_name,
        lower(source_medium) as source_medium,
        'srovname.cz' as campaign_name,
        'unknown' as campaign_status,

        0 as impressions,
        coalesce(clicks, 0) as clicks,
        coalesce(conversions, 0) as conversions,
        coalesce(conversion_value, 0) as conversion_value,
        {# `tollSum`, the admin's "Cena za prokliky". #}
        round(cast(coalesce(costs, 0) as numeric), 2) as cost

    from source
)

select * from renamed

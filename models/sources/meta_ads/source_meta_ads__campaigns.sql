{{ config(enabled=var('ads__meta_ads_enabled', True)) }}

with
source as (
    select *
    from {{ source('meta_ads', 'campaigns') }}
),

renamed as (
    select
        date_start as date_day,
        
        {{ dbt_utils.generate_surrogate_key(["date_start", "upper(config_group)", "account_id", "campaign_id"]) }} as row_key,
        {{ dbt_utils.generate_surrogate_key(["date_start", "upper(config_group)", "lower(source_medium)"]) }} as join_key,

        _dlt_id as row_id,
        account_id as account_id,
        campaign_id as campaign_id,

        account_currency as system_currency,

        upper(config_group) as key_name,
        upper(system_name) as system_name,
        lower(source_medium) as source_medium,
        campaign_name as campaign_name,
        'UNKNOWN' as campaign_status,

        coalesce(impressions, 0) as impressions,
        coalesce(inline_link_clicks, 0) as clicks,
        round(cast(coalesce(spend, 0.0) as numeric), 2) as cost
    from source
)

select * from renamed
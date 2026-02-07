{{ config(enabled=var('ads__google_ads_enabled', True)) }}

with
source as (
    select *
    from {{ source('google_ads', 'campaigns') }}
),

renamed as (
    select
        {{ adapter.quote('date') }} as date_day,

        {{ dbt_utils.generate_surrogate_key(["date", "upper(config_group)", "account_id", "id"]) }} as row_key,
        {{ dbt_utils.generate_surrogate_key(["date", "upper(config_group)", "lower(source_medium)"]) }} as join_key,

        account_id as account_id,
        id as campaign_id,

        currency_code as system_currency,

        upper(config_group) as key_name,
        upper(system_name) as system_name,
        lower(source_medium) as source_medium,
        name as campaign_name,
        upper(status) as campaign_status,

        coalesce(impressions, 0) as impressions,
        coalesce(clicks, 0) as clicks,
        coalesce(conversions, 0.0) as conversions,
        coalesce(conversions_value, 0.0) as conversion_value,
        round(cast(coalesce({{ dbt_utils.safe_divide('cost_micros', 1000000) }}, 0.0) as numeric), 2) as cost
    from source
)

select * from renamed

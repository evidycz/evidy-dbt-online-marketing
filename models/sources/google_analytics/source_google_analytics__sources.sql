with
source as (
    select *
    from {{ source('google_analytics', 'sources') }}
),

renamed as (
    select
        {{ adapter.quote('date') }} as date_day,

        _dlt_id as row_id,
        property_id as property_id,
        session_campaign_id as campaign_id,

        upper(config_group) as key_name,
        session_source_medium as source_medium,

        currency_code as analytics_currency,

        coalesce(sessions, 0) as sessions,
        coalesce(engaged_sessions, 0) as engaged_sessions,
        coalesce(total_users, 0) as total_users,
        coalesce(new_users, 0) as new_users,
        coalesce(ecommerce_purchases, 0) as purchases,
        round(cast(coalesce(purchase_revenue, 0) as numeric), 2) as revenue
    from source
)

select * from renamed

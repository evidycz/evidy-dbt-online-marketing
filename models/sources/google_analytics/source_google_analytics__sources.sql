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
        session_source as source,
        session_medium as medium,
        session_source_medium as source_medium,

        currency_code as analytics_currency,

        coalesce(sessions, 0) as sessions,
        coalesce(engaged_sessions, 0) as engaged_sessions,
        coalesce(total_users, 0) as total_users,
        coalesce(new_users, 0) as new_users,
        coalesce(ecommerce_purchases, 0) as purchases,

        -- `purchase_revenue` is the GA4 `value` parameter and `tax_amount` the `tax`
        -- parameter, both in the property's own currency. They are summed here, before
        -- the FX conversion in `int_sources_exchanged`, so `revenue` stays tax-inclusive
        -- across the tagging change and is converted exactly once.
        round(cast(coalesce(purchase_revenue, 0) as numeric), 2) as revenue_net,
        round(cast(coalesce(tax_amount, 0) as numeric), 2) as tax,
        round(cast(coalesce(purchase_revenue, 0) + coalesce(tax_amount, 0) as numeric), 2) as revenue
    from source
),

cleaned as (
    select
        renamed.*,

        coalesce(case
            when lower(medium) in ('cpc', 'cpm') then split(net.reg_domain(source), '.')[offset(0)]
            else net.reg_domain(source)
        end, source) as source_clean,

        coalesce(concat(
            case
                when lower(medium) in ('cpc', 'cpm') then split(net.reg_domain(source), '.')[offset(0)]
                else net.reg_domain(source)
            end,
            ' / ', medium
        ), source_medium) as source_medium_clean

    from renamed
)

select * from cleaned

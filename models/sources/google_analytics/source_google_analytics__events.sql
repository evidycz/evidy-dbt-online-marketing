with
source as (
    select *
    from {{ source('google_analytics', 'events') }}
),

renamed as (
    select 
        {{ adapter.quote('date') }} as date_day,
        
        property_id,
        session_campaign_id as campaign_id,
        
        upper(config_group) as key_name,
        session_source as source,
        session_medium as medium,
        session_source_medium as source_medium,
        event_name,

        currency_code as analytics_currency,
        
        event_count,
        round(cast(event_value as numeric), 2) as event_value
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
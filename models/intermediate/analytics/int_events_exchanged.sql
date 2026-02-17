{% set convert_to_currency = var('reporting_currency', None) %}

with
events as (
    select *
    from {{ ref('source_google_analytics__events') }}
),

rates as (
    select *
    from {{ ref('source_exchange__rates') }}
),

events_exchanged as (
    select
        events.*,

        {% if convert_to_currency %}
            {{ evidy_dbt_utils.convert_currency('event_value', convert_to_currency, convert_from=['czk', 'eur'], currency_column='analytics_currency') }}
        {% else %}
            'event_value'
        {% endif %} as event_value_final,

        {% if convert_to_currency %}
            upper('{{ convert_to_currency }}')
        {% else %}
            events.analytics_currency
        {% endif %} as currency_code_final
    from events
    left join rates
        on events.date_day = rates.date_day
)

select * from events_exchanged

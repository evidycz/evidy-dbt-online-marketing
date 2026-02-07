{% set convert_to_currency = var('reporting_currency', None) %}

with
sources as (
    select *
    from {{ ref('source_google_analytics__sources') }}
),

rates as (
    select *
    from {{ ref('source_exchange__rates') }}
),

sources_exchanged as (
    select
        sources.*,

        {% if convert_to_currency %}
            {{ evidy_dbt_utils.convert_currency('revenue', convert_to_currency, convert_from=['czk', 'eur'], currency_column='analytics_currency') }}
        {% else %}
            'revenue'
        {% endif %} as revenue_final,

        {% if convert_to_currency %}
            upper('{{ convert_to_currency }}')
        {% else %}
            sources.analytics_currency
        {% endif %} as currency_code_final
    from sources
    left join rates on
        sources.date_day = rates.date_day
)

select * from sources_exchanged
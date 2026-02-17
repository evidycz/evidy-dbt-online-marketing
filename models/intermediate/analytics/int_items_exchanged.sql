{% set convert_to_currency = var('reporting_currency', None) %}

with
items as (
    select *
    from {{ ref('source_google_analytics__items') }}
),

rates as (
    select *
    from {{ ref('source_exchange__rates') }}
),

items_exchanged as (
    select
        items.*,

        {% if convert_to_currency %}
            {{ evidy_dbt_utils.convert_currency('item_revenue', convert_to_currency, convert_from=['czk', 'eur'], currency_column='analytics_currency') }}
        {% else %}
            'item_revenue'
        {% endif %} as item_revenue_final,

        {% if convert_to_currency %}
            upper('{{ convert_to_currency }}')
        {% else %}
            items.analytics_currency
        {% endif %} as currency_code_final
    from items
    left join rates
        on items.date_day = rates.date_day
)

select * from items_exchanged

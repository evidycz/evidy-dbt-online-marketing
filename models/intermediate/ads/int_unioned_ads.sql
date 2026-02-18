{% set convert_to_currency = var('reporting_currency', None) %}

{%  set source_config = [
    ('ads__glami_ads_enabled',  'source_glami__categories'),
    ('ads__google_ads_enabled', 'source_google_ads__campaigns'),
    ('ads__meta_ads_enabled',   'source_meta_ads__campaigns'),
    ('ads__seznam_ads_enabled', 'source_seznam_sklik__campaigns')
] %}

{% set relations_to_union = [] %}

{% for var_name, model_name in source_config %}

    {% if var(var_name, true) %}
        {% do relations_to_union.append(ref(model_name)) %}
    {% endif %}

{% endfor %}

with campaigns_unioned as (
    {{ dbt_utils.union_relations(
        relations=relations_to_union
    ) }}
),

rates as (
    select *
    from {{ ref('source_exchange__rates') }}
),

campaigns_aggregated as (
    select
        date_day,
        account_id,
        campaign_id,
        system_currency,

        key_name,
        system_name,
        source_medium,
        campaign_status,

        array_agg(campaign_name order by  date_day desc limit 1)[offset(0)] as campaign_name,

        sum(impressions) as impressions,
        sum(clicks) as clicks,
        sum(conversions) as conversions,
        sum(conversion_value) as conversion_value,
        sum(cost) as cost
    from campaigns_unioned
    {{ dbt_utils.group_by(n=8) }}
),

metrics_exchanged as (
    select
        campaigns_aggregated.*,

        {% if convert_to_currency %}
            {{ evidy_dbt_utils.convert_currency('cost', convert_to_currency, convert_from=['czk', 'eur', 'huf', 'usd'], currency_column='system_currency') }}
        {% else %}
            'cost'
        {% endif %} as cost_final,

        {% if convert_to_currency %}
            {{ evidy_dbt_utils.convert_currency('conversion_value', convert_to_currency, convert_from=['czk', 'eur', 'huf', 'usd'], currency_column='system_currency') }}
        {% else %}
            'conversion_value'
        {% endif %} as conversion_value_final,

        {% if convert_to_currency %}
            upper('{{ convert_to_currency }}')
        {% else %}
            campaigns_aggregated.system_currency
        {% endif %} as currency_code_final

    from campaigns_aggregated
    left join rates
        on campaigns_aggregated.date_day = rates.date_day
)

select * from metrics_exchanged
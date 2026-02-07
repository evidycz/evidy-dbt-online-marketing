with
source as (
    select *
    from {{ source('open_exchange', 'rates') }}
),

renamed as (
    select
        {{ adapter.quote('date') }} as date_day,
        cast(base as numeric) as base_currency,
        cast(rates__eur as numeric) as eur,
        cast(rates__usd as numeric) as usd,
        cast(rates__huf as numeric) as huf,
        cast(rates__gbp as numeric) as gbp,
        cast(rates__pln as numeric) as pln
    from source
),

final as (
    select
        date_day,
        round(usd, 5) as czk_to_usd,
        round(eur, 5) as czk_to_eur,
        round(huf, 5) as czk_to_huf,
        round(pln, 5) as czk_to_pln,
        round(gbp, 5) as czk_to_gbp,
        round(1 / usd, 5) as usd_to_czk,
        round(1 / eur, 5) as eur_to_czk,
        round(1 / huf, 5) as huf_to_czk,
        round(1 / pln, 5) as pln_to_czk,
        round(1 / gbp, 5) as gbp_to_czk,
        round(eur / usd, 5) as usd_to_eur,
        round(usd / eur, 5) as eur_to_usd,
        round(huf / usd, 5) as usd_to_huf,
        round(usd / huf, 5) as huf_to_usd,
        round(huf / eur, 5) as eur_to_huf,
        round(eur / huf, 5) as huf_to_eur,
        round(eur / pln, 5) as pln_to_eur,
        round(pln / eur, 5) as eur_to_pln,
        round(eur / gbp, 5) as gbp_to_eur,
        round(gbp / eur, 5) as eur_to_gbp
    from renamed
)

select * from final
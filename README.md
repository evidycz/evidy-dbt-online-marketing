# Online Marketing dbt Project

This dbt project (`evidy_dbt_online_ads`) transforms raw online marketing data from various platforms into analytics-ready data marts. Raw data is loaded by [DLT](https://dlthub.com/) into BigQuery; this package transforms it.

The project can be used **standalone** (run directly) or as a **dependency** of a larger dbt project (added via `packages.yml`).

## Architecture

**Data flow:** Raw BigQuery tables → Sources (views) → Intermediate (ephemeral) → Marts (tables)

### Model Layers

- **Sources** (`models/sources/`) — One subfolder per platform. Cleans, renames, and normalizes raw DLT-loaded tables. Normalizes costs. Materialized as **views** in `ads_sources` schema.
- **Intermediate** (`models/intermediate/`) — Unions all enabled ad platform sources, applies currency conversion, and prepares GA4 data. All **ephemeral**.
- **Marts** (`models/marts/`) — Final tables for reporting and analysis. Materialized as **tables** in `ads` schema.

### Data Marts

| Model | Grain | Description |
|---|---|---|
| `ads__campaigns` | campaign / date / source_medium | Campaign-level performance: ad costs LEFT JOIN GA4 sessions and revenue |
| `ads__sources` | source_medium / date / key_name | Source/medium-level: GA4 engagement LEFT JOIN aggregated ad spend |
| `ads__events` | event_name / date / source_medium | GA4 event counts and values with currency exchange |
| `ads__items` | item_id / date / key_name | GA4 item-level e-commerce funnel (views → cart → checkout → purchase) |

## Configuration

### Required Variables

| Variable | Default | Description |
|---|---|---|
| `client_name` | `default-client` | Multi-tenant identifier. Used to build source schema names (e.g., `my_client_google_ads`). |
| `reporting_currency` | `czk` | Target currency for all financial metrics. All costs and revenue are converted to this currency. |

### Optional Variables

| Variable | Default | Description |
|---|---|---|
| `ads_database` | `target.database` | Override the BigQuery database/project for ad platform source data. |
| `exchange_database` | `target.database` | Override the BigQuery database/project for exchange rate data. |

### Feature Flags

Each ad platform can be individually enabled or disabled. When disabled, the platform's source models are skipped and excluded from the union.

| Variable | Default | Description |
|---|---|---|
| `ads__google_ads_enabled` | `true` | Enable Google Ads data |
| `ads__meta_ads_enabled` | `true` | Enable Meta (Facebook) Ads data |
| `ads__seznam_ads_enabled` | `true` | Enable Seznam/Sklik data |
| `ads__glami_ads_enabled` | `true` | Enable Glami data |

Google Analytics sources are always enabled (no feature flag).

### Example Usage

```bash
# Install dependencies
uv sync
dbt deps

# Run all models
dbt run --vars '{"client_name": "my_client", "reporting_currency": "czk"}'

# Run with only Google Ads and Meta enabled
dbt run --vars '{"client_name": "my_client", "ads__seznam_ads_enabled": false, "ads__glami_ads_enabled": false}'

# Run a single mart
dbt run --select ads__campaigns --vars '{"client_name": "my_client"}'

# Run tests
dbt test --select tag:marketing --vars '{"client_name": "my_client"}'
```

### Materialization Strategy

| Layer | Materialization | Schema |
|---|---|---|
| Sources | `view` | `ads_sources` |
| Sources (util) | `ephemeral` | — |
| Intermediate | `ephemeral` | — |
| Marts | `table` | `ads` |

## Ad Platform Differences

All ad platform sources are normalized to a common schema before being unioned in `int_unioned_ads`. However, the raw data varies significantly across platforms:

### Common Output Columns

All platform sources produce: `date_day`, `account_id`, `campaign_id`, `system_currency`, `key_name`, `system_name`, `source_medium`, `campaign_name`, `campaign_status`, `impressions`, `clicks`, `conversions`, `conversion_value`, `cost`.

### Google Ads

- **Source table:** `google_ads.campaigns`
- **Cost unit:** Micros (divided by 1,000,000)
- **Full data:** All standard columns available including `conversions`, `conversion_value`, `campaign_status`

### Meta (Facebook) Ads

- **Source table:** `meta_ads.campaigns`
- **Cost unit:** Standard (spend field, no conversion needed)
- **Clicks:** Uses `inline_link_clicks` as proxy (not total clicks)
- **Missing columns:** `conversions`, `conversion_value` set to 0.0
- **Campaign status:** Hardcoded to `'UNKNOWN'` (not available in the Meta API export)
- **Events:** Separate `source_meta_ads__events` model joins action counts with action values for event-level detail (view_content, add_to_cart, initiate_checkout, purchase)

### Seznam/Sklik

- **Source table:** `seznam_sklik.campaigns`
- **Cost unit:** Centiseks (divided by 100, field: `total_money`)
- **Full data:** All standard columns available including `conversions`, `conversion_value`, `campaign_status`

### Glami

- **Source table:** `glami.categories`
- **Granularity:** Category-level (not campaign-level)
- **Cost unit:** Standard (`costs` field, no conversion needed)
- **Field mappings:** `exit_clicks` → clicks, `orders` → conversions, `gmv` → conversion_value
- **Hardcoded values:** `impressions` = 0 (not tracked), `campaign_name` = `'glami'`, `campaign_status` = `'unknown'`

### Google Analytics (GA4)

- **Source tables:** `google_analytics.sources`, `google_analytics.events`, `google_analytics.items`
- **Not part of ad union:** GA4 data flows through separate intermediate models (`int_sources_exchanged`, `int_events_exchanged`, `int_items_exchanged`)
- **Joined in marts:** GA4 sessions/revenue are joined to ad data in `ads__campaigns` and `ads__sources`; events and items have their own dedicated marts

## Currency Conversion

All financial metrics (cost, conversion_value, revenue, event_value, item_revenue) are converted to the `reporting_currency` using daily exchange rates from the `open_exchange.rates` source.

- Exchange rates are loaded separately and joined by `date_day`
- Conversion is handled by the `evidy_dbt_utils.convert_currency()` macro
- Original currency values are preserved alongside `*_final` converted columns
- The `currency_code_final` column indicates the target currency in each mart

## Dependencies

- **[dbt_utils](https://github.com/dbt-labs/dbt-utils)** (v1.3.x) — `generate_surrogate_key`, `union_relations`, `group_by`, `safe_divide`, `unique_combination_of_columns`
- **[evidy_dbt_utils](https://github.com/evidycz/evidy-dbt-utils)** (v1.1.0) — `convert_currency`, `clean_url_domain`

## Semantic Layer

Every mart model includes a [Lightdash](https://www.lightdash.com/) semantic layer definition using dbt 1.10+ `config.meta` syntax. Definitions include dimensions, aggregate metrics (sum), and derived metrics (CPM, CPC, CTR, PNO, ROAS, etc.).

## Adapters

- **BigQuery** (`dbt-bigquery`) — primary/production
- **DuckDB** (`dbt-duckdb`) — development

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`evidy_dbt_online_ads` is a multi-tenant dbt package for online marketing analytics. It unifies data from multiple ad platforms (Google Ads, Meta Ads, Seznam/Sklik, Glami) and Google Analytics into standardized mart tables. Raw data is loaded by DLT into BigQuery; this package transforms it.

The project can be used **standalone** (run directly) or as a **dependency** of a larger dbt project (added via `packages.yml`). The dynamic `client_name` variable and configurable `ads_database`/`exchange_database` make it portable across different environments and parent projects.

## Key Commands

```bash
# Install Python deps (uses uv, not pip)
uv sync

# Install dbt packages
dbt deps

# Run all models (requires --vars for client context)
dbt run --vars '{"client_name": "my_client", "reporting_currency": "czk"}'

# Run a single model
dbt run --select ads__campaigns --vars '{"client_name": "my_client"}'

# Compile SQL without executing
dbt compile --select model_name --vars '{"client_name": "my_client"}'
```

Optional variables: `ads_database`, `exchange_database` (override `target.database` for source/FX data locations). Feature flags: `ads__glami_ads_enabled`, `ads__google_ads_enabled`, `ads__meta_ads_enabled`, `ads__seznam_ads_enabled` (all default `true`).

## Architecture

**Data flow:** Raw BigQuery tables → Sources (views) → Intermediate (ephemeral) → Marts (tables)

### Model Layers

- **`models/sources/`** — One subfolder per platform. Cleans, renames, and normalizes raw DLT-loaded tables. Generates surrogate keys, normalizes costs (e.g., Google micros ÷ 1M, Sklik ÷ 100). Materialized as **views** in `ads_sources` schema.
- **`models/sources/util/`** — Exchange rates source, materialized as **ephemeral**.
- **`models/intermediate/`** — `int_unioned_ads` unions all enabled ad platform sources via `dbt_utils.union_relations` and applies currency conversion. `int_sources_exchanged` converts GA4 revenue. Both **ephemeral**.
- **`models/marts/`** — `ads__campaigns` (campaign-level: ads LEFT JOIN GA4 sessions) and `ads__sources` (source-medium-level: GA4 LEFT JOIN ad costs). Materialized as **tables** in `ads` schema.

### Sources

All source schemas are dynamic: `{{ var('client_name') ~ '_platform_name' }}`. Database is configurable via `ads_database` / `exchange_database` variables.

### Key Dependencies

- **`dbt_utils`** (v1.3.x) — `generate_surrogate_key`, `union_relations`
- **`evidy_dbt_utils`** (from `github.com/evidycz/evidy-dbt-utils`) — `convert_currency` (FX case expression), `clean_url_domain` (regex URL normalization)

## Semantic Layer (Lightdash)

Every mart model has a semantic layer definition designed for **Lightdash** and **dbt 1.10+**. Definitions live in the mart YAML files (`models/marts/ads__campaigns.yml`, `models/marts/ads__sources.yml`).

The dbt 1.10+ syntax uses `config.meta` nesting for dimensions, metrics, and table configuration:

```yaml
columns:
  - name: cost
    config:
      meta:
        dimension:
          label: "Ad Spend"
          description: "Total cost in reporting currency"
        metrics:
          total_cost:
            type: sum
```

Reference docs:
- [Dimensions](https://docs.lightdash.com/get-started/develop-in-lightdash/how-to-create-dimensions#dbt-v1-10%2B-and-fusion-2)
- [Metrics](https://docs.lightdash.com/get-started/develop-in-lightdash/how-to-create-metrics#dbt-v1-10%2B)
- [Table configuration](https://docs.lightdash.com/get-started/develop-in-lightdash/adding-tables-to-lightdash)

## Adapters

- **BigQuery** (`dbt-bigquery`) — primary/production
- **DuckDB** (`dbt-duckdb`) — secondary/development

## CI/CD

GitHub Actions (`.github/workflows/dbt_release.yml`): on PR merge to `main`, extracts version from `dbt_project.yml` and creates a GitHub Release if the tag doesn't exist yet. No automated dbt run/test/lint in CI.

## SQL Style Guide

- **Lowercase keywords** — `select`, `from`, `with`, `left join`, `as`, `on`, `and`, `coalesce`, `round`, `cast`, `sum`, etc.
- **4-space indentation** for all nested content
- **CTE-based structure** — every model uses `with` + named CTEs, ending with `select * from final_cte`
- **CTE opening parenthesis** on the same line as the CTE name: `cte_name as (`
- **`with` on its own line**, no leading CTE comma — first CTE follows on the next line
- **Trailing commas** in `select` lists and CTE definitions (comma after closing parenthesis)
- **Blank lines** to separate logical column groups within a `select`
- **JOIN formatting** — `left join` on its own line, `on` indented once (4 spaces), additional conditions with `and` aligned under `on`
- **Final select** — `select * from final_cte` on its own line, no trailing newline required
- **Jinja** — no spaces inside `{{ }}` for expressions (e.g., `{{ ref('model') }}`), `{{ config(...) }}` at top of file when used

Example pattern:

```sql
with
source as (
    select *
    from {{ source('platform', 'table') }}
),

renamed as (
    select
        date_start as date_day,

        {{ dbt_utils.generate_surrogate_key(["col1", "col2"]) }} as row_key,

        upper(config_group) as key_name,
        lower(source_medium) as source_medium,

        coalesce(impressions, 0) as impressions,
        coalesce(clicks, 0) as clicks,
        round(cast(coalesce(cost, 0.0) as numeric), 2) as cost
    from source
)

select * from renamed
```

## Conventions

- Python 3.13, managed with `uv` (not pip/poetry)
- Version is tracked in `dbt_project.yml` (canonical) and `pyproject.toml`
- No `profiles.yml` in repo — lives in `~/.dbt/profiles.yml`
- No tests, linting, or pre-commit hooks are currently configured
- Project macros live in the external `evidy_dbt_utils` package, not in a local `macros/` directory

# Online Marketing dbt Project

This dbt project (`evidy_dbt_online_ads`) transforms raw online marketing data from various platforms into analytics-ready data marts.

## Project Overview

The project follows a standard dbt architecture:
- **Sources**: Cleaned up views of raw marketing data (Google Ads, Meta Ads, Sklik, Glami, GA4).
- **Intermediate**: Common transformations, unioning data from different sources, and currency conversions.
- **Marts**: Final, stable tables designed for reporting and analysis.

### Key Data Marts
- `ads__campaigns`: Aggregated campaign-level performance data across all platforms.
- `ads__sources`: Source-level performance and attribution data.

## Configuration

### Project Variables
The project uses the following variables defined in `dbt_project.yml`:
- `reporting_currency`: Currency used for financial reporting (default: `czk`).
- `client_name`: Identifier for the client (default: `default-client`).

### Materialization Strategy
- **Marts**: Materialized as `table` in the `ads` schema.
- **Intermediate**: Materialized as `ephemeral` in the `ads_intermediate` schema.
- **Sources**: Materialized as `view` in the `ads_sources` schema (utility sources are `ephemeral`).

## Getting Started

### Prerequisites
- dbt Core installed.

### Installation
1. Clone the repository.
2. Install dependencies:
   ```bash
   dbt deps
   ```

### Running the Project
- Run all models:
  ```bash
  dbt run
  ```
- Run tests:
  ```bash
  dbt test
  ```

## Dependencies
- `dbt-labs/dbt_utils`
- `evidy-dbt-utils` (custom internal utilities)

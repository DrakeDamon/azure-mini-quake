# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DBT (Data Build Tool) project for analyzing earthquake data stored in Databricks. The project connects to a Databricks cluster and processes earthquake data from a Silver layer into Gold layer analytics tables.

## Architecture

### Data Flow
- **Source**: `quakes_src.silver_earthquakes` - Clean/typed earthquake data from Silver layer in Databricks
- **Gold Layer Models**:
  - `eq_daily_metrics` - Daily earthquake counts and average magnitude grouped by magnitude buckets
  - `eq_top100` - Top 100 strongest earthquake events

### Directory Structure
- `quakes_dbt/` - Main DBT project directory
  - `models/` - SQL transformation models
    - `sources.yml` - Source table definitions
    - `gold/` - Gold layer models (materialized as tables)
  - `dbt_project.yml` - DBT project configuration
  - `run_with_env.sh` - Environment setup script
  - `.env.example` - Template for environment variables

## Environment Setup

The project uses a custom environment setup script that handles:
- Azure Service Principal authentication
- Databricks connection configuration  
- Environment variable mapping for backward compatibility
- TLS certificate configuration for macOS

### Required Environment Variables
Copy `.env.example` to `.env` and configure:
- `DBX_HOST` - Databricks workspace hostname
- `DBX_HTTP_PATH` - Databricks cluster HTTP path
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_CLIENT_ID` - Azure service principal client ID
- `AZURE_CLIENT_SECRET` - Azure service principal secret
- `DBX_CATALOG` - Target catalog (default: hive_metastore)
- `DBX_SCHEMA` - Target schema (default: quakes)

## Common Commands

All DBT commands should be run through the environment setup script:

```bash
cd quakes_dbt

# Run all models
./run_with_env.sh run

# Run specific model
./run_with_env.sh run --select eq_daily_metrics

# Test data quality
./run_with_env.sh test

# Build everything (run + test)
./run_with_env.sh build

# Generate documentation
./run_with_env.sh docs generate
./run_with_env.sh docs serve

# Debug connection
./run_with_env.sh debug

# Parse project without running
./run_with_env.sh parse

# Compile SQL without executing
./run_with_env.sh compile
```

## Data Model Details

### Magnitude Buckets
The `eq_daily_metrics` model categorizes earthquakes into magnitude buckets:
- "M<3.0" - Minor earthquakes
- "M3.0-3.9" - Light earthquakes  
- "M4.0-4.9" - Moderate earthquakes
- "M5.0-5.9" - Strong earthquakes
- "M6.0-6.9" - Major earthquakes
- "M>=7.0" - Great earthquakes

### Source Data Schema
The Silver layer earthquake data includes:
- `event_time` - Timestamp of earthquake occurrence
- `event_date` - Date extracted from event_time
- `mag` - Earthquake magnitude
- `place` - Location description
- `lat`, `lon` - Coordinates
- `depth_km` - Earthquake depth in kilometers

## Connection Details

This project uses:
- **Adapter**: databricks
- **Authentication**: Azure Service Principal OAuth
- **Target**: Databricks cluster (not SQL Warehouse)
- **Metastore**: Hive Metastore format

The `run_with_env.sh` script handles environment variable mapping and ensures clean authentication by unsetting conflicting variables.

## GitHub Actions Automation

The repository includes a GitHub Actions workflow (`.github/workflows/dbt.yml`) that automatically:
- Runs on pushes to main branch and daily at 06:30 UTC
- Installs dbt-databricks and dependencies
- Executes `dbt debug`, `dbt run`, and `dbt test`
- Uses the same Azure Service Principal authentication as local development

### Required GitHub Secrets
Configure these repository secrets in GitHub Settings → Secrets and variables → Actions:
- `DBX_HOST` - Databricks workspace hostname
- `DBX_HTTP_PATH` - Databricks cluster HTTP path  
- `DBX_CATALOG` - Target catalog (hive_metastore)
- `DBX_SCHEMA` - Target schema (quakes)
- `AZURE_TENANT_ID` - Azure tenant ID
- `AZURE_CLIENT_ID` - Azure service principal client ID
- `AZURE_CLIENT_SECRET` - Azure service principal secret
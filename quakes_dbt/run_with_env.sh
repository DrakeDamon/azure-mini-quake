#!/usr/bin/env bash
set -euo pipefail

# Load .env (if present) into environment without printing values
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

# Back-compat/env mapping for alternate variable names
# Map DATABRICKS_URL -> DBX_HOST (strip scheme)
if [ -z "${DBX_HOST:-}" ] && [ -n "${DATABRICKS_URL:-}" ]; then
  _host="${DATABRICKS_URL#https://}"
  _host="${_host#http://}"
  export DBX_HOST="${_host%%/}"
fi
# Map Azure SP vars if alternative names are used
if [ -z "${AZURE_TENANT_ID:-}" ] && [ -n "${TENANT_ID:-}" ]; then
  export AZURE_TENANT_ID="${TENANT_ID}"
fi
if [ -z "${AZURE_CLIENT_ID:-}" ] && [ -n "${CLIENT_ID:-}" ]; then
  export AZURE_CLIENT_ID="${CLIENT_ID}"
fi
if [ -z "${AZURE_CLIENT_SECRET:-}" ] && [ -n "${CLIENT_SECRET:-}" ]; then
  export AZURE_CLIENT_SECRET="${CLIENT_SECRET}"
fi

exec dbt "$@"

#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

# activate virtual environment
source ../.venv/bin/activate

# load .env
set -a
source .env
set +a

# hard-unset anything that could override SP auth
unset DATABRICKS_TOKEN || true
unset DATABRICKS_HOST || true
unset DATABRICKS_HTTP_PATH || true
unset DATABRICKS_CONFIG_FILE || true
unset DATABRICKS_CFG_PATH || true

# explicitly set auth method for databricks-sql-connector
export DATABRICKS_AUTH_TYPE=azure-service-principal
export DATABRICKS_AZURE_TENANT_ID="${AZURE_TENANT_ID}"
export DATABRICKS_AZURE_CLIENT_ID="${AZURE_CLIENT_ID}"
export DATABRICKS_AZURE_CLIENT_SECRET="${AZURE_CLIENT_SECRET}"

# use certifi CA bundle to avoid macOS SSL chain issues
export REQUESTS_CA_BUNDLE="$(python -c 'import certifi; print(certifi.where())')"
export SSL_CERT_FILE="$REQUESTS_CA_BUNDLE"

# (optional) echo what dbt will see
env | egrep 'DBX_|AZURE_|DATABRICKS' || true

dbt "$@"

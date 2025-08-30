#!/usr/bin/env bash
set -euo pipefail

# Load .env (if present) into environment without printing values
if [ -f .env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./.env
  set +a
fi

exec dbt "$@"

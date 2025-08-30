#!/usr/bin/env bash
set -euo pipefail

# Load .env (if present) into environment without printing values
if [ -f .env ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' .env | xargs -0 -I {} bash -c 'echo {}' 2>/dev/null || true)
fi

exec dbt "$@"


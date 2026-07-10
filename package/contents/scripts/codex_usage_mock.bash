#!/usr/bin/env bash
# Mock version of codex_usage.bash for testing without codex installed.
# Outputs the same JSON format using data from test_run.txt.
set -Eeuo pipefail

cat <<'JSON'
{
    "primary_used_percent": 100,
    "primary_window_minutes": 300,
    "primary_resets_at": 1783727503,
    "secondary_used_percent": 16,
    "secondary_window_minutes": 10080,
    "secondary_resets_at": 1784314303,
    "plan_type": "plus",
    "rate_limit_reached": "rate_limit_reached",
    "credits_balance": "411.5208125000",
    "credits_unlimited": false
}
JSON

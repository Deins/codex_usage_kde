#!/usr/bin/env bash
set -Eeuo pipefail

# Extract just the JSON rate-limit data from the codex app-server.
# The output is a single JSON object on stdout, all logs go to stderr.
#
# Override the codex binary path with the CODEX_BIN environment variable:
#   CODEX_BIN=/path/to/codex bash codex_usage.bash

TIMEOUT_SECONDS=30

CODEX_BIN="${CODEX_BIN:-codex}"

for command_name in "$CODEX_BIN" jq; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        if [[ "$command_name" == "$CODEX_BIN" ]]; then
            echo "Error: codex binary not found: '$CODEX_BIN'" >&2
        else
            echo "Error: '$command_name' is not installed." >&2
        fi
        exit 1
    fi
done

coproc CODEX_SERVER {
    "$CODEX_BIN" app-server --listen stdio://
}

server_pid=$CODEX_SERVER_PID

exec {server_out}<&"${CODEX_SERVER[0]}"
exec {server_in}>&"${CODEX_SERVER[1]}"

cleanup() {
    exec {server_in}>&- 2>/dev/null || true
    exec {server_out}<&- 2>/dev/null || true
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
}

trap cleanup EXIT INT TERM

send_json() {
    local message=$1
    local compact

    if ! compact=$(jq -c . <<<"$message"); then
        echo "Error: invalid JSON request:" >&2
        echo "$message" >&2
        exit 1
    fi

    printf '%s\n' "$compact" >&"$server_in"
}

wait_for_id() {
    local wanted_id=$1
    local line

    while true; do
        if ! IFS= read -r -t "$TIMEOUT_SECONDS" line <&"$server_out"; then
            echo "Error: timed out waiting for response id=$wanted_id." >&2
            echo "Make sure Codex is logged in by running: $CODEX_BIN login" >&2
            exit 1
        fi

        if ! jq -e . >/dev/null 2>&1 <<<"$line"; then
            continue
        fi

        if ! jq -e --argjson id "$wanted_id" '.id == $id' \
            >/dev/null 2>&1 <<<"$line"; then
            continue
        fi

        if jq -e '.error != null' >/dev/null 2>&1 <<<"$line"; then
            echo "Codex App Server returned an error:" >&2
            jq '.error' <<<"$line" >&2
            exit 1
        fi

        printf '%s\n' "$line"
        return 0
    done
}

# Initialize the App Server.
send_json '{
    "method": "initialize",
    "id": 1,
    "params": {
        "clientInfo": {
            "name": "kde_codex_usage_widget",
            "title": "KDE Codex Usage Widget",
            "version": "0.1.0"
        }
    }
}'

wait_for_id 1 >/dev/null

# Finish the initialization handshake.
send_json '{
    "method": "initialized",
    "params": {}
}'

# Request Codex usage limits.
send_json '{
    "method": "account/rateLimits/read",
    "id": 2
}'

response=$(wait_for_id 2)

# Output compact JSON with just the fields the widget needs.
jq -c '{
    primary_used_percent: .result.rateLimits.primary.usedPercent,
    primary_window_minutes: .result.rateLimits.primary.windowDurationMins,
    primary_resets_at: .result.rateLimits.primary.resetsAt,
    secondary_used_percent: .result.rateLimits.secondary.usedPercent,
    secondary_window_minutes: .result.rateLimits.secondary.windowDurationMins,
    secondary_resets_at: .result.rateLimits.secondary.resetsAt,
    plan_type: .result.rateLimits.planType,
    rate_limit_reached: .result.rateLimits.rateLimitReachedType,
    credits_balance: .result.rateLimits.credits.balance,
    credits_unlimited: .result.rateLimits.credits.unlimited
}' <<<"$response"

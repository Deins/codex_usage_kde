#!/usr/bin/env bash
set -Eeuo pipefail

# Fetch the JSON-RPC response from the Codex app-server. Plasma's QML runtime
# parses and reshapes the JSON, so no external JSON utility is required.

TIMEOUT_SECONDS=30
CODEX_BIN="${CODEX_BIN:-codex}"

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
    echo "Error: codex binary not found: '$CODEX_BIN'" >&2
    exit 1
fi

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

wait_for_id() {
    local wanted_id=$1
    local line
    local id_pattern='"id"[[:space:]]*:[[:space:]]*'"$wanted_id"'([^0-9]|$)'

    while true; do
        if ! IFS= read -r -t "$TIMEOUT_SECONDS" line <&"$server_out"; then
            echo "Error: timed out waiting for response id=$wanted_id." >&2
            echo "Make sure Codex is logged in by running: $CODEX_BIN login" >&2
            exit 1
        fi

        if ! [[ "$line" =~ $id_pattern ]]; then
            continue
        fi
        if [[ "$line" =~ \"error\"[[:space:]]*:[[:space:]]*[^n] ]]; then
            echo "Codex App Server returned an error:" >&2
            echo "$line" >&2
            exit 1
        fi

        printf '%s\n' "$line"
        return 0
    done
}

printf '%s\n' '{"method":"initialize","id":1,"params":{"clientInfo":{"name":"kde_codex_usage_widget","title":"KDE Codex Usage Widget","version":"0.1.0"}}}' >&"$server_in"
wait_for_id 1 >/dev/null

printf '%s\n' '{"method":"initialized","params":{}}' >&"$server_in"
printf '%s\n' '{"method":"account/rateLimits/read","id":2}' >&"$server_in"

# Return the unmodified response for QML's built-in JSON parser.
wait_for_id 2

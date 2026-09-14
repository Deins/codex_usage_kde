#!/usr/bin/env bash
set -Eeuo pipefail

TIMEOUT_SECONDS=30
CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/codex-usage/codex-path"
CODEX_BIN="${CODEX_BIN:-}"

if [[ -z "$CODEX_BIN" && -r "$CONFIG_FILE" ]]; then
    IFS= read -r CODEX_BIN < "$CONFIG_FILE"
fi
CODEX_BIN="${CODEX_BIN:-codex}"

if ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
    echo "Codex binary not found: $CODEX_BIN" >&2
    echo "Put its full path in $CONFIG_FILE" >&2
    exit 1
fi

coproc CODEX_SERVER { "$CODEX_BIN" app-server --listen stdio://; }
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
    local wanted_id=$1 line
    local id_pattern='"id"[[:space:]]*:[[:space:]]*'"$wanted_id"'([^0-9]|$)'

    while IFS= read -r -t "$TIMEOUT_SECONDS" line <&"$server_out"; do
        [[ "$line" =~ $id_pattern ]] || continue
        printf '%s\n' "$line"
        return
    done

    echo "Timed out waiting for Codex response id=$wanted_id" >&2
    exit 1
}

printf '%s\n' '{"method":"initialize","id":1,"params":{"clientInfo":{"name":"gnome_codex_usage_widget","title":"GNOME Codex Usage Widget","version":"0.1.0"}}}' >&"$server_in"
wait_for_id 1 >/dev/null
printf '%s\n' '{"method":"initialized","params":{}}' >&"$server_in"
printf '%s\n' '{"method":"account/rateLimits/read","id":2}' >&"$server_in"
wait_for_id 2

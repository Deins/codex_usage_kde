#!/usr/bin/env bash
set -Eeuo pipefail

TIMEOUT_SECONDS=15

for command_name in codex jq; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Error: '$command_name' is not installed." >&2
        exit 1
    fi
done

echo "Codex version: $(codex --version)" >&2
echo "Starting codex app-server…" >&2

coproc CODEX_SERVER {
    codex app-server --listen stdio://
}

server_pid=$CODEX_SERVER_PID

# Duplicate the coprocess file descriptors.
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

    # codex app-server uses JSONL:
    # every request must be one complete JSON object on one line.
    if ! compact=$(jq -c . <<<"$message"); then
        echo "Error: invalid JSON request:" >&2
        echo "$message" >&2
        exit 1
    fi

    echo "→ $compact" >&2

    if ! printf '%s\n' "$compact" >&"$server_in"; then
        echo "Error: failed to write to codex app-server." >&2
        exit 1
    fi
}

wait_for_id() {
    local wanted_id=$1
    local line

    while true; do
        if ! IFS= read -r -t "$TIMEOUT_SECONDS" line <&"$server_out"; then
            echo "Error: timed out waiting for response id=$wanted_id." >&2
            echo "Make sure Codex is logged in by running: codex login" >&2
            exit 1
        fi

        echo "← $line" >&2

        # Ignore non-JSON lines.
        if ! jq -e . >/dev/null 2>&1 <<<"$line"; then
            continue
        fi

        # Ignore notifications and responses with a different ID.
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
            "name": "kde_codex_usage_test",
            "title": "KDE Codex Usage Test",
            "version": "0.1.0"
        }
    }
}'

wait_for_id 1 >/dev/null
echo "Initialization succeeded." >&2

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

echo
echo "Raw response:"
jq . <<<"$response"

echo
echo "Formatted usage:"

jq '
    .result as $result
    | (
        $result.rateLimitsByLimitId
        // (
            if $result.rateLimits then
                {
                    ($result.rateLimits.limitId // "codex"):
                    $result.rateLimits
                }
            else
                {}
            end
        )
    )
    | to_entries
    | if length == 0 then
        error("No rate-limit information was returned")
      else
        map({
            id: .key,
            name: (.value.limitName // .key),

            primary: (
                if .value.primary then
                    {
                        used_percent:
                            .value.primary.usedPercent,

                        remaining_percent:
                            (100 - .value.primary.usedPercent),

                        window_minutes:
                            .value.primary.windowDurationMins,

                        resets_at_unix:
                            .value.primary.resetsAt,

                        resets_at_utc:
                            (
                                if .value.primary.resetsAt then
                                    (
                                        .value.primary.resetsAt
                                        | strftime("%Y-%m-%d %H:%M:%S UTC")
                                    )
                                else
                                    null
                                end
                            )
                    }
                else
                    null
                end
            ),

            secondary: (
                if .value.secondary then
                    {
                        used_percent:
                            .value.secondary.usedPercent,

                        remaining_percent:
                            (100 - .value.secondary.usedPercent),

                        window_minutes:
                            .value.secondary.windowDurationMins,

                        resets_at_unix:
                            .value.secondary.resetsAt,

                        resets_at_utc:
                            (
                                if .value.secondary.resetsAt then
                                    (
                                        .value.secondary.resetsAt
                                        | strftime("%Y-%m-%d %H:%M:%S UTC")
                                    )
                                else
                                    null
                                end
                            )
                    }
                else
                    null
                end
            ),

            credits:
                (.value.credits // null),

            reached_limit:
                (.value.rateLimitReachedType // null)
        })
      end
' <<<"$response"

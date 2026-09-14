#!/usr/bin/env bash
set -Eeuo pipefail

UUID=codex-usage@dee.github.com
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"

if (( $# > 1 )); then
    echo "Usage: $0 [codex-binary]" >&2
    exit 2
fi
if (( $# == 1 )); then
    [[ -x "$1" ]] || { echo "Not executable: $1" >&2; exit 2; }
    CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/codex-usage/codex-path"
    mkdir -p "$(dirname "$CONFIG_FILE")"
    printf '%s\n' "$1" > "$CONFIG_FILE"
fi

mkdir -p "$(dirname "$INSTALL_DIR")"
ln -sfnT "$SOURCE_DIR" "$INSTALL_DIR"

echo "Installed $UUID"
echo "Log out and back in, then run: gnome-extensions enable $UUID"

#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$REPO_DIR/package"
INSTALL_DIR="${HOME}/.local/share/plasma/plasmoids/com.github.codex.usage"

echo "Installing Codex Usage widget…"
echo "  Source:  $PKG_DIR"
echo "  Target:  $INSTALL_DIR"

mkdir -p "$(dirname "$INSTALL_DIR")"

if [[ -d "$INSTALL_DIR" || -L "$INSTALL_DIR" ]]; then
    echo "  Removing existing installation…"
    rm -rf "$INSTALL_DIR"
fi

ln -s "$PKG_DIR" "$INSTALL_DIR"
echo "  Symlinked."

echo
echo "Done. To test:"
echo "  plasmawindowed com.github.codex.usage"
echo
echo "To apply changes after editing QML:"
echo "  systemctl --user restart plasma-plasmashell"
echo
echo "To add the widget to your panel/desktop:"
echo "  Right-click panel → Add Widgets → search 'Codex Usage'"

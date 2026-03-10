#!/usr/bin/env bash
# GravitySwitch Installer — macOS
set -euo pipefail

GITHUB_USER="YOUR_GITHUB_USERNAME"
GITHUB_REPO="GravitySwitch"
BRANCH="main"
SCRIPT_NAME="gravityswitch"
RAW_URL="https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/$SCRIPT_NAME"

INSTALL_DIR="/usr/local/bin"
# Fallback if no write permission
if [[ ! -w "$INSTALL_DIR" ]]; then
    INSTALL_DIR="$HOME/.local/bin"
    mkdir -p "$INSTALL_DIR"
    if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
        echo "  ⚠ Add this to your ~/.zshrc or ~/.bashrc:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo ""
    fi
fi

echo ""
echo "  ┌──────────────────────────────────────────┐"
echo "  │   GravitySwitch — Installer (macOS)       │"
echo "  └──────────────────────────────────────────┘"
echo ""

echo "  → Downloading gravityswitch..."
curl -fsSL "$RAW_URL" -o "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

echo "  ✓ Installed to: $INSTALL_DIR/$SCRIPT_NAME"
echo ""
echo "  ✅ Done! Quick start:"
echo ""
echo "    gravityswitch new work"
echo "    gravityswitch new personal"
echo "    gravityswitch launch work"
echo "    gravityswitch help"
echo ""

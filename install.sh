#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-z"
CONFIG_FILE="$CONFIG_DIR/config"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ┌─────────────────────────────────┐"
echo "  │  claude-z installer             │"
echo "  │  Claude Code + Z.ai provider    │"
echo "  └─────────────────────────────────┘"
echo ""

# Check claude is installed
if ! command -v claude &>/dev/null; then
  echo "  Claude Code is not installed."
  echo "  Install it first: https://docs.anthropic.com/en/docs/claude-code"
  echo ""
  exit 1
fi

claude_ver=$(claude --version 2>/dev/null || echo "unknown")
echo "  Found Claude Code: $claude_ver"
echo ""

# --- Setup wizard ---

# 1. API key
echo "  Get your Z.ai API key at: https://z.ai/manage-apikey/apikey-list"
echo ""
read -rp "  Z.ai API key: " api_key
if [[ -z "$api_key" ]]; then
  echo "  Error: API key is required." >&2
  exit 1
fi

# 2. Permission mode
echo ""
echo "  Permission mode:"
echo "    1) normal           — ask before each action (safest)"
echo "    2) acceptEdits      — auto-accept file edits, ask for commands"
echo "    3) dangerously-skip — skip all permission prompts (fastest)"
echo ""
read -rp "  Choose [1/2/3] (default: 1): " mode_choice
case "${mode_choice:-1}" in
  1) perm_mode="normal" ;;
  2) perm_mode="acceptEdits" ;;
  3) perm_mode="dangerously-skip-permissions" ;;
  *) echo "  Invalid choice, using 'normal'"; perm_mode="normal" ;;
esac

# 3. Max tokens
echo ""
read -rp "  Max output tokens (enter to skip, e.g. 64000): " max_tokens

# --- Save config ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<CONF
ZAI_API_KEY="$api_key"
ZAI_PERMISSION_MODE="$perm_mode"
ZAI_MAX_TOKENS="$max_tokens"
CONF
chmod 600 "$CONFIG_FILE"

# --- Install script ---
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/claude-z.sh" "$INSTALL_DIR/claude-z"
chmod +x "$INSTALL_DIR/claude-z"

# Check PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo ""
  echo "  WARNING: $INSTALL_DIR is not in your PATH."
  echo "  Add this to your ~/.bashrc or ~/.zshrc:"
  echo ""
  echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo ""
fi

echo ""
echo "  ────────────────────────────────────"
echo "  Done! claude-z is ready to use."
echo ""
echo "  Usage:"
echo "    claude-z                — start Claude Code via Z.ai"
echo "    claude-z reconfig       — change settings"
echo "    claude-z -p \"prompt\"    — one-shot query"
echo ""
echo "  Config: $CONFIG_FILE"
echo "  Binary: $INSTALL_DIR/claude-z"
echo "  ────────────────────────────────────"
echo ""

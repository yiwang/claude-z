#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-o"
CONFIG_FILE="$CONFIG_DIR/config"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ┌─────────────────────────────────┐"
echo "  │  claude-o installer             │"
echo "  │  Claude Code + OpenRouter       │"
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
echo "  Get your OpenRouter API key at: https://openrouter.ai/settings/keys"
echo ""
read -rp "  API key: " api_key
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

# 3. Model
echo ""
echo "  Model for opus/sonnet slot (OpenRouter model ID)."
echo "  Browse: https://openrouter.ai/models"
echo ""
read -rp "  Model ID: " or_model
if [[ -z "$or_model" ]]; then
  echo "  Error: model ID is required." >&2
  exit 1
fi
model_opus="$or_model"
model_sonnet="$or_model"
echo ""
read -rp "  Haiku (light) model ID (enter to use same): " or_haiku
model_haiku="${or_haiku:-$or_model}"

# 4. Max tokens
echo ""
read -rp "  Max output tokens (enter to skip, e.g. 64000): " max_tokens

# --- Save config ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<CONF
CO_API_KEY="$api_key"
CO_PERMISSION_MODE="$perm_mode"
CO_MODEL_OPUS="$model_opus"
CO_MODEL_SONNET="$model_sonnet"
CO_MODEL_HAIKU="$model_haiku"
CO_MAX_TOKENS="$max_tokens"
CONF
chmod 600 "$CONFIG_FILE"

# --- Install script ---
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/claude-o.sh" "$INSTALL_DIR/claude-o"
chmod +x "$INSTALL_DIR/claude-o"

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
echo "  Done! claude-o is ready (OpenRouter)."
echo ""
echo "  Usage:"
echo "    claude-o                — start Claude Code via OpenRouter"
echo "    claude-o reconfig       — change settings"
echo "    claude-o -p \"prompt\"    — one-shot query"
echo ""
echo "  Config: $CONFIG_FILE"
echo "  Binary: $INSTALL_DIR/claude-o"
echo "  ────────────────────────────────────"
echo ""

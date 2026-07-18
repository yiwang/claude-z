#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-k"
CONFIG_FILE="$CONFIG_DIR/config"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ┌─────────────────────────────────┐"
echo "  │  claude-k installer             │"
echo "  │  Claude Code + Kimi             │"
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
echo "  Get your Kimi API key at: Kimi Code Console (https://www.kimi.com/code) — Create API Key"
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
echo "  Model:"
echo "    1) k3[1m]                  — K3, 1M context (Allegretto and above) (default)"
echo "    2) k3                      — K3, 256k context (Moderato and above)"
echo "    3) kimi-for-coding         — K2.7 Code, 256k context (all plans)"
echo "    4) kimi-for-coding-highspeed — K2.7 Code, ~5-6x faster (Allegretto and above)"
echo ""
read -rp "  Choose [1/2/3/4] (default: 1): " model_choice
case "${model_choice:-1}" in
  1) model="k3[1m]" ;;
  2) model="k3" ;;
  3) model="kimi-for-coding" ;;
  4) model="kimi-for-coding-highspeed" ;;
  *) echo "  Invalid choice, using k3[1m]"; model="k3[1m]" ;;
esac

# 4. Max tokens
echo ""
read -rp "  Max output tokens (enter to skip, e.g. 64000): " max_tokens

# --- Save config ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<CONF
CK_API_KEY="$api_key"
CK_PERMISSION_MODE="$perm_mode"
CK_MODEL="$model"
CK_MAX_TOKENS="$max_tokens"
CONF
chmod 600 "$CONFIG_FILE"

# --- Install script ---
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/claude-k.sh" "$INSTALL_DIR/claude-k"
chmod +x "$INSTALL_DIR/claude-k"

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
echo "  Done! claude-k is ready (Kimi)."
echo ""
echo "  Usage:"
echo "    claude-k                — start Claude Code via Kimi"
echo "    claude-k reconfig       — change settings"
echo "    claude-k -p \"prompt\"    — one-shot query"
echo ""
echo "  Config: $CONFIG_FILE"
echo "  Binary: $INSTALL_DIR/claude-k"
echo "  ────────────────────────────────────"
echo ""

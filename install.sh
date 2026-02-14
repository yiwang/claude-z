#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-z"
CONFIG_FILE="$CONFIG_DIR/config"
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ┌─────────────────────────────────┐"
echo "  │  claude-z installer             │"
echo "  │  Claude Code + custom provider  │"
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

# 1. Provider
echo "  Provider:"
echo "    1) Z.ai       — GLM models, from \$6/mo"
echo "    2) OpenRouter  — 400+ models, pay-per-token"
echo ""
read -rp "  Choose [1/2] (default: 1): " provider_choice
case "${provider_choice:-1}" in
  1) provider="zai" ;;
  2) provider="openrouter" ;;
  *) echo "  Invalid choice, using Z.ai"; provider="zai" ;;
esac

# 2. API key
echo ""
if [[ "$provider" == "zai" ]]; then
  echo "  Get your Z.ai API key at: https://z.ai/manage-apikey/apikey-list"
else
  echo "  Get your OpenRouter API key at: https://openrouter.ai/settings/keys"
fi
echo ""
read -rp "  API key: " api_key
if [[ -z "$api_key" ]]; then
  echo "  Error: API key is required." >&2
  exit 1
fi

# 3. Permission mode
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

# 4. Model
echo ""
if [[ "$provider" == "zai" ]]; then
  echo "  Base model:"
  echo "    1) glm-5        — flagship, best quality (Max plan only)"
  echo "    2) glm-4.7      — fast, great for coding (default)"
  echo "    3) glm-4.5      — hybrid reasoning, thinking mode"
  echo "    4) glm-4.5-air  — lightweight, cheapest"
  echo ""
  read -rp "  Choose [1/2/3/4] (default: 2): " model_choice
  case "${model_choice:-2}" in
    1) model_opus="glm-5";       model_sonnet="glm-5";       model_haiku="glm-4.5-air" ;;
    2) model_opus="glm-4.7";     model_sonnet="glm-4.7";     model_haiku="glm-4.5-air" ;;
    3) model_opus="glm-4.5";     model_sonnet="glm-4.5";     model_haiku="glm-4.5-air" ;;
    4) model_opus="glm-4.5-air"; model_sonnet="glm-4.5-air"; model_haiku="glm-4.5-air" ;;
    *) echo "  Invalid choice, using glm-4.7"; model_opus="glm-4.7"; model_sonnet="glm-4.7"; model_haiku="glm-4.5-air" ;;
  esac
else
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
fi

# 5. Max tokens
echo ""
read -rp "  Max output tokens (enter to skip, e.g. 64000): " max_tokens

# --- Save config ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_FILE" <<CONF
CZ_PROVIDER="$provider"
CZ_API_KEY="$api_key"
CZ_PERMISSION_MODE="$perm_mode"
CZ_MODEL_OPUS="$model_opus"
CZ_MODEL_SONNET="$model_sonnet"
CZ_MODEL_HAIKU="$model_haiku"
CZ_MAX_TOKENS="$max_tokens"
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

provider_name="Z.ai"
[[ "$provider" == "openrouter" ]] && provider_name="OpenRouter"

echo ""
echo "  ────────────────────────────────────"
echo "  Done! claude-z is ready ($provider_name)."
echo ""
echo "  Usage:"
echo "    claude-z                — start Claude Code via $provider_name"
echo "    claude-z reconfig       — change settings"
echo "    claude-z -p \"prompt\"    — one-shot query"
echo ""
echo "  Config: $CONFIG_FILE"
echo "  Binary: $INSTALL_DIR/claude-z"
echo "  ────────────────────────────────────"
echo ""

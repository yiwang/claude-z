#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-o"
CONFIG_FILE="$CONFIG_DIR/config"

# --- reconfig ---
if [[ "${1:-}" == "reconfig" ]]; then
  echo ""
  echo "  claude-o reconfig (OpenRouter)"
  echo "  ──────────────────────────────"
  echo ""

  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null

  # API key
  current_key="${CO_API_KEY:-}"
  if [[ -n "$current_key" ]]; then
    masked="${current_key:0:8}...${current_key: -4}"
    echo "  Current API key: $masked"
  fi
  echo "  Get key: https://openrouter.ai/settings/keys"
  read -rp "  API key (enter to keep current): " new_key
  [[ -n "$new_key" ]] && current_key="$new_key"
  if [[ -z "$current_key" ]]; then
    echo "  Error: API key is required." >&2
    exit 1
  fi

  # Permission mode
  echo ""
  echo "  Permission mode:"
  echo "    1) normal           — ask before each action"
  echo "    2) acceptEdits      — auto-accept file edits, ask for commands"
  echo "    3) dangerously-skip — skip all permission prompts"
  echo ""
  current_mode="${CO_PERMISSION_MODE:-normal}"
  read -rp "  Choose [1/2/3] (enter to keep '$current_mode'): " mode_choice
  case "$mode_choice" in
    1) current_mode="normal" ;;
    2) current_mode="acceptEdits" ;;
    3) current_mode="dangerously-skip-permissions" ;;
    "") ;; # keep current
    *) echo "  Invalid choice, keeping '$current_mode'" ;;
  esac

  # Model
  echo ""
  current_opus="${CO_MODEL_OPUS:-}"
  echo "  Model for opus/sonnet slot (OpenRouter model ID)."
  echo "  Browse: https://openrouter.ai/models"
  echo ""
  read -rp "  Model ID (enter to keep '$current_opus'): " or_model
  [[ -n "$or_model" ]] && current_opus="$or_model"
  if [[ -z "$current_opus" ]]; then
    echo "  Error: model ID is required." >&2
    exit 1
  fi
  current_sonnet="$current_opus"
  echo ""
  current_haiku="${CO_MODEL_HAIKU:-$current_opus}"
  read -rp "  Haiku (light) model (enter to keep '$current_haiku'): " or_haiku
  [[ -n "$or_haiku" ]] && current_haiku="$or_haiku"

  # Max tokens
  echo ""
  current_tokens="${CO_MAX_TOKENS:-}"
  read -rp "  Max output tokens [enter to skip, e.g. 64000]: " new_tokens
  [[ -n "$new_tokens" ]] && current_tokens="$new_tokens"

  # Save
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<CONF
CO_API_KEY="$current_key"
CO_PERMISSION_MODE="$current_mode"
CO_MODEL_OPUS="$current_opus"
CO_MODEL_SONNET="$current_sonnet"
CO_MODEL_HAIKU="$current_haiku"
CO_MAX_TOKENS="$current_tokens"
CONF
  chmod 600 "$CONFIG_FILE"

  echo ""
  echo "  Config saved. Run 'claude-o' to start."
  echo ""
  exit 0
fi

# --- main: launch claude ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo ""
  echo "  claude-o is not configured yet."
  echo "  Run: claude-o reconfig"
  echo ""
  exit 1
fi

source "$CONFIG_FILE"

if [[ -z "${CO_API_KEY:-}" ]]; then
  echo "  Error: CO_API_KEY is empty. Run: claude-o reconfig" >&2
  exit 1
fi

# Check claude is installed
if ! command -v claude &>/dev/null; then
  echo "  Error: 'claude' not found. Install Claude Code first:" >&2
  echo "  https://docs.anthropic.com/en/docs/claude-code" >&2
  exit 1
fi

export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$CO_API_KEY"
export ANTHROPIC_API_KEY=""

export API_TIMEOUT_MS="3000000"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${CO_MODEL_OPUS:-}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${CO_MODEL_SONNET:-$CO_MODEL_OPUS}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${CO_MODEL_HAIKU:-$CO_MODEL_OPUS}"

if [[ -n "${CO_MAX_TOKENS:-}" ]]; then
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$CO_MAX_TOKENS"
fi

# Build args and exec
if [[ "${CO_PERMISSION_MODE:-normal}" == "dangerously-skip-permissions" ]]; then
  exec claude --dangerously-skip-permissions "$@"
else
  exec claude "$@"
fi

#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-z"
CONFIG_FILE="$CONFIG_DIR/config"

# --- reconfig ---
if [[ "${1:-}" == "reconfig" ]]; then
  echo ""
  echo "  claude-z reconfig (Z.ai)"
  echo "  ────────────────────────"
  echo ""

  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null

  # API key
  current_key="${CZ_API_KEY:-}"
  if [[ -n "$current_key" ]]; then
    masked="${current_key:0:8}...${current_key: -4}"
    echo "  Current API key: $masked"
  fi
  echo "  Get key: https://z.ai/manage-apikey/apikey-list"
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
  current_mode="${CZ_PERMISSION_MODE:-normal}"
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
  echo "  Base model:"
  echo "    1) glm-5.2[1m]  — flagship, 1M context"
  echo "    2) glm-5.2      — flagship, standard context"
  echo "    3) glm-4.7      — fast, great for coding"
  echo "    4) glm-4.5-air  — lightweight, cheapest"
  echo ""
  current_opus="${CZ_MODEL_OPUS:-glm-5.2[1m]}"
  read -rp "  Choose [1/2/3/4] (enter to keep '$current_opus'): " model_choice
  case "$model_choice" in
    1) current_opus="glm-5.2[1m]"; current_sonnet="glm-5.2[1m]"; current_haiku="glm-4.7" ;;
    2) current_opus="glm-5.2";     current_sonnet="glm-5.2";     current_haiku="glm-4.7" ;;
    3) current_opus="glm-4.7";     current_sonnet="glm-4.7";     current_haiku="glm-4.7" ;;
    4) current_opus="glm-4.5-air"; current_sonnet="glm-4.5-air"; current_haiku="glm-4.5-air" ;;
    "") current_sonnet="${CZ_MODEL_SONNET:-$current_opus}"; current_haiku="${CZ_MODEL_HAIKU:-glm-4.7}" ;;
    *) echo "  Invalid, keeping current"; current_sonnet="${CZ_MODEL_SONNET:-$current_opus}"; current_haiku="${CZ_MODEL_HAIKU:-glm-4.7}" ;;
  esac

  # Max tokens
  echo ""
  current_tokens="${CZ_MAX_TOKENS:-}"
  read -rp "  Max output tokens [enter to skip, e.g. 64000]: " new_tokens
  [[ -n "$new_tokens" ]] && current_tokens="$new_tokens"

  # Save
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<CONF
CZ_API_KEY="$current_key"
CZ_PERMISSION_MODE="$current_mode"
CZ_MODEL_OPUS="$current_opus"
CZ_MODEL_SONNET="$current_sonnet"
CZ_MODEL_HAIKU="$current_haiku"
CZ_MAX_TOKENS="$current_tokens"
CONF
  chmod 600 "$CONFIG_FILE"

  echo ""
  echo "  Config saved. Run 'claude-z' to start."
  echo ""
  exit 0
fi

# --- main: launch claude ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo ""
  echo "  claude-z is not configured yet."
  echo "  Run: claude-z reconfig"
  echo ""
  exit 1
fi

source "$CONFIG_FILE"

if [[ -z "${CZ_API_KEY:-}" ]]; then
  echo "  Error: CZ_API_KEY is empty. Run: claude-z reconfig" >&2
  exit 1
fi

# Check claude is installed
if ! command -v claude &>/dev/null; then
  echo "  Error: 'claude' not found. Install Claude Code first:" >&2
  echo "  https://docs.anthropic.com/en/docs/claude-code" >&2
  exit 1
fi

export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export ANTHROPIC_AUTH_TOKEN="$CZ_API_KEY"

export API_TIMEOUT_MS="3000000"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${CZ_MODEL_OPUS:-glm-5.2[1m]}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${CZ_MODEL_SONNET:-glm-5.2[1m]}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${CZ_MODEL_HAIKU:-glm-4.7}"

# Opt into the 1M context window for [1m] model variants
if [[ "${CZ_MODEL_OPUS:-}" == *"[1m]"* ]]; then
  export CLAUDE_CODE_AUTO_COMPACT_WINDOW="1000000"
fi

if [[ -n "${CZ_MAX_TOKENS:-}" ]]; then
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$CZ_MAX_TOKENS"
fi

# Build args and exec
if [[ "${CZ_PERMISSION_MODE:-normal}" == "dangerously-skip-permissions" ]]; then
  exec claude --dangerously-skip-permissions "$@"
else
  exec claude "$@"
fi

#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-z"
CONFIG_FILE="$CONFIG_DIR/config"

# --- reconfig ---
if [[ "${1:-}" == "reconfig" ]]; then
  echo ""
  echo "  claude-z reconfig"
  echo "  ─────────────────"
  echo ""

  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null

  # Provider
  current_provider="${CZ_PROVIDER:-zai}"
  echo "  Provider:"
  echo "    1) Z.ai       — GLM models, from \$6/mo"
  echo "    2) OpenRouter  — 400+ models, pay-per-token"
  echo ""
  read -rp "  Choose [1/2] (enter to keep '$current_provider'): " provider_choice
  case "$provider_choice" in
    1) current_provider="zai" ;;
    2) current_provider="openrouter" ;;
    "") ;; # keep current
    *) echo "  Invalid choice, keeping '$current_provider'" ;;
  esac

  # API key
  echo ""
  current_key="${CZ_API_KEY:-}"
  if [[ -n "$current_key" ]]; then
    masked="${current_key:0:8}...${current_key: -4}"
    echo "  Current API key: $masked"
  fi
  if [[ "$current_provider" == "zai" ]]; then
    echo "  Get key: https://z.ai/manage-apikey/apikey-list"
  else
    echo "  Get key: https://openrouter.ai/settings/keys"
  fi
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
  if [[ "$current_provider" == "zai" ]]; then
    echo "  Base model:"
    echo "    1) glm-5        — flagship, best quality (Max plan only)"
    echo "    2) glm-4.7      — fast, great for coding"
    echo "    3) glm-4.5      — hybrid reasoning, thinking mode"
    echo "    4) glm-4.5-air  — lightweight, cheapest"
    echo ""
    current_opus="${CZ_MODEL_OPUS:-glm-4.7}"
    read -rp "  Choose [1/2/3/4] (enter to keep '$current_opus'): " model_choice
    case "$model_choice" in
      1) current_opus="glm-5";       current_sonnet="glm-5";       current_haiku="glm-4.5-air" ;;
      2) current_opus="glm-4.7";     current_sonnet="glm-4.7";     current_haiku="glm-4.5-air" ;;
      3) current_opus="glm-4.5";     current_sonnet="glm-4.5";     current_haiku="glm-4.5-air" ;;
      4) current_opus="glm-4.5-air"; current_sonnet="glm-4.5-air"; current_haiku="glm-4.5-air" ;;
      "") current_sonnet="${CZ_MODEL_SONNET:-$current_opus}"; current_haiku="${CZ_MODEL_HAIKU:-glm-4.5-air}" ;;
      *) echo "  Invalid, keeping current"; current_sonnet="${CZ_MODEL_SONNET:-$current_opus}"; current_haiku="${CZ_MODEL_HAIKU:-glm-4.5-air}" ;;
    esac
  else
    current_opus="${CZ_MODEL_OPUS:-}"
    echo "  Model for opus/sonnet slot (OpenRouter model ID)."
    echo "  Browse: https://openrouter.ai/models"
    echo ""
    read -rp "  Model ID (enter to keep '$current_opus'): " or_model
    [[ -n "$or_model" ]] && current_opus="$or_model"
    current_sonnet="$current_opus"
    echo ""
    current_haiku="${CZ_MODEL_HAIKU:-$current_opus}"
    read -rp "  Haiku (light) model (enter to keep '$current_haiku'): " or_haiku
    [[ -n "$or_haiku" ]] && current_haiku="$or_haiku"
  fi

  # Max tokens
  echo ""
  current_tokens="${CZ_MAX_TOKENS:-}"
  read -rp "  Max output tokens [enter to skip, e.g. 64000]: " new_tokens
  [[ -n "$new_tokens" ]] && current_tokens="$new_tokens"

  # Save
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<CONF
CZ_PROVIDER="$current_provider"
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

# Build env per provider
case "${CZ_PROVIDER:-zai}" in
  openrouter)
    export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
    export ANTHROPIC_AUTH_TOKEN="$CZ_API_KEY"
    export ANTHROPIC_API_KEY=""
    ;;
  *)
    export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
    export ANTHROPIC_AUTH_TOKEN="$CZ_API_KEY"
    ;;
esac

export API_TIMEOUT_MS="3000000"
export ANTHROPIC_DEFAULT_OPUS_MODEL="${CZ_MODEL_OPUS:-glm-4.7}"
export ANTHROPIC_DEFAULT_SONNET_MODEL="${CZ_MODEL_SONNET:-glm-4.7}"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="${CZ_MODEL_HAIKU:-glm-4.5-air}"

if [[ -n "${CZ_MAX_TOKENS:-}" ]]; then
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$CZ_MAX_TOKENS"
fi

# Build args
claude_args=()
case "${CZ_PERMISSION_MODE:-normal}" in
  dangerously-skip-permissions)
    claude_args+=(--dangerously-skip-permissions)
    ;;
esac

# Pass through user args
claude_args+=("$@")

exec claude "${claude_args[@]}"

#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-z"
CONFIG_FILE="$CONFIG_DIR/config"
SCRIPT_PATH="$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")"

# --- reconfig ---
if [[ "${1:-}" == "reconfig" ]]; then
  echo ""
  echo "  claude-z reconfig"
  echo "  ─────────────────"
  echo ""

  # API key
  current_key=""
  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null && current_key="${ZAI_API_KEY:-}"
  if [[ -n "$current_key" ]]; then
    masked="${current_key:0:8}...${current_key: -4}"
    echo "  Current API key: $masked"
  fi
  read -rp "  Z.ai API key (enter to keep current): " new_key
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
  current_mode="${ZAI_PERMISSION_MODE:-normal}"
  read -rp "  Choose [1/2/3] (enter to keep '$current_mode'): " mode_choice
  case "$mode_choice" in
    1) current_mode="normal" ;;
    2) current_mode="acceptEdits" ;;
    3) current_mode="dangerously-skip-permissions" ;;
    "") ;; # keep current
    *) echo "  Invalid choice, keeping '$current_mode'" ;;
  esac

  # Max tokens
  echo ""
  current_tokens="${ZAI_MAX_TOKENS:-}"
  read -rp "  Max output tokens [enter to skip, e.g. 64000]: " new_tokens
  [[ -n "$new_tokens" ]] && current_tokens="$new_tokens"

  # Save
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<CONF
ZAI_API_KEY="$current_key"
ZAI_PERMISSION_MODE="$current_mode"
ZAI_MAX_TOKENS="$current_tokens"
CONF
  chmod 600 "$CONFIG_FILE"

  echo ""
  echo "  Config saved. Run 'claude-z' to start."
  echo ""
  exit 0
fi

# --- main: launch claude with z.ai ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo ""
  echo "  claude-z is not configured yet."
  echo "  Run: claude-z reconfig"
  echo ""
  exit 1
fi

source "$CONFIG_FILE"

if [[ -z "${ZAI_API_KEY:-}" ]]; then
  echo "  Error: ZAI_API_KEY is empty. Run: claude-z reconfig" >&2
  exit 1
fi

# Check claude is installed
if ! command -v claude &>/dev/null; then
  echo "  Error: 'claude' not found. Install Claude Code first:" >&2
  echo "  https://docs.anthropic.com/en/docs/claude-code" >&2
  exit 1
fi

# Build env
export ANTHROPIC_AUTH_TOKEN="$ZAI_API_KEY"
export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
export API_TIMEOUT_MS="3000000"

if [[ -n "${ZAI_MAX_TOKENS:-}" ]]; then
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$ZAI_MAX_TOKENS"
fi

# Build args
claude_args=()
case "${ZAI_PERMISSION_MODE:-normal}" in
  dangerously-skip-permissions)
    claude_args+=(--dangerously-skip-permissions)
    ;;
esac

# Pass through user args
claude_args+=("$@")

exec claude "${claude_args[@]}"

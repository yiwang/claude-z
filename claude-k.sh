#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="$HOME/.config/claude-k"
CONFIG_FILE="$CONFIG_DIR/config"

# --- reconfig ---
if [[ "${1:-}" == "reconfig" ]]; then
  echo ""
  echo "  claude-k reconfig"
  echo "  ─────────────────"
  echo ""

  [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" 2>/dev/null

  # API key
  current_key="${CK_API_KEY:-}"
  if [[ -n "$current_key" ]]; then
    masked="${current_key:0:8}...${current_key: -4}"
    echo "  Current API key: $masked"
  fi
  echo "  Get key: Kimi Code Console (https://www.kimi.com/code) — Create API Key"
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
  current_mode="${CK_PERMISSION_MODE:-normal}"
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
  echo "  Model:"
  echo "    1) k3[1m]                  — K3, 1M context (Allegretto and above)"
  echo "    2) k3                      — K3, 256k context (Moderato and above)"
  echo "    3) kimi-for-coding         — K2.7 Code, 256k context (all plans)"
  echo "    4) kimi-for-coding-highspeed — K2.7 Code, ~5-6x faster (Allegretto and above)"
  echo ""
  current_model="${CK_MODEL:-k3[1m]}"
  read -rp "  Choose [1/2/3/4] (enter to keep '$current_model'): " model_choice
  case "$model_choice" in
    1) current_model="k3[1m]" ;;
    2) current_model="k3" ;;
    3) current_model="kimi-for-coding" ;;
    4) current_model="kimi-for-coding-highspeed" ;;
    "") ;; # keep current
    *) echo "  Invalid choice, keeping '$current_model'" ;;
  esac

  # Max tokens
  echo ""
  current_tokens="${CK_MAX_TOKENS:-}"
  read -rp "  Max output tokens [enter to skip, e.g. 64000]: " new_tokens
  [[ -n "$new_tokens" ]] && current_tokens="$new_tokens"

  # Save
  mkdir -p "$CONFIG_DIR"
  cat > "$CONFIG_FILE" <<CONF
CK_API_KEY="$current_key"
CK_PERMISSION_MODE="$current_mode"
CK_MODEL="$current_model"
CK_MAX_TOKENS="$current_tokens"
CONF
  chmod 600 "$CONFIG_FILE"

  echo ""
  echo "  Config saved. Run 'claude-k' to start."
  echo ""
  exit 0
fi

# --- main: launch claude ---
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo ""
  echo "  claude-k is not configured yet."
  echo "  Run: claude-k reconfig"
  echo ""
  exit 1
fi

source "$CONFIG_FILE"

if [[ -z "${CK_API_KEY:-}" ]]; then
  echo "  Error: CK_API_KEY is empty. Run: claude-k reconfig" >&2
  exit 1
fi

# Check claude is installed
if ! command -v claude &>/dev/null; then
  echo "  Error: 'claude' not found. Install Claude Code first:" >&2
  echo "  https://docs.anthropic.com/en/docs/claude-code" >&2
  exit 1
fi

CK_MODEL="${CK_MODEL:-k3[1m]}"

# K3 with 1M context window; K2.7 Code series uses 256k
if [[ "$CK_MODEL" == "k3[1m]" ]]; then
  context_window="1048576"
else
  context_window="262144"
fi

export ANTHROPIC_BASE_URL="https://api.kimi.com/coding/"
# Send the key as a bearer token, which Claude Code always prefers to a claude.ai login.
# As ANTHROPIC_API_KEY it asks once per config dir whether to use it, with No preselected,
# and after a No it sends that config dir's claude.ai login token to this URL instead.
export ANTHROPIC_AUTH_TOKEN="$CK_API_KEY"
unset ANTHROPIC_API_KEY

export ANTHROPIC_MODEL="$CK_MODEL"
export ANTHROPIC_DEFAULT_FABLE_MODEL="$CK_MODEL"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$CK_MODEL"
export ANTHROPIC_DEFAULT_SONNET_MODEL="$CK_MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$CK_MODEL"
export CLAUDE_CODE_SUBAGENT_MODEL="$CK_MODEL"

export CLAUDE_CODE_AUTO_COMPACT_WINDOW="$context_window"
export CLAUDE_CODE_MAX_CONTEXT_TOKENS="$context_window"

export API_TIMEOUT_MS="3000000"

if [[ -n "${CK_MAX_TOKENS:-}" ]]; then
  export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$CK_MAX_TOKENS"
fi

# Build args and exec
if [[ "${CK_PERMISSION_MODE:-normal}" == "dangerously-skip-permissions" ]]; then
  exec claude --dangerously-skip-permissions "$@"
else
  exec claude "$@"
fi

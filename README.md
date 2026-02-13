# claude-z

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with [Z.ai](https://z.ai) as the API provider — cheaper alternative using GLM models.

**One command to install. Zero dependencies. Pure bash.**

## Install

```bash
git clone https://github.com/user/claude-z.git
cd claude-z
bash install.sh
```

The installer asks 3 things:
1. Your Z.ai API key ([get one here](https://z.ai/manage-apikey/apikey-list))
2. Permission mode (normal / acceptEdits / dangerously-skip)
3. Max output tokens (optional)

That's it. You're done.

## Usage

```bash
# Start Claude Code via Z.ai
claude-z

# One-shot prompt
claude-z -p "explain this codebase"

# Pass any Claude Code flags
claude-z --model sonnet
claude-z --verbose

# Change settings anytime
claude-z reconfig
```

## How it works

`claude-z` is a thin wrapper around `claude`. It sets these environment variables and launches Claude Code:

| Variable | Value |
|---|---|
| `ANTHROPIC_AUTH_TOKEN` | Your Z.ai API key |
| `ANTHROPIC_BASE_URL` | `https://api.z.ai/api/anthropic` |
| `API_TIMEOUT_MS` | `3000000` |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | Your chosen value (if set) |

Your regular `claude` command is **not affected** — it still uses Anthropic directly.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A [Z.ai](https://z.ai) API key
- bash

## Uninstall

```bash
bash uninstall.sh
```

Removes `~/.local/bin/claude-z` and `~/.config/claude-z/`. Nothing else is touched.

## Config

Stored at `~/.config/claude-z/config` (chmod 600). Edit manually or run `claude-z reconfig`.

## License

MIT

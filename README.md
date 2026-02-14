# claude-z

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with alternative API providers — [Z.ai](https://z.ai) or [OpenRouter](https://openrouter.ai).

**One command to install. Zero dependencies. Pure bash.**

## Install

```bash
git clone https://github.com/Glaveily/claude-z.git
cd claude-z
bash install.sh
```

The installer asks 5 things:
1. Provider (Z.ai or OpenRouter)
2. API key
3. Permission mode (normal / acceptEdits / dangerously-skip)
4. Model
5. Max output tokens (optional)

That's it. You're done.

## Usage

```bash
# Start Claude Code via your provider
claude-z

# One-shot prompt
claude-z -p "explain this codebase"

# Pass any Claude Code flags
claude-z --model sonnet
claude-z --verbose

# Change settings anytime
claude-z reconfig
```

## Providers

### Z.ai — GLM models, flat monthly pricing

Plans from $6/mo. Get your key at [z.ai/manage-apikey](https://z.ai/manage-apikey/apikey-list).

| Model | Description | Plan |
|---|---|---|
| `glm-5` | Flagship, best quality, 744B MoE | Max only |
| `glm-4.7` | Fast, great for coding (default) | All plans |
| `glm-4.5` | Hybrid reasoning, thinking mode | All plans |
| `glm-4.5-air` | Lightweight, cheapest | All plans |

### OpenRouter — 400+ models, pay-per-token

Use any model from [openrouter.ai/models](https://openrouter.ai/models). Get your key at [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys).

You type the model ID during setup.

## How it works

`claude-z` is a thin wrapper around `claude`. It sets environment variables and launches Claude Code:

| Variable | Z.ai | OpenRouter |
|---|---|---|
| `ANTHROPIC_BASE_URL` | `https://api.z.ai/api/anthropic` | `https://openrouter.ai/api` |
| `ANTHROPIC_AUTH_TOKEN` | Your Z.ai key | Your OpenRouter key |
| `ANTHROPIC_API_KEY` | _(not set)_ | `""` (blank, required) |
| `ANTHROPIC_DEFAULT_*_MODEL` | Your chosen GLM model | Your chosen model ID |

Your regular `claude` command is **not affected** — it still uses Anthropic directly.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- A [Z.ai](https://z.ai) or [OpenRouter](https://openrouter.ai) API key
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

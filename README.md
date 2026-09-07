# claude-z / claude-o / claude-k

Run [Claude Code](https://docs.anthropic.com/en/docs/claude-code) with alternative API providers — [Z.ai](https://z.ai), [OpenRouter](https://openrouter.ai), or [Kimi](https://www.kimi.com/code).

Each provider gets its own command, its own installer, and its own config file. Install one, two, or all three side by side.

**One command to install. Zero dependencies.**

| Command | Provider | Default model |
|---|---|---|
| `claude-z` | Z.ai | `glm-5.3[1m]` (1M context) |
| `claude-o` | OpenRouter | any model ID you choose |
| `claude-k` | Kimi | `k3[1m]` (1M context) |

## Install

Pick the provider(s) you want:

### Linux / macOS

```bash
git clone https://github.com/Glaveily/claude-z.git
cd claude-z
bash install-z.sh   # Z.ai
bash install-o.sh   # OpenRouter
bash install-k.sh   # Kimi
```

### Windows

```
git clone https://github.com/Glaveily/claude-z.git
cd claude-z
install-z.cmd   :: Z.ai
install-o.cmd   :: OpenRouter
install-k.cmd   :: Kimi
```

Each installer asks 4 things:
1. API key
2. Permission mode (normal / acceptEdits / dangerously-skip)
3. Model
4. Max output tokens (optional)

That's it. You're done.

## Usage

```bash
# Start Claude Code via your provider
claude-z          # or claude-o, claude-k

# One-shot prompt
claude-k -p "explain this codebase"

# Pass any Claude Code flags
claude-z --verbose

# Change settings anytime
claude-k reconfig
```

Your regular `claude` command is **not affected** — it still uses Anthropic directly.

## Providers

### claude-z — Z.ai: GLM models, flat monthly pricing

Plans from $6/mo. Get your key at [z.ai/manage-apikey](https://z.ai/manage-apikey/apikey-list).

| Model | Description |
|---|---|
| `glm-5.3[1m]` | Flagship (default) — 1M context, text-only |
| `glm-5.3-flash` | Fast, multimodal, cheapest — 1M context |
| `glm-4.7` | Fast, great for coding |

GLM-5.3 models have a 1M context window natively; the `[1m]` suffix tells Claude Code to use the full window (it sets `CLAUDE_CODE_AUTO_COMPACT_WINDOW=1000000` automatically).

### claude-o — OpenRouter: 400+ models, pay-per-token

Use any model from [openrouter.ai/models](https://openrouter.ai/models). Get your key at [openrouter.ai/settings/keys](https://openrouter.ai/settings/keys). You type the model ID during setup.

### claude-k — Kimi: K3 / K2.7 Code, membership plans

Requires a Kimi membership with Kimi Code benefits. Create a key in the [Kimi Code Console](https://www.kimi.com/code) ("Create API Key").

| Model | Description | Plan |
|---|---|---|
| `k3[1m]` | K3, 1M context (default) | Allegretto and above |
| `k3` | K3, 256k context | Moderato and above |
| `kimi-for-coding` | K2.7 Code, 256k context | All plans |
| `kimi-for-coding-highspeed` | K2.7 Code, ~5–6× faster output | Allegretto and above |

Context-window variables (`CLAUDE_CODE_AUTO_COMPACT_WINDOW`, `CLAUDE_CODE_MAX_CONTEXT_TOKENS`) are set automatically per model: `1048576` for `k3[1m]`, `262144` otherwise. In a session, use `/effort` to switch thinking effort.

## How it works

Each command is a thin wrapper around `claude`. It sets environment variables from its config and launches Claude Code:

| Variable | claude-z | claude-o | claude-k |
|---|---|---|---|
| `ANTHROPIC_BASE_URL` | `https://api.z.ai/api/anthropic` | `https://openrouter.ai/api` | `https://api.kimi.com/coding/` |
| `ANTHROPIC_AUTH_TOKEN` | Your Z.ai key | Your OpenRouter key | _(not set)_ |
| `ANTHROPIC_API_KEY` | _(not set)_ | `""` (blank, required) | Your Kimi key |
| `ANTHROPIC_DEFAULT_OPUS/SONNET/HAIKU_MODEL` | Your GLM models | Your model IDs | Your Kimi model |
| `ANTHROPIC_MODEL` + `CLAUDE_CODE_SUBAGENT_MODEL` | _(not set)_ | _(not set)_ | Your Kimi model |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | `1` | _(not set)_ | _(not set)_ |
| Context window vars | `1000000` for `[1m]` models | _(not set)_ | `1048576` / `262144` per model |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed
- An API key for the provider you want: [Z.ai](https://z.ai), [OpenRouter](https://openrouter.ai), or [Kimi](https://www.kimi.com/code) (membership)
- bash (Linux/macOS) or PowerShell (Windows)

## Uninstall

Each tool removes only itself — its binary, its config, and (on Windows) its PATH entry.

### Linux / macOS

```bash
bash uninstall-z.sh   # removes ~/.local/bin/claude-z and ~/.config/claude-z/
bash uninstall-o.sh   # removes ~/.local/bin/claude-o and ~/.config/claude-o/
bash uninstall-k.sh   # removes ~/.local/bin/claude-k and ~/.config/claude-k/
```

### Windows

```
uninstall-z.cmd   :: removes %LOCALAPPDATA%\claude-z\ and %APPDATA%\claude-z\
uninstall-o.cmd   :: removes %LOCALAPPDATA%\claude-o\ and %APPDATA%\claude-o\
uninstall-k.cmd   :: removes %LOCALAPPDATA%\claude-k\ and %APPDATA%\claude-k\
```

## Config

One config per command, editable manually or via `claude-x reconfig`:

| Command | Linux/macOS | Windows |
|---|---|---|
| `claude-z` | `~/.config/claude-z/config` | `%APPDATA%\claude-z\config` |
| `claude-o` | `~/.config/claude-o/config` | `%APPDATA%\claude-o\config` |
| `claude-k` | `~/.config/claude-k/config` | `%APPDATA%\claude-k\config` |

(chmod 600 on Linux/macOS)

## Upgrading from the old combined claude-z

Older versions had a single `claude-z` with a provider switch. Z.ai configs keep working as-is. If you used OpenRouter through the old `claude-z`, run `install-o` (or `claude-o reconfig`) and re-enter your key and model ID.

## License

MIT

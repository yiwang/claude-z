# claude-o.ps1 — Claude Code with OpenRouter API backend (Windows)
$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:APPDATA "claude-o"
$ConfigFile = Join-Path $ConfigDir "config"

function Read-CoConfig {
    $config = @{}
    if (Test-Path $ConfigFile) {
        Get-Content $ConfigFile | ForEach-Object {
            if ($_ -match '^(\w+)="(.*)"$') {
                $config[$Matches[1]] = $Matches[2]
            }
        }
    }
    return $config
}

function Save-CoConfig {
    param([hashtable]$c)
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    @"
CO_API_KEY="$($c.CO_API_KEY)"
CO_PERMISSION_MODE="$($c.CO_PERMISSION_MODE)"
CO_MODEL_OPUS="$($c.CO_MODEL_OPUS)"
CO_MODEL_SONNET="$($c.CO_MODEL_SONNET)"
CO_MODEL_HAIKU="$($c.CO_MODEL_HAIKU)"
CO_MAX_TOKENS="$($c.CO_MAX_TOKENS)"
"@ | Set-Content -Path $ConfigFile -Encoding UTF8
}

# --- reconfig ---
if ($args.Count -gt 0 -and $args[0] -eq "reconfig") {
    Write-Host ""
    Write-Host "  claude-o reconfig"
    Write-Host "  -----------------"
    Write-Host ""

    $config = Read-CoConfig

    # API key
    $currentKey = if ($config.CO_API_KEY) { $config.CO_API_KEY } else { "" }
    if ($currentKey) {
        $maskLen = [Math]::Min(8, $currentKey.Length)
        $tailStart = [Math]::Max(0, $currentKey.Length - 4)
        $masked = $currentKey.Substring(0, $maskLen) + "..." + $currentKey.Substring($tailStart)
        Write-Host "  Current API key: $masked"
    }
    Write-Host "  Get key: https://openrouter.ai/settings/keys"
    $newKey = Read-Host "  API key (enter to keep current)"
    if ($newKey) { $currentKey = $newKey }
    if (-not $currentKey) {
        Write-Host "  Error: API key is required." -ForegroundColor Red
        exit 1
    }

    # Permission mode
    Write-Host ""
    Write-Host "  Permission mode:"
    Write-Host "    1) normal           -- ask before each action"
    Write-Host "    2) acceptEdits      -- auto-accept file edits, ask for commands"
    Write-Host "    3) dangerously-skip -- skip all permission prompts"
    Write-Host ""
    $currentMode = if ($config.CO_PERMISSION_MODE) { $config.CO_PERMISSION_MODE } else { "normal" }
    $choice = Read-Host "  Choose [1/2/3] (enter to keep '$currentMode')"
    switch ($choice) {
        "1" { $currentMode = "normal" }
        "2" { $currentMode = "acceptEdits" }
        "3" { $currentMode = "dangerously-skip-permissions" }
        "" { }
        default { Write-Host "  Invalid choice, keeping '$currentMode'" }
    }

    # Model
    Write-Host ""
    Write-Host "  Model for opus/sonnet slot (OpenRouter model ID)."
    Write-Host "  Browse: https://openrouter.ai/models"
    Write-Host ""
    $currentOpus = if ($config.CO_MODEL_OPUS) { $config.CO_MODEL_OPUS } else { "" }
    $orModel = Read-Host "  Model ID (enter to keep '$currentOpus')"
    if ($orModel) { $currentOpus = $orModel }
    if (-not $currentOpus) {
        Write-Host "  Error: model ID is required." -ForegroundColor Red
        exit 1
    }
    $currentSonnet = $currentOpus
    Write-Host ""
    $currentHaiku = if ($config.CO_MODEL_HAIKU) { $config.CO_MODEL_HAIKU } else { $currentOpus }
    $orHaiku = Read-Host "  Haiku (light) model ID (enter to keep '$currentHaiku')"
    if ($orHaiku) { $currentHaiku = $orHaiku }

    # Max tokens
    Write-Host ""
    $currentTokens = if ($config.CO_MAX_TOKENS) { $config.CO_MAX_TOKENS } else { "" }
    $newTokens = Read-Host "  Max output tokens [enter to skip, e.g. 64000]"
    if ($newTokens) { $currentTokens = $newTokens }

    # Save
    Save-CoConfig @{
        CO_API_KEY         = $currentKey
        CO_PERMISSION_MODE = $currentMode
        CO_MODEL_OPUS      = $currentOpus
        CO_MODEL_SONNET    = $currentSonnet
        CO_MODEL_HAIKU     = $currentHaiku
        CO_MAX_TOKENS      = $currentTokens
    }

    Write-Host ""
    Write-Host "  Config saved. Run 'claude-o' to start."
    Write-Host ""
    exit 0
}

# --- main: launch claude ---
if (-not (Test-Path $ConfigFile)) {
    Write-Host ""
    Write-Host "  claude-o is not configured yet."
    Write-Host "  Run: claude-o reconfig"
    Write-Host ""
    exit 1
}

$config = Read-CoConfig

if (-not $config.CO_API_KEY) {
    Write-Host "  Error: CO_API_KEY is empty. Run: claude-o reconfig" -ForegroundColor Red
    exit 1
}

# Check claude is installed
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  Error: 'claude' not found. Install Claude Code first:" -ForegroundColor Red
    Write-Host "  https://docs.anthropic.com/en/docs/claude-code"
    exit 1
}

$env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
$env:ANTHROPIC_AUTH_TOKEN = $config.CO_API_KEY
$env:ANTHROPIC_API_KEY = ""

$env:API_TIMEOUT_MS = "3000000"

$env:ANTHROPIC_DEFAULT_OPUS_MODEL = $config.CO_MODEL_OPUS
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = if ($config.CO_MODEL_SONNET) { $config.CO_MODEL_SONNET } else { $config.CO_MODEL_OPUS }
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = if ($config.CO_MODEL_HAIKU) { $config.CO_MODEL_HAIKU } else { $config.CO_MODEL_OPUS }

if ($config.CO_MAX_TOKENS) {
    $env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = $config.CO_MAX_TOKENS
}

# Launch claude
if ($config.CO_PERMISSION_MODE -eq "dangerously-skip-permissions") {
    & claude --dangerously-skip-permissions @args
} else {
    & claude @args
}
exit $LASTEXITCODE

# claude-z.ps1 — Claude Code with alternative API providers (Windows)
$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:APPDATA "claude-z"
$ConfigFile = Join-Path $ConfigDir "config"

function Read-CzConfig {
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

function Save-CzConfig {
    param([hashtable]$c)
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    @"
CZ_PROVIDER="$($c.CZ_PROVIDER)"
CZ_API_KEY="$($c.CZ_API_KEY)"
CZ_PERMISSION_MODE="$($c.CZ_PERMISSION_MODE)"
CZ_MODEL_OPUS="$($c.CZ_MODEL_OPUS)"
CZ_MODEL_SONNET="$($c.CZ_MODEL_SONNET)"
CZ_MODEL_HAIKU="$($c.CZ_MODEL_HAIKU)"
CZ_MAX_TOKENS="$($c.CZ_MAX_TOKENS)"
"@ | Set-Content -Path $ConfigFile -Encoding UTF8
}

# --- reconfig ---
if ($args.Count -gt 0 -and $args[0] -eq "reconfig") {
    Write-Host ""
    Write-Host "  claude-z reconfig"
    Write-Host "  -----------------"
    Write-Host ""

    $config = Read-CzConfig

    # Provider
    $currentProvider = if ($config.CZ_PROVIDER) { $config.CZ_PROVIDER } else { "zai" }
    Write-Host "  Provider:"
    Write-Host "    1) Z.ai       -- GLM models, from `$6/mo"
    Write-Host "    2) OpenRouter  -- 400+ models, pay-per-token"
    Write-Host ""
    $choice = Read-Host "  Choose [1/2] (enter to keep '$currentProvider')"
    switch ($choice) {
        "1" { $currentProvider = "zai" }
        "2" { $currentProvider = "openrouter" }
        "" { }
        default { Write-Host "  Invalid choice, keeping '$currentProvider'" }
    }

    # API key
    Write-Host ""
    $currentKey = if ($config.CZ_API_KEY) { $config.CZ_API_KEY } else { "" }
    if ($currentKey) {
        $maskLen = [Math]::Min(8, $currentKey.Length)
        $tailStart = [Math]::Max(0, $currentKey.Length - 4)
        $masked = $currentKey.Substring(0, $maskLen) + "..." + $currentKey.Substring($tailStart)
        Write-Host "  Current API key: $masked"
    }
    if ($currentProvider -eq "zai") {
        Write-Host "  Get key: https://z.ai/manage-apikey/apikey-list"
    } else {
        Write-Host "  Get key: https://openrouter.ai/settings/keys"
    }
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
    $currentMode = if ($config.CZ_PERMISSION_MODE) { $config.CZ_PERMISSION_MODE } else { "normal" }
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
    $currentOpus = ""; $currentSonnet = ""; $currentHaiku = ""
    if ($currentProvider -eq "zai") {
        Write-Host "  Base model:"
        Write-Host "    1) glm-5        -- flagship, best quality (Max plan only)"
        Write-Host "    2) glm-4.7      -- fast, great for coding"
        Write-Host "    3) glm-4.5      -- hybrid reasoning, thinking mode"
        Write-Host "    4) glm-4.5-air  -- lightweight, cheapest"
        Write-Host ""
        $currentOpus = if ($config.CZ_MODEL_OPUS) { $config.CZ_MODEL_OPUS } else { "glm-4.7" }
        $choice = Read-Host "  Choose [1/2/3/4] (enter to keep '$currentOpus')"
        switch ($choice) {
            "1" { $currentOpus = "glm-5";       $currentSonnet = "glm-5";       $currentHaiku = "glm-4.5-air" }
            "2" { $currentOpus = "glm-4.7";     $currentSonnet = "glm-4.7";     $currentHaiku = "glm-4.5-air" }
            "3" { $currentOpus = "glm-4.5";     $currentSonnet = "glm-4.5";     $currentHaiku = "glm-4.5-air" }
            "4" { $currentOpus = "glm-4.5-air"; $currentSonnet = "glm-4.5-air"; $currentHaiku = "glm-4.5-air" }
            "" {
                $currentSonnet = if ($config.CZ_MODEL_SONNET) { $config.CZ_MODEL_SONNET } else { $currentOpus }
                $currentHaiku = if ($config.CZ_MODEL_HAIKU) { $config.CZ_MODEL_HAIKU } else { "glm-4.5-air" }
            }
            default {
                Write-Host "  Invalid, keeping current"
                $currentSonnet = if ($config.CZ_MODEL_SONNET) { $config.CZ_MODEL_SONNET } else { $currentOpus }
                $currentHaiku = if ($config.CZ_MODEL_HAIKU) { $config.CZ_MODEL_HAIKU } else { "glm-4.5-air" }
            }
        }
    } else {
        $currentOpus = if ($config.CZ_MODEL_OPUS) { $config.CZ_MODEL_OPUS } else { "" }
        Write-Host "  Model for opus/sonnet slot (OpenRouter model ID)."
        Write-Host "  Browse: https://openrouter.ai/models"
        Write-Host ""
        $orModel = Read-Host "  Model ID (enter to keep '$currentOpus')"
        if ($orModel) { $currentOpus = $orModel }
        $currentSonnet = $currentOpus
        Write-Host ""
        $currentHaiku = if ($config.CZ_MODEL_HAIKU) { $config.CZ_MODEL_HAIKU } else { $currentOpus }
        $orHaiku = Read-Host "  Haiku (light) model (enter to keep '$currentHaiku')"
        if ($orHaiku) { $currentHaiku = $orHaiku }
    }

    # Max tokens
    Write-Host ""
    $currentTokens = if ($config.CZ_MAX_TOKENS) { $config.CZ_MAX_TOKENS } else { "" }
    $newTokens = Read-Host "  Max output tokens [enter to skip, e.g. 64000]"
    if ($newTokens) { $currentTokens = $newTokens }

    # Save
    Save-CzConfig @{
        CZ_PROVIDER        = $currentProvider
        CZ_API_KEY          = $currentKey
        CZ_PERMISSION_MODE  = $currentMode
        CZ_MODEL_OPUS       = $currentOpus
        CZ_MODEL_SONNET     = $currentSonnet
        CZ_MODEL_HAIKU      = $currentHaiku
        CZ_MAX_TOKENS       = $currentTokens
    }

    Write-Host ""
    Write-Host "  Config saved. Run 'claude-z' to start."
    Write-Host ""
    exit 0
}

# --- main: launch claude ---
if (-not (Test-Path $ConfigFile)) {
    Write-Host ""
    Write-Host "  claude-z is not configured yet."
    Write-Host "  Run: claude-z reconfig"
    Write-Host ""
    exit 1
}

$config = Read-CzConfig

if (-not $config.CZ_API_KEY) {
    Write-Host "  Error: CZ_API_KEY is empty. Run: claude-z reconfig" -ForegroundColor Red
    exit 1
}

# Check claude is installed
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  Error: 'claude' not found. Install Claude Code first:" -ForegroundColor Red
    Write-Host "  https://docs.anthropic.com/en/docs/claude-code"
    exit 1
}

# Build env per provider
switch ($config.CZ_PROVIDER) {
    "openrouter" {
        $env:ANTHROPIC_BASE_URL = "https://openrouter.ai/api"
        $env:ANTHROPIC_AUTH_TOKEN = $config.CZ_API_KEY
        $env:ANTHROPIC_API_KEY = ""
    }
    default {
        $env:ANTHROPIC_BASE_URL = "https://api.z.ai/api/anthropic"
        $env:ANTHROPIC_AUTH_TOKEN = $config.CZ_API_KEY
    }
}

$env:API_TIMEOUT_MS = "3000000"
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = if ($config.CZ_MODEL_OPUS) { $config.CZ_MODEL_OPUS } else { "glm-4.7" }
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = if ($config.CZ_MODEL_SONNET) { $config.CZ_MODEL_SONNET } else { "glm-4.7" }
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = if ($config.CZ_MODEL_HAIKU) { $config.CZ_MODEL_HAIKU } else { "glm-4.5-air" }

if ($config.CZ_MAX_TOKENS) {
    $env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = $config.CZ_MAX_TOKENS
}

# Launch claude
if ($config.CZ_PERMISSION_MODE -eq "dangerously-skip-permissions") {
    & claude --dangerously-skip-permissions @args
} else {
    & claude @args
}
exit $LASTEXITCODE

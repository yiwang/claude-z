# claude-k.ps1 — Claude Code with Kimi API backend (Windows)
$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:APPDATA "claude-k"
$ConfigFile = Join-Path $ConfigDir "config"

function Read-CkConfig {
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

function Save-CkConfig {
    param([hashtable]$c)
    if (-not (Test-Path $ConfigDir)) {
        New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
    }
    @"
CK_API_KEY="$($c.CK_API_KEY)"
CK_PERMISSION_MODE="$($c.CK_PERMISSION_MODE)"
CK_MODEL="$($c.CK_MODEL)"
CK_MAX_TOKENS="$($c.CK_MAX_TOKENS)"
"@ | Set-Content -Path $ConfigFile -Encoding UTF8
}

# --- reconfig ---
if ($args.Count -gt 0 -and $args[0] -eq "reconfig") {
    Write-Host ""
    Write-Host "  claude-k reconfig"
    Write-Host "  -----------------"
    Write-Host ""

    $config = Read-CkConfig

    # API key
    $currentKey = if ($config.CK_API_KEY) { $config.CK_API_KEY } else { "" }
    if ($currentKey) {
        $maskLen = [Math]::Min(8, $currentKey.Length)
        $tailStart = [Math]::Max(0, $currentKey.Length - 4)
        $masked = $currentKey.Substring(0, $maskLen) + "..." + $currentKey.Substring($tailStart)
        Write-Host "  Current API key: $masked"
    }
    Write-Host "  Get key: Kimi Code Console (https://www.kimi.com/code) - Create API Key"
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
    $currentMode = if ($config.CK_PERMISSION_MODE) { $config.CK_PERMISSION_MODE } else { "normal" }
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
    Write-Host "  Model:"
    Write-Host "    1) k3[1m]                  -- K3, 1M context (Allegretto and above)"
    Write-Host "    2) k3                      -- K3, 256k context (Moderato and above)"
    Write-Host "    3) kimi-for-coding         -- K2.7 Code, 256k context (all plans)"
    Write-Host "    4) kimi-for-coding-highspeed -- K2.7 Code, ~5-6x faster (Allegretto and above)"
    Write-Host ""
    $currentModel = if ($config.CK_MODEL) { $config.CK_MODEL } else { "k3[1m]" }
    $choice = Read-Host "  Choose [1/2/3/4] (enter to keep '$currentModel')"
    switch ($choice) {
        "1" { $currentModel = "k3[1m]" }
        "2" { $currentModel = "k3" }
        "3" { $currentModel = "kimi-for-coding" }
        "4" { $currentModel = "kimi-for-coding-highspeed" }
        "" { }
        default { Write-Host "  Invalid choice, keeping '$currentModel'" }
    }

    # Max tokens
    Write-Host ""
    $currentTokens = if ($config.CK_MAX_TOKENS) { $config.CK_MAX_TOKENS } else { "" }
    $newTokens = Read-Host "  Max output tokens [enter to skip, e.g. 64000]"
    if ($newTokens) { $currentTokens = $newTokens }

    # Save
    Save-CkConfig @{
        CK_API_KEY         = $currentKey
        CK_PERMISSION_MODE = $currentMode
        CK_MODEL           = $currentModel
        CK_MAX_TOKENS      = $currentTokens
    }

    Write-Host ""
    Write-Host "  Config saved. Run 'claude-k' to start."
    Write-Host ""
    exit 0
}

# --- main: launch claude ---
if (-not (Test-Path $ConfigFile)) {
    Write-Host ""
    Write-Host "  claude-k is not configured yet."
    Write-Host "  Run: claude-k reconfig"
    Write-Host ""
    exit 1
}

$config = Read-CkConfig

if (-not $config.CK_API_KEY) {
    Write-Host "  Error: CK_API_KEY is empty. Run: claude-k reconfig" -ForegroundColor Red
    exit 1
}

# Check claude is installed
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  Error: 'claude' not found. Install Claude Code first:" -ForegroundColor Red
    Write-Host "  https://docs.anthropic.com/en/docs/claude-code"
    exit 1
}

$model = if ($config.CK_MODEL) { $config.CK_MODEL } else { "k3[1m]" }

# K3 with 1M context window; K2.7 Code series uses 256k
$contextWindow = if ($model -eq "k3[1m]") { "1048576" } else { "262144" }

$env:ANTHROPIC_BASE_URL = "https://api.kimi.com/coding/"
$env:ANTHROPIC_API_KEY = $config.CK_API_KEY

$env:ANTHROPIC_MODEL = $model
$env:ANTHROPIC_DEFAULT_FABLE_MODEL = $model
$env:ANTHROPIC_DEFAULT_OPUS_MODEL = $model
$env:ANTHROPIC_DEFAULT_SONNET_MODEL = $model
$env:ANTHROPIC_DEFAULT_HAIKU_MODEL = $model
$env:CLAUDE_CODE_SUBAGENT_MODEL = $model

$env:CLAUDE_CODE_AUTO_COMPACT_WINDOW = $contextWindow
$env:CLAUDE_CODE_MAX_CONTEXT_TOKENS = $contextWindow

$env:API_TIMEOUT_MS = "3000000"

if ($config.CK_MAX_TOKENS) {
    $env:CLAUDE_CODE_MAX_OUTPUT_TOKENS = $config.CK_MAX_TOKENS
}

# Launch claude
if ($config.CK_PERMISSION_MODE -eq "dangerously-skip-permissions") {
    & claude --dangerously-skip-permissions @args
} else {
    & claude @args
}
exit $LASTEXITCODE

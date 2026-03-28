# install.ps1 — claude-z installer for Windows
$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:APPDATA "claude-z"
$ConfigFile = Join-Path $ConfigDir "config"
$InstallDir = Join-Path $env:LOCALAPPDATA "claude-z"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  +-----------------------------------+"
Write-Host "  |  claude-z installer               |"
Write-Host "  |  Claude Code + custom provider    |"
Write-Host "  +-----------------------------------+"
Write-Host ""

# Check claude is installed
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    Write-Host "  Claude Code is not installed."
    Write-Host "  Install it first: https://docs.anthropic.com/en/docs/claude-code"
    Write-Host ""
    exit 1
}

$claudeVer = try { & claude --version 2>&1 } catch { "unknown" }
Write-Host "  Found Claude Code: $claudeVer"
Write-Host ""

# --- Setup wizard ---

# 1. Provider
Write-Host "  Provider:"
Write-Host "    1) Z.ai       -- GLM models, from `$6/mo"
Write-Host "    2) OpenRouter  -- 400+ models, pay-per-token"
Write-Host ""
$choice = Read-Host "  Choose [1/2] (default: 1)"
if (-not $choice) { $choice = "1" }
switch ($choice) {
    "1" { $provider = "zai" }
    "2" { $provider = "openrouter" }
    default { Write-Host "  Invalid choice, using Z.ai"; $provider = "zai" }
}

# 2. API key
Write-Host ""
if ($provider -eq "zai") {
    Write-Host "  Get your Z.ai API key at: https://z.ai/manage-apikey/apikey-list"
} else {
    Write-Host "  Get your OpenRouter API key at: https://openrouter.ai/settings/keys"
}
Write-Host ""
$apiKey = Read-Host "  API key"
if (-not $apiKey) {
    Write-Host "  Error: API key is required." -ForegroundColor Red
    exit 1
}

# 3. Permission mode
Write-Host ""
Write-Host "  Permission mode:"
Write-Host "    1) normal           -- ask before each action (safest)"
Write-Host "    2) acceptEdits      -- auto-accept file edits, ask for commands"
Write-Host "    3) dangerously-skip -- skip all permission prompts (fastest)"
Write-Host ""
$choice = Read-Host "  Choose [1/2/3] (default: 1)"
if (-not $choice) { $choice = "1" }
switch ($choice) {
    "1" { $permMode = "normal" }
    "2" { $permMode = "acceptEdits" }
    "3" { $permMode = "dangerously-skip-permissions" }
    default { Write-Host "  Invalid choice, using 'normal'"; $permMode = "normal" }
}

# 4. Model
Write-Host ""
if ($provider -eq "zai") {
    Write-Host "  Base model:"
    Write-Host "    1) glm-5        -- flagship, best quality (Max plan only)"
    Write-Host "    2) glm-4.7      -- fast, great for coding (default)"
    Write-Host "    3) glm-4.5      -- hybrid reasoning, thinking mode"
    Write-Host "    4) glm-4.5-air  -- lightweight, cheapest"
    Write-Host ""
    $choice = Read-Host "  Choose [1/2/3/4] (default: 2)"
    if (-not $choice) { $choice = "2" }
    switch ($choice) {
        "1" { $modelOpus = "glm-5";       $modelSonnet = "glm-5";       $modelHaiku = "glm-4.5-air" }
        "2" { $modelOpus = "glm-4.7";     $modelSonnet = "glm-4.7";     $modelHaiku = "glm-4.5-air" }
        "3" { $modelOpus = "glm-4.5";     $modelSonnet = "glm-4.5";     $modelHaiku = "glm-4.5-air" }
        "4" { $modelOpus = "glm-4.5-air"; $modelSonnet = "glm-4.5-air"; $modelHaiku = "glm-4.5-air" }
        default { Write-Host "  Invalid choice, using glm-4.7"; $modelOpus = "glm-4.7"; $modelSonnet = "glm-4.7"; $modelHaiku = "glm-4.5-air" }
    }
} else {
    Write-Host "  Model for opus/sonnet slot (OpenRouter model ID)."
    Write-Host "  Browse: https://openrouter.ai/models"
    Write-Host ""
    $orModel = Read-Host "  Model ID"
    if (-not $orModel) {
        Write-Host "  Error: model ID is required." -ForegroundColor Red
        exit 1
    }
    $modelOpus = $orModel
    $modelSonnet = $orModel
    Write-Host ""
    $orHaiku = Read-Host "  Haiku (light) model ID (enter to use same)"
    $modelHaiku = if ($orHaiku) { $orHaiku } else { $orModel }
}

# 5. Max tokens
Write-Host ""
$maxTokens = Read-Host "  Max output tokens (enter to skip, e.g. 64000)"

# --- Save config ---
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}
@"
CZ_PROVIDER="$provider"
CZ_API_KEY="$apiKey"
CZ_PERMISSION_MODE="$permMode"
CZ_MODEL_OPUS="$modelOpus"
CZ_MODEL_SONNET="$modelSonnet"
CZ_MODEL_HAIKU="$modelHaiku"
CZ_MAX_TOKENS="$maxTokens"
"@ | Set-Content -Path $ConfigFile -Encoding UTF8

# --- Install script ---
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Copy-Item (Join-Path $ScriptDir "claude-z.ps1") (Join-Path $InstallDir "claude-z.ps1") -Force

# Create cmd wrapper so 'claude-z' works from cmd.exe and PowerShell
@"
@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0claude-z.ps1" %*
exit /b %errorlevel%
"@ | Set-Content -Path (Join-Path $InstallDir "claude-z.cmd") -Encoding ASCII

# Add to user PATH if needed
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$InstallDir", "User")
    # Also update current session
    $env:Path = "$env:Path;$InstallDir"
    Write-Host ""
    Write-Host "  Added $InstallDir to your PATH."
    Write-Host "  You may need to restart your terminal for PATH changes to take effect."
}

$providerName = if ($provider -eq "openrouter") { "OpenRouter" } else { "Z.ai" }

Write-Host ""
Write-Host "  ------------------------------------"
Write-Host "  Done! claude-z is ready ($providerName)."
Write-Host ""
Write-Host "  Usage:"
Write-Host "    claude-z                -- start Claude Code via $providerName"
Write-Host "    claude-z reconfig       -- change settings"
Write-Host "    claude-z -p `"prompt`"    -- one-shot query"
Write-Host ""
Write-Host "  Config: $ConfigFile"
Write-Host "  Binary: $InstallDir\claude-z.cmd"
Write-Host "  ------------------------------------"
Write-Host ""

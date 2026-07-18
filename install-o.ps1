# install-o.ps1 — claude-o installer for Windows
$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:APPDATA "claude-o"
$ConfigFile = Join-Path $ConfigDir "config"
$InstallDir = Join-Path $env:LOCALAPPDATA "claude-o"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  +-----------------------------------+"
Write-Host "  |  claude-o installer               |"
Write-Host "  |  Claude Code + OpenRouter         |"
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

# 1. API key
Write-Host "  Get your OpenRouter API key at: https://openrouter.ai/settings/keys"
Write-Host ""
$apiKey = Read-Host "  API key"
if (-not $apiKey) {
    Write-Host "  Error: API key is required." -ForegroundColor Red
    exit 1
}

# 2. Permission mode
Write-Host ""
Write-Host "  Permission mode:"
Write-Host "    1) normal           -- ask before each action"
Write-Host "    2) acceptEdits      -- auto-accept file edits, ask for commands"
Write-Host "    3) dangerously-skip -- skip all permission prompts"
Write-Host ""
$choice = Read-Host "  Choose [1/2/3] (default: 1)"
if (-not $choice) { $choice = "1" }
switch ($choice) {
    "1" { $permMode = "normal" }
    "2" { $permMode = "acceptEdits" }
    "3" { $permMode = "dangerously-skip-permissions" }
    default { Write-Host "  Invalid choice, using 'normal'"; $permMode = "normal" }
}

# 3. Model
Write-Host ""
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

# 4. Max tokens
Write-Host ""
$maxTokens = Read-Host "  Max output tokens (enter to skip, e.g. 64000)"

# --- Save config ---
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}
@"
CO_API_KEY="$apiKey"
CO_PERMISSION_MODE="$permMode"
CO_MODEL_OPUS="$modelOpus"
CO_MODEL_SONNET="$modelSonnet"
CO_MODEL_HAIKU="$modelHaiku"
CO_MAX_TOKENS="$maxTokens"
"@ | Set-Content -Path $ConfigFile -Encoding UTF8

# --- Install script ---
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Copy-Item (Join-Path $ScriptDir "claude-o.ps1") (Join-Path $InstallDir "claude-o.ps1") -Force

# Create cmd wrapper so 'claude-o' works from cmd.exe and PowerShell
@"
@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0claude-o.ps1" %*
exit /b %errorlevel%
"@ | Set-Content -Path (Join-Path $InstallDir "claude-o.cmd") -Encoding ASCII

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

Write-Host ""
Write-Host "  ------------------------------------"
Write-Host "  Done! claude-o is ready (OpenRouter)."
Write-Host ""
Write-Host "  Usage:"
Write-Host "    claude-o                -- start Claude Code via OpenRouter"
Write-Host "    claude-o reconfig       -- change settings"
Write-Host "    claude-o -p `"prompt`"    -- one-shot query"
Write-Host ""
Write-Host "  Config: $ConfigFile"
Write-Host "  Binary: $InstallDir\claude-o.cmd"
Write-Host "  ------------------------------------"
Write-Host ""

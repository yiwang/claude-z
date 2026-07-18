# install-k.ps1 — claude-k installer for Windows
$ErrorActionPreference = "Stop"

$ConfigDir = Join-Path $env:APPDATA "claude-k"
$ConfigFile = Join-Path $ConfigDir "config"
$InstallDir = Join-Path $env:LOCALAPPDATA "claude-k"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "  +-----------------------------------+"
Write-Host "  |  claude-k installer               |"
Write-Host "  |  Claude Code + Kimi               |"
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
Write-Host "  Get your Kimi API key at: Kimi Code Console (https://www.kimi.com/code) - Create API Key"
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
Write-Host "  Model:"
Write-Host "    1) k3[1m]                  -- K3, 1M context (Allegretto and above) (default)"
Write-Host "    2) k3                      -- K3, 256k context (Moderato and above)"
Write-Host "    3) kimi-for-coding         -- K2.7 Code, 256k context (all plans)"
Write-Host "    4) kimi-for-coding-highspeed -- K2.7 Code, ~5-6x faster (Allegretto and above)"
Write-Host ""
$choice = Read-Host "  Choose [1/2/3/4] (default: 1)"
if (-not $choice) { $choice = "1" }
switch ($choice) {
    "1" { $model = "k3[1m]" }
    "2" { $model = "k3" }
    "3" { $model = "kimi-for-coding" }
    "4" { $model = "kimi-for-coding-highspeed" }
    default { Write-Host "  Invalid choice, using k3[1m]"; $model = "k3[1m]" }
}

# 4. Max tokens
Write-Host ""
$maxTokens = Read-Host "  Max output tokens (enter to skip, e.g. 64000)"

# --- Save config ---
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}
@"
CK_API_KEY="$apiKey"
CK_PERMISSION_MODE="$permMode"
CK_MODEL="$model"
CK_MAX_TOKENS="$maxTokens"
"@ | Set-Content -Path $ConfigFile -Encoding UTF8

# --- Install script ---
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Copy-Item (Join-Path $ScriptDir "claude-k.ps1") (Join-Path $InstallDir "claude-k.ps1") -Force

# Create cmd wrapper so 'claude-k' works from cmd.exe and PowerShell
@"
@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0claude-k.ps1" %*
exit /b %errorlevel%
"@ | Set-Content -Path (Join-Path $InstallDir "claude-k.cmd") -Encoding ASCII

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
Write-Host "  Done! claude-k is ready (Kimi)."
Write-Host ""
Write-Host "  Usage:"
Write-Host "    claude-k                -- start Claude Code via Kimi"
Write-Host "    claude-k reconfig       -- change settings"
Write-Host "    claude-k -p `"prompt`"    -- one-shot query"
Write-Host ""
Write-Host "  Config: $ConfigFile"
Write-Host "  Binary: $InstallDir\claude-k.cmd"
Write-Host "  ------------------------------------"
Write-Host ""

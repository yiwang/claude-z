# uninstall-o.ps1 — remove claude-o (Windows)
$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  Uninstalling claude-o..."
Write-Host ""

$removed = 0
$InstallDir = Join-Path $env:LOCALAPPDATA "claude-o"
$ConfigDir = Join-Path $env:APPDATA "claude-o"

if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
    Write-Host "  Removed: $InstallDir"
    $removed = 1
}

if (Test-Path $ConfigDir) {
    Remove-Item -Recurse -Force $ConfigDir
    Write-Host "  Removed: $ConfigDir"
    $removed = 1
}

# Clean PATH
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -like "*$InstallDir*") {
    $newPath = ($userPath -split ";" | Where-Object { $_ -ne $InstallDir }) -join ";"
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "  Removed $InstallDir from PATH."
}

if ($removed -eq 0) {
    Write-Host "  Nothing to remove. claude-o was not installed."
} else {
    Write-Host ""
    Write-Host "  Done. claude-o has been fully removed."
}
Write-Host ""

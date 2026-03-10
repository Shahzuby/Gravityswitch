#Requires -Version 5.1
# GravitySwitch Installer — Windows
$ErrorActionPreference = "Stop"

$GITHUB_USER  = "YOUR_GITHUB_USERNAME"
$GITHUB_REPO  = "GravitySwitch"
$BRANCH       = "main"
$SCRIPT_NAME  = "gravityswitch.ps1"
$RAW_URL      = "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/$SCRIPT_NAME"
$INSTALL_DIR  = Join-Path $env:APPDATA "GravitySwitch"
$INSTALL_PATH = Join-Path $INSTALL_DIR $SCRIPT_NAME
$PS_PROFILE   = $PROFILE.CurrentUserAllHosts

Write-Host ""
Write-Host "  ┌──────────────────────────────────────────┐" -ForegroundColor DarkCyan
Write-Host "  │   GravitySwitch — Installer (Windows)     │" -ForegroundColor DarkCyan
Write-Host "  └──────────────────────────────────────────┘" -ForegroundColor DarkCyan
Write-Host ""

# Create dir
if (-not (Test-Path $INSTALL_DIR)) { New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null }
Write-Host "  → Downloading gravityswitch..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $RAW_URL -OutFile $INSTALL_PATH -UseBasicParsing
Write-Host "  ✓ Saved to: $INSTALL_PATH" -ForegroundColor Green

# Add to PowerShell profile
$funcLine  = "function gravityswitch { & `"$INSTALL_PATH`" @args }"
$already   = (Test-Path $PS_PROFILE) -and ((Get-Content $PS_PROFILE -Raw -EA SilentlyContinue) -like "*$INSTALL_PATH*")

if (-not $already) {
    if (-not (Test-Path (Split-Path $PS_PROFILE))) { New-Item -ItemType Directory -Path (Split-Path $PS_PROFILE) -Force | Out-Null }
    if (-not (Test-Path $PS_PROFILE))              { New-Item -ItemType File -Path $PS_PROFILE -Force | Out-Null }
    Add-Content $PS_PROFILE ""
    Add-Content $PS_PROFILE "# GravitySwitch"
    Add-Content $PS_PROFILE $funcLine
    Write-Host "  ✓ Added to PowerShell profile" -ForegroundColor Green
}

Invoke-Expression $funcLine

Write-Host ""
Write-Host "  ✅ Done! Restart PowerShell, then:" -ForegroundColor Green
Write-Host ""
Write-Host "    gravityswitch new work" -ForegroundColor DarkGray
Write-Host "    gravityswitch new personal" -ForegroundColor DarkGray
Write-Host "    gravityswitch launch work" -ForegroundColor DarkGray
Write-Host "    gravityswitch help" -ForegroundColor DarkGray
Write-Host ""

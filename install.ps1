#Requires -Version 5.1
<#
.SYNOPSIS
    Installer for Antigravity Profiles CLI
.DESCRIPTION
    Downloads and installs antigravity-profiles to your system.
    Run this in PowerShell (no admin required).
#>

$ErrorActionPreference = "Stop"

# ─── CONFIG ──────────────────────────────────────────────────────────────────

# Change this to your own GitHub repo once you upload it
$GITHUB_USER   = "YOUR_GITHUB_USERNAME"
$GITHUB_REPO   = "antigravity-profiles"
$BRANCH        = "main"
$SCRIPT_NAME   = "antigravity-profiles.ps1"
$RAW_URL       = "https://raw.githubusercontent.com/$GITHUB_USER/$GITHUB_REPO/$BRANCH/$SCRIPT_NAME"

# Install location (no admin needed)
$INSTALL_DIR   = Join-Path $env:APPDATA "AntigravityProfilesCLI"
$INSTALL_PATH  = Join-Path $INSTALL_DIR $SCRIPT_NAME

# PowerShell profile path (so you can run the command from anywhere)
$PS_PROFILE    = $PROFILE.CurrentUserAllHosts

# ─── HELPERS ─────────────────────────────────────────────────────────────────

function Write-Step { param($msg) Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Err  { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

# ─── BANNER ──────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ┌──────────────────────────────────────────┐" -ForegroundColor DarkCyan
Write-Host "  │   Antigravity Profiles — Installer        │" -ForegroundColor DarkCyan
Write-Host "  └──────────────────────────────────────────┘" -ForegroundColor DarkCyan
Write-Host ""

# ─── INSTALL ─────────────────────────────────────────────────────────────────

# 1. Create install dir
Write-Step "Creating install directory..."
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}
Write-OK "Directory: $INSTALL_DIR"

# 2. Download the script
Write-Step "Downloading antigravity-profiles..."
try {
    Invoke-WebRequest -Uri $RAW_URL -OutFile $INSTALL_PATH -UseBasicParsing
} catch {
    Write-Err "Download failed. Check your internet connection or the GitHub URL."
}
Write-OK "Script saved to: $INSTALL_PATH"

# 3. Add function alias to PowerShell profile
Write-Step "Adding 'antigravity-profiles' command to your PowerShell profile..."

$funcLine = "function antigravity-profiles { & `"$INSTALL_PATH`" @args }"
$aliasLine = "Set-Alias agy-profiles antigravity-profiles"

$alreadySetup = $false
if (Test-Path $PS_PROFILE) {
    $existing = Get-Content $PS_PROFILE -Raw -ErrorAction SilentlyContinue
    if ($existing -and $existing.Contains($INSTALL_PATH)) {
        $alreadySetup = $true
    }
}

if (-not $alreadySetup) {
    # Make sure profile file exists
    if (-not (Test-Path (Split-Path $PS_PROFILE))) {
        New-Item -ItemType Directory -Path (Split-Path $PS_PROFILE) -Force | Out-Null
    }
    if (-not (Test-Path $PS_PROFILE)) {
        New-Item -ItemType File -Path $PS_PROFILE -Force | Out-Null
    }

    Add-Content -Path $PS_PROFILE -Value ""
    Add-Content -Path $PS_PROFILE -Value "# Antigravity Profiles CLI"
    Add-Content -Path $PS_PROFILE -Value $funcLine
    Add-Content -Path $PS_PROFILE -Value $aliasLine

    Write-OK "Added to profile: $PS_PROFILE"
} else {
    Write-OK "Already in profile — skipping."
}

# 4. Load into current session immediately
Invoke-Expression $funcLine
Invoke-Expression $aliasLine

# ─── DONE ────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ✅ Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "  Restart PowerShell or run: . `$PROFILE" -ForegroundColor Yellow
Write-Host ""
Write-Host "  Quick start:" -ForegroundColor White
Write-Host "    antigravity-profiles new work" -ForegroundColor DarkGray
Write-Host "    antigravity-profiles new personal" -ForegroundColor DarkGray
Write-Host "    antigravity-profiles launch work" -ForegroundColor DarkGray
Write-Host "    antigravity-profiles help" -ForegroundColor DarkGray
Write-Host ""

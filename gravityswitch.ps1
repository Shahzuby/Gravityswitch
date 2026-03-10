#Requires -Version 5.1
<#
.SYNOPSIS
    GravitySwitch — Run multiple Antigravity IDE profiles simultaneously on Windows
.DESCRIPTION
    Create, manage and launch isolated Antigravity IDE profiles.
    Each profile has its own accounts, settings, and extensions.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── CONFIG ──────────────────────────────────────────────────────────────────

$TOOL_VERSION = "1.0.0"
$PROFILES_DIR = Join-Path $env:APPDATA "GravitySwitch\profiles"

$AGY_EXE_PATHS = @(
    "$env:LOCALAPPDATA\Programs\Antigravity\antigravity.exe",
    "$env:LOCALAPPDATA\antigravity\antigravity.exe",
    "C:\Program Files\Google\Antigravity\antigravity.exe",
    "C:\Program Files (x86)\Google\Antigravity\antigravity.exe"
)

$SHORTCUT_DIR = Join-Path ([Environment]::GetFolderPath("Programs")) "GravitySwitch"

# ─── COLOURS ─────────────────────────────────────────────────────────────────

function Write-Step  { param($msg) Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red }
function Write-Title { param($msg) Write-Host "`n  $msg" -ForegroundColor White }

function Write-Banner {
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │   GravitySwitch  v$TOOL_VERSION                    │" -ForegroundColor DarkCyan
    Write-Host "  │   Run multiple accounts at the same time  │" -ForegroundColor DarkCyan
    Write-Host "  └──────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

# ─── HELPERS ─────────────────────────────────────────────────────────────────

function Find-AntigravityExe {
    foreach ($path in $AGY_EXE_PATHS) {
        if (Test-Path $path) { return $path }
    }
    $fromPath = Get-Command "antigravity" -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    return $null
}

function Assert-AntigravityInstalled {
    $exe = Find-AntigravityExe
    if (-not $exe) {
        Write-Err "Antigravity IDE not found."
        Write-Host "  Install from: https://antigravity.google" -ForegroundColor Gray
        exit 1
    }
    return $exe
}

function Validate-ProfileName {
    param([string]$name)
    if ($name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9\-]*$') {
        Write-Err "Invalid profile name: '$name'"
        Write-Host "  Letters, numbers, hyphens only. Must start with letter or number." -ForegroundColor Gray
        exit 1
    }
}

function Get-ProfilePath   { param([string]$n) Join-Path $PROFILES_DIR $n }
function Profile-Exists    { param([string]$n) Test-Path (Get-ProfilePath $n) }
function Ensure-ProfilesDir { if (-not (Test-Path $PROFILES_DIR)) { New-Item -ItemType Directory -Path $PROFILES_DIR -Force | Out-Null } }

function Get-AllProfiles {
    if (-not (Test-Path $PROFILES_DIR)) { return @() }
    Get-ChildItem -Path $PROFILES_DIR -Directory | Select-Object -ExpandProperty Name | Sort-Object
}

# ─── SHORTCUT ────────────────────────────────────────────────────────────────

function Create-Shortcut {
    param([string]$profileName, [string]$exePath)
    if (-not (Test-Path $SHORTCUT_DIR)) { New-Item -ItemType Directory -Path $SHORTCUT_DIR -Force | Out-Null }

    $shortcutPath = Join-Path $SHORTCUT_DIR "Antigravity [$profileName].lnk"
    $scriptPath   = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.ScriptName }

    $wsh = New-Object -ComObject WScript.Shell
    $sc  = $wsh.CreateShortcut($shortcutPath)
    $sc.TargetPath       = "powershell.exe"
    $sc.Arguments        = "-ExecutionPolicy Bypass -File `"$scriptPath`" launch `"$profileName`""
    $sc.WorkingDirectory = Split-Path $exePath
    $sc.Description      = "Antigravity IDE — GravitySwitch profile: $profileName"
    $sc.IconLocation     = "$exePath,0"
    $sc.Save()
    Write-OK "Shortcut: Start Menu → GravitySwitch → Antigravity [$profileName]"
}

function Remove-Shortcut {
    param([string]$profileName)
    $shortcutPath = Join-Path $SHORTCUT_DIR "Antigravity [$profileName].lnk"
    if (Test-Path $shortcutPath) { Remove-Item $shortcutPath -Force; Write-OK "Shortcut removed." }
}

# ─── COMMANDS ────────────────────────────────────────────────────────────────

function Cmd-New {
    param([string]$name)
    Validate-ProfileName $name
    Ensure-ProfilesDir
    if (Profile-Exists $name) { Write-Err "Profile '$name' already exists."; exit 1 }
    New-Item -ItemType Directory -Path (Get-ProfilePath $name) -Force | Out-Null
    Write-OK "Profile '$name' created."
    Create-Shortcut -profileName $name -exePath (Assert-AntigravityInstalled)
}

function Cmd-Launch {
    param([string]$name, [string[]]$extraArgs)
    Validate-ProfileName $name
    if (-not (Profile-Exists $name)) { Write-Err "Profile '$name' not found. Run: gravityswitch new $name"; exit 1 }

    $exe         = Assert-AntigravityInstalled
    $userDataDir = Join-Path (Get-ProfilePath $name) "userdata"
    if (-not (Test-Path $userDataDir)) { New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null }

    Write-Step "Launching Antigravity with profile '$name'..."
    Start-Process -FilePath $exe -ArgumentList (@("--user-data-dir=`"$userDataDir`"") + $extraArgs)
    Write-OK "Antigravity launched with profile '$name'."
}

function Cmd-List {
    $profiles = Get-AllProfiles
    if ($profiles.Count -eq 0) { Write-Warn "No profiles yet. Run: gravityswitch new <n>"; return }

    Write-Title "Your profiles ($($profiles.Count)):"
    Write-Host ""
    foreach ($p in $profiles) {
        $bytes = try { (Get-ChildItem (Get-ProfilePath $p) -Recurse -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch { 0 }
        $size  = if ($bytes -gt 1MB) { "{0:N1} MB" -f ($bytes/1MB) } elseif ($bytes -gt 1KB) { "{0:N1} KB" -f ($bytes/1KB) } else { "$bytes B" }
        Write-Host "    ● $p" -ForegroundColor Cyan -NoNewline
        Write-Host "  ($size)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Cmd-Clone {
    param([string]$src, [string]$dest)
    Validate-ProfileName $src; Validate-ProfileName $dest; Ensure-ProfilesDir
    if (-not (Profile-Exists $src))  { Write-Err "Source '$src' not found."; exit 1 }
    if (Profile-Exists $dest)        { Write-Err "Destination '$dest' already exists."; exit 1 }
    Write-Step "Cloning '$src' → '$dest'..."
    Copy-Item -Path (Get-ProfilePath $src) -Destination (Get-ProfilePath $dest) -Recurse -Force
    Write-OK "Profile '$dest' cloned."
    Create-Shortcut -profileName $dest -exePath (Assert-AntigravityInstalled)
}

function Cmd-Rename {
    param([string]$old, [string]$new)
    Validate-ProfileName $old; Validate-ProfileName $new
    if (-not (Profile-Exists $old)) { Write-Err "Profile '$old' not found."; exit 1 }
    if (Profile-Exists $new)        { Write-Err "Profile '$new' already exists."; exit 1 }
    Rename-Item -Path (Get-ProfilePath $old) -NewName $new
    Remove-Shortcut -profileName $old
    Create-Shortcut -profileName $new -exePath (Assert-AntigravityInstalled)
    Write-OK "Renamed '$old' → '$new'."
}

function Cmd-Delete {
    param([string]$name)
    Validate-ProfileName $name
    if (-not (Profile-Exists $name)) { Write-Err "Profile '$name' not found."; exit 1 }
    Write-Warn "This will permanently delete '$name' and all its data."
    Write-Host "  Path: $(Get-ProfilePath $name)" -ForegroundColor DarkGray
    $confirm = Read-Host "`n  Type the profile name to confirm"
    if ($confirm -ne $name) { Write-Host "  Cancelled." -ForegroundColor Yellow; return }
    Remove-Item -Path (Get-ProfilePath $name) -Recurse -Force
    Remove-Shortcut -profileName $name
    Write-OK "Profile '$name' deleted."
}

function Cmd-Doctor {
    Write-Title "System check:"; Write-Host ""
    $exe = Find-AntigravityExe
    if ($exe) { Write-OK "Antigravity: $exe" } else { Write-Err "Antigravity not found." }
    if (Test-Path $PROFILES_DIR) { Write-OK "Profiles dir: $PROFILES_DIR" } else { Write-Warn "Profiles dir not yet created." }
    Write-OK "PowerShell: $($PSVersionTable.PSVersion)"
    try { New-Object -ComObject WScript.Shell | Out-Null; Write-OK "WScript available (shortcuts OK)." } catch { Write-Warn "WScript unavailable — shortcuts may fail." }
    Write-Host ""
}

function Cmd-Stats {
    $profiles = Get-AllProfiles
    if ($profiles.Count -eq 0) { Write-Warn "No profiles yet."; return }
    Write-Title "Storage usage:"; Write-Host ""
    $total = 0
    foreach ($p in $profiles) {
        $bytes = try { (Get-ChildItem (Get-ProfilePath $p) -Recurse -EA SilentlyContinue | Measure-Object -Property Length -Sum).Sum } catch { 0 }
        $total += $bytes
        $size  = if ($bytes -gt 1MB) { "{0:N1} MB" -f ($bytes/1MB) } elseif ($bytes -gt 1KB) { "{0:N1} KB" -f ($bytes/1KB) } else { "$bytes B" }
        Write-Host ("    {0,-20} {1}" -f $p, $size) -ForegroundColor Cyan
    }
    $ts = if ($total -gt 1MB) { "{0:N1} MB" -f ($total/1MB) } elseif ($total -gt 1KB) { "{0:N1} KB" -f ($total/1KB) } else { "$total B" }
    Write-Host "`n    Total: $ts" -ForegroundColor White; Write-Host ""
}

function Cmd-Help {
    Write-Banner
    Write-Host "  USAGE:" -ForegroundColor White
    Write-Host "    gravityswitch <command> [arguments]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  COMMANDS:" -ForegroundColor White
    @(
        "new <n>               Create a new profile",
        "launch <n> [args...]  Open Antigravity with that profile",
        "list                  Show all profiles",
        "clone <src> <dest>    Copy a profile",
        "rename <old> <new>    Rename a profile",
        "delete <n>            Delete a profile (asks confirmation)",
        "doctor                Check system setup",
        "stats                 Show storage usage",
        "help                  Show this help"
    ) | ForEach-Object { Write-Host "    $_" -ForegroundColor Cyan }
    Write-Host ""
    Write-Host "  EXAMPLES:" -ForegroundColor White
    Write-Host "    gravityswitch new work" -ForegroundColor DarkGray
    Write-Host "    gravityswitch launch work" -ForegroundColor DarkGray
    Write-Host "    gravityswitch work          # shortcut — no 'launch' needed" -ForegroundColor DarkGray
    Write-Host "    gravityswitch clone work work-backup" -ForegroundColor DarkGray
    Write-Host ""
}

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────

$CMD = if ($args.Count -gt 0) { $args[0] } else { "help" }

switch ($CMD.ToLower()) {
    "new"                           { if ($args.Count -lt 2) { Write-Err "Usage: gravityswitch new <n>"; exit 1 }; Write-Banner; Cmd-New $args[1] }
    { $_ -in "launch","open","run"} { if ($args.Count -lt 2) { Write-Err "Usage: gravityswitch launch <n>"; exit 1 }; $extra = if ($args.Count -gt 2) { $args[2..($args.Count-1)] } else { @() }; Cmd-Launch $args[1] $extra }
    "list"                          { Write-Banner; Cmd-List }
    "clone"                         { if ($args.Count -lt 3) { Write-Err "Usage: gravityswitch clone <src> <dest>"; exit 1 }; Write-Banner; Cmd-Clone $args[1] $args[2] }
    "rename"                        { if ($args.Count -lt 3) { Write-Err "Usage: gravityswitch rename <old> <new>"; exit 1 }; Write-Banner; Cmd-Rename $args[1] $args[2] }
    "delete"                        { if ($args.Count -lt 2) { Write-Err "Usage: gravityswitch delete <n>"; exit 1 }; Write-Banner; Cmd-Delete $args[1] }
    "doctor"                        { Write-Banner; Cmd-Doctor }
    "stats"                         { Write-Banner; Cmd-Stats }
    { $_ -in "help","--help","-h" } { Cmd-Help }
    default {
        if (Profile-Exists $CMD) {
            $extra = if ($args.Count -gt 1) { $args[1..($args.Count-1)] } else { @() }
            Cmd-Launch $CMD $extra
        } else {
            Write-Err "Unknown command: '$CMD'. Run 'gravityswitch help'."
            exit 1
        }
    }
}

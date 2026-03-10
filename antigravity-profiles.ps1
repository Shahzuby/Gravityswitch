#Requires -Version 5.1
<#
.SYNOPSIS
    Antigravity Profiles - Run multiple Antigravity IDE accounts simultaneously on Windows
.DESCRIPTION
    Create, manage and launch isolated Antigravity IDE profiles.
    Each profile has its own accounts, settings, and extensions.
.AUTHOR
    Your own tool — not based on any third party code.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ─── CONFIG ──────────────────────────────────────────────────────────────────

$TOOL_NAME    = "antigravity-profiles"
$TOOL_VERSION = "1.0.0"

# Where Antigravity stores its user data on Windows
$AGY_APPDATA_BASE = Join-Path $env:APPDATA "Antigravity"

# Where we store profiles
$PROFILES_DIR = Join-Path $env:APPDATA "AntigravityProfiles"

# Where Antigravity executable usually lives
$AGY_EXE_PATHS = @(
    "$env:LOCALAPPDATA\Programs\Antigravity\antigravity.exe",
    "$env:LOCALAPPDATA\antigravity\antigravity.exe",
    "C:\Program Files\Google\Antigravity\antigravity.exe",
    "C:\Program Files (x86)\Google\Antigravity\antigravity.exe"
)

# Start Menu shortcut folder
$SHORTCUT_DIR = Join-Path ([Environment]::GetFolderPath("Programs")) "Antigravity Profiles"

# ─── COLOURS ─────────────────────────────────────────────────────────────────

function Write-Step  { param($msg) Write-Host "  → $msg" -ForegroundColor Cyan }
function Write-OK    { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Warn  { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Err   { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red }
function Write-Title { param($msg) Write-Host "`n  $msg" -ForegroundColor White }

function Write-Banner {
    Write-Host ""
    Write-Host "  ┌──────────────────────────────────────────┐" -ForegroundColor DarkCyan
    Write-Host "  │   Antigravity Profiles  v$TOOL_VERSION            │" -ForegroundColor DarkCyan
    Write-Host "  │   Run multiple accounts at the same time  │" -ForegroundColor DarkCyan
    Write-Host "  └──────────────────────────────────────────┘" -ForegroundColor DarkCyan
    Write-Host ""
}

# ─── HELPERS ─────────────────────────────────────────────────────────────────

function Find-AntigravityExe {
    foreach ($path in $AGY_EXE_PATHS) {
        if (Test-Path $path) { return $path }
    }
    # Try PATH
    $fromPath = Get-Command "antigravity" -ErrorAction SilentlyContinue
    if ($fromPath) { return $fromPath.Source }
    return $null
}

function Assert-AntigravityInstalled {
    $exe = Find-AntigravityExe
    if (-not $exe) {
        Write-Err "Antigravity IDE not found on this system."
        Write-Host "  Please install it from: https://antigravity.google" -ForegroundColor Gray
        exit 1
    }
    return $exe
}

function Validate-ProfileName {
    param([string]$name)
    if ($name -notmatch '^[a-zA-Z0-9][a-zA-Z0-9\-]*$') {
        Write-Err "Invalid profile name: '$name'"
        Write-Host "  Rules: letters, numbers, hyphens only. Must start with a letter or number." -ForegroundColor Gray
        Write-Host "  OK  : work, personal, client-a, test1" -ForegroundColor Green
        Write-Host "  BAD : -name, my_profile, my profile" -ForegroundColor Red
        exit 1
    }
}

function Get-ProfilePath {
    param([string]$name)
    return Join-Path $PROFILES_DIR $name
}

function Profile-Exists {
    param([string]$name)
    return Test-Path (Get-ProfilePath $name)
}

function Get-AllProfiles {
    if (-not (Test-Path $PROFILES_DIR)) { return @() }
    return Get-ChildItem -Path $PROFILES_DIR -Directory | Select-Object -ExpandProperty Name | Sort-Object
}

function Ensure-ProfilesDir {
    if (-not (Test-Path $PROFILES_DIR)) {
        New-Item -ItemType Directory -Path $PROFILES_DIR -Force | Out-Null
    }
}

# ─── SHORTCUT ────────────────────────────────────────────────────────────────

function Create-Shortcut {
    param([string]$profileName, [string]$exePath)

    if (-not (Test-Path $SHORTCUT_DIR)) {
        New-Item -ItemType Directory -Path $SHORTCUT_DIR -Force | Out-Null
    }

    $shortcutPath = Join-Path $SHORTCUT_DIR "Antigravity [$profileName].lnk"
    $scriptPath   = $MyInvocation.ScriptName
    if (-not $scriptPath) { $scriptPath = $PSCommandPath }

    $wsh    = New-Object -ComObject WScript.Shell
    $sc     = $wsh.CreateShortcut($shortcutPath)
    $sc.TargetPath       = "powershell.exe"
    $sc.Arguments        = "-ExecutionPolicy Bypass -File `"$scriptPath`" launch `"$profileName`""
    $sc.WorkingDirectory = Split-Path $exePath
    $sc.Description      = "Antigravity IDE — profile: $profileName"
    $sc.IconLocation     = "$exePath,0"
    $sc.Save()

    Write-OK "Shortcut created: Start Menu → Antigravity Profiles → Antigravity [$profileName]"
}

function Remove-Shortcut {
    param([string]$profileName)
    $shortcutPath = Join-Path $SHORTCUT_DIR "Antigravity [$profileName].lnk"
    if (Test-Path $shortcutPath) {
        Remove-Item $shortcutPath -Force
        Write-OK "Shortcut removed."
    }
}

# ─── COMMANDS ────────────────────────────────────────────────────────────────

function Cmd-New {
    param([string]$name)
    Validate-ProfileName $name
    Ensure-ProfilesDir

    if (Profile-Exists $name) {
        Write-Err "Profile '$name' already exists."
        exit 1
    }

    $profileDir = Get-ProfilePath $name
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null

    Write-OK "Profile '$name' created at: $profileDir"

    $exe = Assert-AntigravityInstalled
    Create-Shortcut -profileName $name -exePath $exe
}

function Cmd-Launch {
    param([string]$name, [string[]]$extraArgs)
    Validate-ProfileName $name

    if (-not (Profile-Exists $name)) {
        Write-Err "Profile '$name' does not exist."
        Write-Host "  Create it first: antigravity-profiles new $name" -ForegroundColor Gray
        exit 1
    }

    $exe        = Assert-AntigravityInstalled
    $profileDir = Get-ProfilePath $name
    $userDataDir = Join-Path $profileDir "userdata"

    if (-not (Test-Path $userDataDir)) {
        New-Item -ItemType Directory -Path $userDataDir -Force | Out-Null
    }

    Write-Step "Launching Antigravity with profile '$name'..."

    $startArgs = @("--user-data-dir=`"$userDataDir`"") + $extraArgs

    Start-Process -FilePath $exe -ArgumentList $startArgs -WindowStyle Normal
    Write-OK "Antigravity launched with profile '$name'."
}

function Cmd-List {
    $profiles = Get-AllProfiles

    if ($profiles.Count -eq 0) {
        Write-Warn "No profiles yet. Create one:"
        Write-Host "  antigravity-profiles new <name>" -ForegroundColor Gray
        return
    }

    Write-Title "Your profiles ($($profiles.Count)):"
    Write-Host ""
    foreach ($p in $profiles) {
        $dir  = Get-ProfilePath $p
        $size = try {
            $bytes = (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
            if ($bytes -gt 1MB) { "{0:N1} MB" -f ($bytes / 1MB) }
            elseif ($bytes -gt 1KB) { "{0:N1} KB" -f ($bytes / 1KB) }
            else { "$bytes B" }
        } catch { "?" }
        Write-Host "    ● $p" -ForegroundColor Cyan -NoNewline
        Write-Host "  ($size)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

function Cmd-Clone {
    param([string]$source, [string]$dest)
    Validate-ProfileName $source
    Validate-ProfileName $dest
    Ensure-ProfilesDir

    if (-not (Profile-Exists $source)) {
        Write-Err "Source profile '$source' does not exist."
        exit 1
    }
    if (Profile-Exists $dest) {
        Write-Err "Destination profile '$dest' already exists."
        exit 1
    }

    $srcDir  = Get-ProfilePath $source
    $destDir = Get-ProfilePath $dest

    Write-Step "Cloning '$source' → '$dest'..."
    Copy-Item -Path $srcDir -Destination $destDir -Recurse -Force
    Write-OK "Profile '$dest' cloned from '$source'."

    $exe = Assert-AntigravityInstalled
    Create-Shortcut -profileName $dest -exePath $exe
}

function Cmd-Rename {
    param([string]$oldName, [string]$newName)
    Validate-ProfileName $oldName
    Validate-ProfileName $newName

    if (-not (Profile-Exists $oldName)) {
        Write-Err "Profile '$oldName' does not exist."
        exit 1
    }
    if (Profile-Exists $newName) {
        Write-Err "Profile '$newName' already exists."
        exit 1
    }

    $oldDir = Get-ProfilePath $oldName
    $newDir = Get-ProfilePath $newName
    Rename-Item -Path $oldDir -NewName $newName
    Remove-Shortcut -profileName $oldName

    $exe = Assert-AntigravityInstalled
    Create-Shortcut -profileName $newName -exePath $exe
    Write-OK "Profile renamed: '$oldName' → '$newName'."
}

function Cmd-Delete {
    param([string]$name)
    Validate-ProfileName $name

    if (-not (Profile-Exists $name)) {
        Write-Err "Profile '$name' does not exist."
        exit 1
    }

    $profileDir = Get-ProfilePath $name
    Write-Warn "This will permanently delete profile '$name' and all its data."
    Write-Host "  Path: $profileDir" -ForegroundColor DarkGray
    Write-Host ""
    $confirm = Read-Host "  Type the profile name to confirm deletion"

    if ($confirm -ne $name) {
        Write-Host "  Cancelled." -ForegroundColor Yellow
        return
    }

    Remove-Item -Path $profileDir -Recurse -Force
    Remove-Shortcut -profileName $name
    Write-OK "Profile '$name' deleted."
}

function Cmd-Doctor {
    Write-Title "System check:"
    Write-Host ""

    # Check Antigravity exe
    $exe = Find-AntigravityExe
    if ($exe) {
        Write-OK "Antigravity found: $exe"
    } else {
        Write-Err "Antigravity not found. Install from https://antigravity.google"
    }

    # Check profiles dir
    if (Test-Path $PROFILES_DIR) {
        Write-OK "Profiles directory: $PROFILES_DIR"
    } else {
        Write-Warn "Profiles directory not yet created (will be created on first 'new')."
    }

    # Check default Antigravity data folder
    if (Test-Path $AGY_APPDATA_BASE) {
        Write-OK "Antigravity AppData found: $AGY_APPDATA_BASE"
    } else {
        Write-Warn "Antigravity AppData not found (might not have launched yet)."
    }

    # Check PowerShell version
    $psVer = $PSVersionTable.PSVersion.ToString()
    Write-OK "PowerShell version: $psVer"

    # Check WScript (needed for shortcuts)
    try {
        New-Object -ComObject WScript.Shell | Out-Null
        Write-OK "WScript.Shell available (shortcuts will work)."
    } catch {
        Write-Warn "WScript.Shell not available — shortcuts may not work."
    }

    Write-Host ""
}

function Cmd-Stats {
    $profiles = Get-AllProfiles

    if ($profiles.Count -eq 0) {
        Write-Warn "No profiles yet."
        return
    }

    Write-Title "Storage usage:"
    Write-Host ""

    $totalBytes = 0
    foreach ($p in $profiles) {
        $dir = Get-ProfilePath $p
        $bytes = try {
            (Get-ChildItem $dir -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        } catch { 0 }
        $totalBytes += $bytes
        $display = if ($bytes -gt 1MB) { "{0:N1} MB" -f ($bytes / 1MB) }
                   elseif ($bytes -gt 1KB) { "{0:N1} KB" -f ($bytes / 1KB) }
                   else { "$bytes B" }
        Write-Host ("    {0,-20} {1}" -f $p, $display) -ForegroundColor Cyan
    }

    Write-Host ""
    $totalDisplay = if ($totalBytes -gt 1MB) { "{0:N1} MB" -f ($totalBytes / 1MB) }
                    elseif ($totalBytes -gt 1KB) { "{0:N1} KB" -f ($totalBytes / 1KB) }
                    else { "$totalBytes B" }
    Write-Host "    Total: $totalDisplay" -ForegroundColor White
    Write-Host ""
}

function Cmd-Help {
    Write-Banner
    Write-Host "  USAGE:" -ForegroundColor White
    Write-Host ""
    Write-Host "    antigravity-profiles <command> [arguments]" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  COMMANDS:" -ForegroundColor White
    Write-Host ""
    Write-Host "    new <name>               Create a new profile" -ForegroundColor Cyan
    Write-Host "    launch <name> [args...]  Open Antigravity with that profile" -ForegroundColor Cyan
    Write-Host "    list                     Show all profiles" -ForegroundColor Cyan
    Write-Host "    clone <src> <dest>       Copy a profile" -ForegroundColor Cyan
    Write-Host "    rename <old> <new>       Rename a profile" -ForegroundColor Cyan
    Write-Host "    delete <name>            Delete a profile (asks to confirm)" -ForegroundColor Cyan
    Write-Host "    doctor                   Check if everything is set up correctly" -ForegroundColor Cyan
    Write-Host "    stats                    Show storage usage per profile" -ForegroundColor Cyan
    Write-Host "    help                     Show this help" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  EXAMPLES:" -ForegroundColor White
    Write-Host ""
    Write-Host "    antigravity-profiles new work" -ForegroundColor DarkGray
    Write-Host "    antigravity-profiles new personal" -ForegroundColor DarkGray
    Write-Host "    antigravity-profiles launch work" -ForegroundColor DarkGray
    Write-Host "    antigravity-profiles launch work --new-window" -ForegroundColor DarkGray
    Write-Host "    antigravity-profiles clone work work-backup" -ForegroundColor DarkGray
    Write-Host "    antigravity-profiles list" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  PROFILE NAME RULES:" -ForegroundColor White
    Write-Host "    ✓ work, personal, client-a, test1" -ForegroundColor Green
    Write-Host "    ✗ -name, my_profile, my profile" -ForegroundColor Red
    Write-Host ""
}

# ─── ENTRY POINT ─────────────────────────────────────────────────────────────

$command = if ($args.Count -gt 0) { $args[0] } else { "help" }

switch ($command.ToLower()) {

    "new" {
        if ($args.Count -lt 2) { Write-Err "Usage: antigravity-profiles new <name>"; exit 1 }
        Write-Banner
        Cmd-New -name $args[1]
    }

    { $_ -in "launch", "open", "run" } {
        if ($args.Count -lt 2) { Write-Err "Usage: antigravity-profiles launch <name> [args...]"; exit 1 }
        $extra = if ($args.Count -gt 2) { $args[2..($args.Count-1)] } else { @() }
        Cmd-Launch -name $args[1] -extraArgs $extra
    }

    "list" {
        Write-Banner
        Cmd-List
    }

    "clone" {
        if ($args.Count -lt 3) { Write-Err "Usage: antigravity-profiles clone <source> <destination>"; exit 1 }
        Write-Banner
        Cmd-Clone -source $args[1] -dest $args[2]
    }

    "rename" {
        if ($args.Count -lt 3) { Write-Err "Usage: antigravity-profiles rename <old-name> <new-name>"; exit 1 }
        Write-Banner
        Cmd-Rename -oldName $args[1] -newName $args[2]
    }

    "delete" {
        if ($args.Count -lt 2) { Write-Err "Usage: antigravity-profiles delete <name>"; exit 1 }
        Write-Banner
        Cmd-Delete -name $args[1]
    }

    "doctor" {
        Write-Banner
        Cmd-Doctor
    }

    "stats" {
        Write-Banner
        Cmd-Stats
    }

    { $_ -in "help", "--help", "-h", "-?" } {
        Cmd-Help
    }

    default {
        # Treat unknown arg as a profile name to launch (convenience shortcut)
        $profileName = $command
        if (Profile-Exists $profileName) {
            $extra = if ($args.Count -gt 1) { $args[1..($args.Count-1)] } else { @() }
            Cmd-Launch -name $profileName -extraArgs $extra
        } else {
            Write-Err "Unknown command: '$command'"
            Write-Host "  Run 'antigravity-profiles help' to see all commands." -ForegroundColor Gray
            exit 1
        }
    }
}

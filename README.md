# GravitySwitch

**Run multiple Antigravity IDE accounts simultaneously — Windows & macOS.**

No more logging in and out. Switch profiles instantly or use them all at once.

---

## Install

### Windows (PowerShell)
```powershell
irm https://raw.githubusercontent.com/Shahzuby/Gravityswitch/main/install.ps1 | iex
```

### macOS (Terminal)
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Shahzuby/Gravityswitch/main/install.sh)"
```

---

## Getting Started

```bash
# Create profiles
gravityswitch new work
gravityswitch new personal

# Launch a profile
gravityswitch launch work

# Shortcut — no need to type 'launch'
gravityswitch work
```

---

## Commands

| Command | Description |
|---|---|
| `gravityswitch new <n>` | Create a new profile |
| `gravityswitch launch <n>` | Open Antigravity with that profile |
| `gravityswitch <n>` | Shortcut — same as launch |
| `gravityswitch list` | Show all profiles |
| `gravityswitch clone <src> <dest>` | Copy a profile |
| `gravityswitch rename <old> <new>` | Rename a profile |
| `gravityswitch delete <n>` | Delete a profile (asks confirmation) |
| `gravityswitch doctor` | Check system setup |
| `gravityswitch stats` | Show storage usage per profile |
| `gravityswitch help` | Show help |

---

## How It Works

Each profile gets its own isolated data folder — separate accounts, extensions, and settings. Profiles never interfere with each other.

```
Windows:  %APPDATA%\GravitySwitch\profiles\work\userdata\
macOS:    ~/.gravityswitch/profiles/work/userdata/
```

---

## App Shortcuts

Every profile automatically gets a clickable launcher:

| Platform | Location |
|---|---|
| **Windows** | Start Menu → GravitySwitch → Antigravity [work] |
| **macOS** | ~/Applications/Antigravity [work].app |

---

## Profile Name Rules

- Letters, numbers, and hyphens only
- Must start with a letter or number
- ✅ `work`, `personal`, `client-a`, `test1`
- ❌ `-name`, `my_profile`, `my profile`

---

## Requirements

| Platform | Requirements |
|---|---|
| Windows | Windows 10/11, PowerShell 5.1+ |
| macOS | macOS 11+, Bash |

Antigravity IDE must be installed.

---

## License

MIT — free to use, modify, and share.

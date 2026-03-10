# Antigravity Profiles

**Windows pe multiple Antigravity IDE accounts ek saath chalao.**

Ek hi machine pe alag alag Google accounts, settings aur extensions — bina login/logout ke.

---

## Install

PowerShell mein yeh paste karo:

```powershell
irm https://raw.githubusercontent.com/YOUR_USERNAME/antigravity-profiles/main/install.ps1 | iex
```

---

## Commands

| Command | Kya karta hai |
|---|---|
| `antigravity-profiles new work` | Naya profile banao |
| `antigravity-profiles launch work` | Profile ke saath Antigravity kholo |
| `antigravity-profiles list` | Saare profiles dekho |
| `antigravity-profiles clone work work-copy` | Profile copy karo |
| `antigravity-profiles rename work freelance` | Profile ka naam badlo |
| `antigravity-profiles delete personal` | Profile delete karo |
| `antigravity-profiles doctor` | System check karo |
| `antigravity-profiles stats` | Storage usage dekho |
| `antigravity-profiles help` | Help dekho |

### Shortcut

Profile name seedha type karo — `launch` ki zaroorat nahi:

```powershell
antigravity-profiles work
antigravity-profiles work --new-window
antigravity-profiles work path\to\project
```

---

## Profile Ke Naam Ke Rules

- Letters, numbers, aur hyphens (`-`) hi allowed hain
- Letter ya number se shuru hona chahiye
- ✅ `work`, `personal`, `client-a`, `test1`
- ❌ `-name`, `my_profile`, `my profile`

---

## Kahan Data Save Hota Hai?

```
%APPDATA%\AntigravityProfiles\
    work\
        userdata\    ← work account ka isolated data
    personal\
        userdata\    ← personal account ka isolated data
```

Har profile ka data bilkul alag hota hai — ek profile doosre ko affect nahi karta.

---

## Start Menu Shortcuts

Har naye profile ke saath ek Start Menu shortcut bhi banta hai:

`Start Menu → Antigravity Profiles → Antigravity [work]`

---

## Requirements

- Windows 10 / 11
- PowerShell 5.1+
- Antigravity IDE installed

---

## License

MIT

# DefinitionSwitcher

## How to Build

This project uses **Invoke-Build**, **Inno Setup**, and the **PS2EXE** module to compile and package the PowerShell script.

### Prerequisites
1. **PowerShell 7+** (`winget install Microsoft.PowerShell`)
2. **Inno Setup** (`winget install JRSoftware.InnoSetup`)
3. **PS2EXE Module** (to compile `.ps1` to `.exe`)

### Steps
Make sure the **Inno Setup installation folder** (containing `ISCC.exe`) is added to your system's **PATH** environment variable.

Open **PowerShell 7** in the repository root directory and run:

```powershell
Install-Module ps2exe, InvokeBuild -Scope CurrentUser -Force
Invoke-Build
```

The compiled installer will be generated inside the `build/` folder.

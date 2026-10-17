# DefinitionSwitcher

## How to Build

This project uses **Invoke-Build** and **Inno Setup** to compile and generate the installer. 

### Prerequisites
1. **PowerShell 7+** (`winget install Microsoft.PowerShell`)
2. **Inno Setup** (`winget install JRSoftware.InnoSetup`)

### Steps
Make sure the **Inno Setup installation folder** (containing `ISCC.exe`) is added to your system's **PATH** environment variable.

Open **PowerShell 7** in the repository root directory and run:

```powershell
# 1. Install the task-runner framework
Install-Module InvokeBuild -Scope CurrentUser -Force

# 2. Create the required output directory
New-Item -ItemType Directory -Name "build" -Force

# 3. Run the compilation
Invoke-Build
```

The compiled installer will be generated inside the `build/` folder.

# ---------------------------------------------------------
# WINDOWS API BRIDGE (C#)
# ---------------------------------------------------------
$csharpSource = @"
using System;
using System.Runtime.InteropServices;

public class ScreenHelper {
    // 1. Import for changing resolution
    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    // 2. Import for refreshing the mouse cursor
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, IntPtr lpvParam, int fuWinIni);

    public const int SPI_SETCURSORS = 0x0057;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;

    [StructLayout(LayoutKind.Sequential)]
    public struct DEVMODE {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public short dmSpecVersion;
        public short dmDriverVersion;
        public short dmSize;
        public short dmDriverExtra;
        public int dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public int dmDisplayOrientation;
        public int dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public short dmLogPixels;
        public int dmBitsPerPel;
        public int dmPelsWidth;
        public int dmPelsHeight;
        public int dmDisplayFlags;
        public int dmDisplayFrequency;
    }

    // Helper to reload cursors fixes the pixelated mouse glitch
    public static void ReloadCursors() {
        SystemParametersInfo(SPI_SETCURSORS, 0, IntPtr.Zero, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }

    public static void SetDefinition(int width, int height) {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);
        dm.dmPelsWidth = width;
        dm.dmPelsHeight = height;
        dm.dmFields = 0x80000 | 0x100000; // DM_PELSWIDTH | DM_PELSHEIGHT
        
        // 1. Change Resolution
        ChangeDisplaySettings(ref dm, 0); 

        // 2. Fix the Mouse Cursor immediately
        ReloadCursors();
    }
}
"@

if (-not ("ScreenHelper" -as [type])) {
    Add-Type -TypeDefinition $csharpSource -Language CSharp
}

# ---------------------------------------------------------
# CONFIGURATION
# ---------------------------------------------------------
$SteamCommonPath = "D:\Programmes\Steam\steamapps\common\"
$SteamExePath = "D:\Programmes\Steam\steam.exe"

$HighResX = 2880
$HighResY = 1620
$NormalResX = 1920
$NormalResY = 1080

# ---------------------------------------------------------
# SINGLE INSTANCE CHECK
# ---------------------------------------------------------
$MutexName = "Global\DefinitionSwitcher"
$CreatedNew = $false
try {
    $null =New-Object System.Threading.Mutex($true, $MutexName, [ref]$CreatedNew)
} catch {
    $CreatedNew = $false
}
if (-not $CreatedNew) {
    Start-Process -FilePath $SteamExePath
    exit
}

# ---------------------------------------------------------
# LAUNCH STEAM IF NOT RUNNING
# ---------------------------------------------------------
$SteamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($null -eq $SteamProcess) {
    Start-Process -FilePath $SteamExePath
    Start-Sleep -Seconds 5
}

# ---------------------------------------------------------
# WATCH LOOP
# ---------------------------------------------------------
$CurrentGame = $null

while ($true) {
    
    # Check If Steam Running
    $SteamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    if ($null -eq $SteamProcess) {
        if ($CurrentGame) {
             [ScreenHelper]::SetDefinition($NormalResX, $NormalResY)
        }
        break 
    }

    # Detect If Game Running
    if ($null -eq $CurrentGame) {
        $DetectedGame = Get-Process | Where-Object { 
            try { $_.Path -like "$SteamCommonPath*" } catch { $false } 
        } | Select-Object -First 1

        if ($DetectedGame) {
            [ScreenHelper]::SetDefinition($HighResX, $HighResY)
            $CurrentGame = $DetectedGame
        }
    }
    else {
        if ($CurrentGame.HasExited) {
            [ScreenHelper]::SetDefinition($NormalResX, $NormalResY)
            $CurrentGame = $null
        }
    }

    Start-Sleep -Seconds 3
}
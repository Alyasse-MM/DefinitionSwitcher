# ---------------------------------------------------------
# 1. WINDOWS API BRIDGE (RESOLUTION & CURSORS)
# ---------------------------------------------------------

$csharpSource = @"
using System;
using System.Runtime.InteropServices;

public class ScreenHelper {
    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

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

    public static void ReloadCursors() {
        SystemParametersInfo(SPI_SETCURSORS, 0, IntPtr.Zero, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }

    public static void SetDefinition(int width, int height) {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);
        dm.dmPelsWidth = width;
        dm.dmPelsHeight = height;
        dm.dmFields = 0x80000 | 0x100000; 
        
        ChangeDisplaySettings(ref dm, 0); 
        ReloadCursors();
    }
}
"@

if (-not ("ScreenHelper" -as [type])) {
    Add-Type -TypeDefinition $csharpSource -Language CSharp
}

# ---------------------------------------------------------
# 2. CONFIGURATION
# ---------------------------------------------------------

$SteamExePath = "D:\Programmes\Steam\steam.exe"

# TV / Gaming Resolution
$HighResX = 2880
$HighResY = 1620

# Desktop / Work Resolution
$NormalResX = 1920
$NormalResY = 1080

# ---------------------------------------------------------
# 3. SINGLE INSTANCE CHECK
# ---------------------------------------------------------

$MutexName = "Global\DefinitionSwitcher"
$CreatedNew = $false
try {
    # Keep Mutex alive in Global scope to prevent Garbage Collection
    $Global:AppMutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$CreatedNew)
} catch {
    $CreatedNew = $false
}

if (-not $CreatedNew) {
    # If already running, just bring Steam to front
    Start-Process "steam://open/bigpicture"
    exit
}

# ---------------------------------------------------------
# 4. START SESSION (SWITCH TO 4K)
# ---------------------------------------------------------

# 1. Switch to High Res immediately (Before Steam / Games load)
[ScreenHelper]::SetDefinition($HighResX, $HighResY)

# 2. Launch Steam (if not running)
$SteamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($null -eq $SteamProcess) {
    # Launch in Big Picture Mode (Great for TV/High Res)
    Start-Process -FilePath $SteamExePath -ArgumentList "-bigpicture"
    Start-Sleep -Seconds 10
} else {
    # If Steam is already running, force it into Big Picture to match the new 4K res
    Start-Process "steam://open/bigpicture"
}

# ---------------------------------------------------------
# 5. WAIT FOR SESSION TO END
# ---------------------------------------------------------

while ($true) {
    $SteamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    
    # If Steam closes, we end the session
    if ($null -eq $SteamProcess) {
        break 
    }

    # Low CPU usage wait
    Start-Sleep -Seconds 3
}

# ---------------------------------------------------------
# 6. CLEANUP (SWITCH TO 1080p)
# ---------------------------------------------------------

[ScreenHelper]::SetDefinition($NormalResX, $NormalResY)
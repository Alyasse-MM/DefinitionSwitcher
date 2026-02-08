# ---------------------------------------------------------
# 1. WINDOWS API BRIDGE (C#)
# ---------------------------------------------------------

$csharpSource = @"
using System;
using System.Runtime.InteropServices;

public class ScreenHelper {
    [DllImport("user32.dll")]
    public static extern int ChangeDisplaySettings(ref DEVMODE devMode, int flags);

    [DllImport("user32.dll")]
    public static extern bool EnumDisplaySettings(string deviceName, int modeNum, ref DEVMODE devMode);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, IntPtr lpvParam, int fuWinIni);

    public const int SPI_SETCURSORS = 0x0057;
    public const int SPIF_UPDATEINIFILE = 0x01;
    public const int SPIF_SENDCHANGE = 0x02;
    public const int ENUM_CURRENT_SETTINGS = -1;

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

    // 1. Set Resolution & Fix Cursor
    public static void Set(int width, int height) {
        DEVMODE dm = new DEVMODE();
        dm.dmSize = (short)Marshal.SizeOf(dm);
        dm.dmPelsWidth = width;
        dm.dmPelsHeight = height;
        dm.dmFields = 0x80000 | 0x100000; 
        ChangeDisplaySettings(ref dm, 0); 
        SystemParametersInfo(SPI_SETCURSORS, 0, IntPtr.Zero, SPIF_UPDATEINIFILE | SPIF_SENDCHANGE);
    }

    // 2. Check if current resolution matches target
    public static bool Is(int width, int height) {
       DEVMODE dm = new DEVMODE();
       dm.dmSize = (short)Marshal.SizeOf(dm);
       EnumDisplaySettings(null, ENUM_CURRENT_SETTINGS, ref dm);
       return (dm.dmPelsWidth == width && dm.dmPelsHeight == height);
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

$HighResX = 2880
$HighResY = 1620

$NormalResX = 1920
$NormalResY = 1080

# ---------------------------------------------------------
# 3. SINGLE INSTANCE CHECK
# ---------------------------------------------------------

$MutexName = "Global\DefinitionSwitcher"
$CreatedNew = $false
try {
    $Global:AppMutex = New-Object System.Threading.Mutex($true, $MutexName, [ref]$CreatedNew)
} catch {
    $CreatedNew = $false
}

if (-not $CreatedNew) {
    Start-Process "steam://open/main"
    exit
}

# ---------------------------------------------------------
# 4. START SESSION
# ---------------------------------------------------------

[ScreenHelper]::Set($HighResX, $HighResY)

$SteamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
if ($null -eq $SteamProcess) {
    Start-Process -FilePath $SteamExePath
    Start-Sleep -Seconds 10
} else {
    Start-Process "steam://open/main"
}

# ---------------------------------------------------------
# 5. ENFORCER LOOP
# ---------------------------------------------------------

while ($true) {
    $SteamProcess = Get-Process -Name "steam" -ErrorAction SilentlyContinue
    
    if ($null -eq $SteamProcess) {
        break 
    }

    if (-not [ScreenHelper]::Is($HighResX, $HighResY)) {
        [ScreenHelper]::Set($HighResX, $HighResY)
    }

    Start-Sleep -Seconds 2
}

# ---------------------------------------------------------
# 6. CLEANUP
# ---------------------------------------------------------

[ScreenHelper]::Set($NormalResX, $NormalResY)
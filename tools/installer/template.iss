#define AppName      "{$AppName}"
#define AppVersion   "{$AppVersion}"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
; AppPublisher={$AppPublisher}

DefaultDirName={autopf}\{#AppName}
ArchitecturesInstallIn64BitMode=x64compatible
UsePreviousAppDir=yes
DisableProgramGroupPage=auto
DefaultGroupName={#AppName}
PrivilegesRequired=admin

DisableWelcomePage=no
WizardImageFile=
WizardSmallImageFile=

OutputDir={$BuildDir}
OutputBaseFilename={#AppName}_{#AppVersion}_Setup
Compression=lzma2/max
SolidCompression=yes

[Files]
Source: "{$BuildDir}*"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppName}.exe"
Name: "{commondesktop}\{#AppName}"; Filename: "{app}\{#AppName}.exe"; Tasks: desktopicon

[Code]
function GetSteamInstallPath(var Path: String): Boolean;
begin
  if RegQueryStringValue(HKLM, 'SOFTWARE\WOW6432Node\Valve\Steam', 'InstallPath', Path) then
  begin
    Result := True;
    Exit;
  end;
  
  if RegQueryStringValue(HKLM, 'SOFTWARE\Valve\Steam', 'InstallPath', Path) then
  begin
    Result := True;
    Exit;
  end;
  
  Result := False;
end;

function GetSteamExeIcon(Param: String): String;
var
  Path: String;
begin
  if GetSteamInstallPath(Path) then
    Result := Path + '\steam.exe'
  else
    Result := ''; 
end;
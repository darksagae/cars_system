; NSB Motors - Complete Windows Installer
; Professional installer for Windows 10/11
; This creates a standard Windows installer (.exe) that can be distributed via USB

#define MyAppName "NSB Motors Sales System"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NSB Motors Uganda"
#define MyAppURL "https://nsbbsolutions@gmail.com"
#define MyAppExeName "sales_system.exe"
#define MyAppId "{{8F1D4E6A-9B3C-4D2E-A1F2-C3B4D5E6F7A8}"

[Setup]
; App identification
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Installation settings
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
LicenseFile=LICENSE.txt
InfoBeforeFile=README.txt
InfoAfterFile=POST_INSTALL.txt
OutputDir=..\dist
OutputBaseFilename=NSB_Motors_Setup_v{#MyAppVersion}
; SetupIconFile=..\assets\app_icon\icon.ico  ; Uncomment if you have an icon file
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763

; UI settings
DisableProgramGroupPage=yes
DisableReadyPage=no
DisableFinishedPage=no
DisableWelcomePage=no
WizardImageFile=
WizardSmallImageFile=

; Uninstaller
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "quicklaunchicon"; Description: "{cm:CreateQuickLaunchIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked; OnlyBelowVersion: 6.1; Check: not IsAdminInstallMode

[Files]
; Main application files from Flutter build
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Poppler utilities for PDF text extraction (Windows)
; CRITICAL: pdftotext.exe and ALL DLLs must be in the SAME directory
; Copy pdftotext.exe to app root
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\pdftotext.exe"; DestDir: "{app}"; Flags: ignoreversion
; Copy ALL required DLLs to app root (same directory as pdftotext.exe)
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\poppler.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\poppler-cpp.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\poppler-glib.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\cairo.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\charset.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\deflate.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\expat.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\fontconfig-1.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\freetype.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\iconv.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\jpeg8.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\lcms2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\Lerc.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libcrypto-3-x64.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libcurl.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libexpat.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\liblzma.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libpng16.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libssh2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libtiff.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\libzstd.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\openjp2.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\pixman-1-0.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\tiff.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\zlib.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\poppler-extracted\poppler-25.12.0\Library\bin\zstd.dll"; DestDir: "{app}"; Flags: ignoreversion

; Documentation files
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.txt"; DestDir: "{app}"; Flags: ignoreversion

; Visual C++ Redistributable (if included)
Source: "..\vc_redist.x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall; Check: VCRedistNeedsInstall

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userappdata}\Microsoft\Internet Explorer\Quick Launch\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: quicklaunchicon

[Run]
; Install VC++ Redistributable if needed
Filename: "{tmp}\vc_redist.x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "Installing Visual C++ Redistributable..."; Check: VCRedistNeedsInstall

; Launch application after installation
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Code]
var
  DownloadPage: TDownloadWizardPage;

function VCRedistNeedsInstall: Boolean;
var
  Version: String;
begin
  Result := not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64', 'Version', Version);
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  // Check Windows version
  if GetWindowsVersion < $06030000 then
  begin
    MsgBox('This application requires Windows 10 version 1903 or later, or Windows 11.', mbError, MB_OK);
    Result := False;
  end;
end;

function InitializeUninstall(): Boolean;
var
  ResultCode: Integer;
begin
  Result := True;
  // Check if application is running
  if CheckForMutexes('NSBMotorsUgMutex') or FileExists(ExpandConstant('{app}\{#MyAppExeName}')) then
  begin
    if MsgBox('Please close NSB Motors Sales System before uninstalling.' + #13#10 + #13#10 +
              'Do you want to close it now?', mbConfirmation, MB_YESNO) = IDYES then
    begin
      // Try to close the application
      Exec('taskkill', '/F /IM ' + '{#MyAppExeName}', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
      Sleep(1000);
    end
    else
    begin
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Create firewall exception for the application (optional)
    // Exec('netsh', 'advfirewall firewall add rule name="NSB Motors Sales System" dir=in action=allow program="' + ExpandConstant('{app}') + '\' + '{#MyAppExeName}' + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    // Remove firewall exception (optional)
    // Exec('netsh', 'advfirewall firewall delete rule name="NSB Motors Sales System"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;


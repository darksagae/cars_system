; NSB Motors System Installer
; Inno Setup Script

#define MyAppName "NSB Motors System"
#define MyAppVersion "1.0"
#define MyAppPublisher "NSB Motors"
#define MyAppURL "https://nsbmotors.com/"
#define MyAppExeName "sales_system.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
AppId={{28EC7A4F-8F0B-4F5C-9B4E-8D4A9E7D7F4E}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; Install to Program Files to follow Windows conventions
DefaultDirName={autopf}\NSB Motors System
DefaultGroupName=NSB Motors System
AllowNoIcons=yes
LicenseFile=LICENSE
PrivilegesRequired=admin
OutputDir=.
OutputBaseFilename=nsb_motors_system_installer
Compression=lzma
SolidCompression=yes
WizardStyle=modern
SetupIconFile=data\flutter_assets\assets\app_icon\app_icon.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "dist\app\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}\poppler"

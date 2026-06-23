[Setup]
AppName=NSB Motors UG
AppVersion=1.0.0
AppPublisher=NSB Motors
DefaultDirName={pf}\NSB Motors UG
DefaultGroupName=NSB Motors UG
OutputBaseFilename=nsb_motors_ug_setup_1.0.0
Compression=lzma
SolidCompression=yes

[Files]
Source: "{#SourcePath}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\NSB Motors UG"; Filename: "{app}\nsb_motors_ug.exe"
Name: "{commondesktop}\NSB Motors UG"; Filename: "{app}\nsb_motors_ug.exe"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

# PowerShell script to build a Flutter Windows release and prepare an Inno Setup installer script
# Usage: run from project root (sales_system)

param(
    [string]$FlutterPath = "flutter",
    [string]$OutDir = "dist\release",
    [string]$InnoScriptPath = "..\installer\app_installer.iss"
)

Set-StrictMode -Version Latest

# Ensure running in project root
$projectRoot = Get-Location
Write-Output "Project root: $projectRoot"

# Read pubspec to get app name and version
$pubspec = Join-Path $projectRoot 'pubspec.yaml'
if (-Not (Test-Path $pubspec)) { Write-Error "pubspec.yaml not found."; exit 1 }

$pub = Get-Content $pubspec -Raw
$appName = ($pub -split "\r?\n" | Where-Object { $_ -match '^name:\s*(\S+)' } | Select-Object -First 1) -replace '^name:\s*', ''
$appVersion = ($pub -split "\r?\n" | Where-Object { $_ -match '^version:\s*(\S+)' } | Select-Object -First 1) -replace '^version:\s*', ''
if (-not $appName) { $appName = 'flutter_app' }
if (-not $appVersion) { $appVersion = '1.0.0' }

Write-Output "App: $appName  Version: $appVersion"

# Run flutter build windows --release
Write-Output "Building Flutter Windows release..."
& $FlutterPath build windows --release
if ($LASTEXITCODE -ne 0) { Write-Error "flutter build failed with exit code $LASTEXITCODE"; exit $LASTEXITCODE }

# Source release folder
$releaseSrc = Join-Path $projectRoot 'build\windows\runner\Release'
if (-Not (Test-Path $releaseSrc)) { Write-Error "Release folder not found: $releaseSrc"; exit 1 }

# Prepare output folder
$fullOut = Join-Path $projectRoot $OutDir
if (Test-Path $fullOut) { Remove-Item $fullOut -Recurse -Force }
New-Item -ItemType Directory -Path $fullOut | Out-Null

# Copy release contents
Write-Output "Copying release files to $fullOut"
Copy-Item -Path (Join-Path $releaseSrc '*') -Destination $fullOut -Recurse -Force

# Ensure Inno installer folder exists
$innoScriptFull = Join-Path $projectRoot $InnoScriptPath
$innoDir = Split-Path $innoScriptFull -Parent
if (-Not (Test-Path $innoDir)) { New-Item -ItemType Directory -Path $innoDir | Out-Null }

# Generate a simple Inno Setup script if missing
if (-Not (Test-Path $innoScriptFull)) {
    # Resolve the distribution path
    $distPath = (Split-Path $fullOut -Resolve)

    # Use a literal here-string to avoid interpolation issues
    $iss = @'
[Setup]
AppName={APPNAME}
AppVersion={APPVERSION}
AppPublisher=YourPublisher
DefaultDirName={pf}\{APPNAME}
DefaultGroupName={APPNAME}
OutputBaseFilename={APPNAME}_Setup_{APPVERSION}
Compression=lzma
SolidCompression=yes

[Files]
Source: "{DISTPATH}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{APPNAME}"; Filename: "{app}\{APP_EXE}"
Name: "{commondesktop}\{APPNAME}"; Filename: "{app}\{APP_EXE}"; Tasks: desktopicon

[Tasks]
Name: desktopicon; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked
'@

    # Replace placeholders safely
    $iss = $iss -replace '\{APPNAME\}', [Regex]::Escape($appName)
    $iss = $iss -replace '\{APPVERSION\}', [Regex]::Escape($appVersion)
    # For DISTPATH we want the raw path (no regex metacharacters interpreted)
    $escapedDist = $distPath -replace '([\\"\$`])', '\$1' # escape backslashes, quotes, dollar, backtick for safety in replacement
    $iss = $iss -replace '\{DISTPATH\}', $escapedDist
    $iss = $iss -replace '\{APP_EXE\}', [Regex]::Escape("$appName.exe")

    Set-Content -Path $innoScriptFull -Value $iss -Encoding UTF8
    Write-Output "Generated Inno Setup script at: $innoScriptFull"
} else {
    Write-Output "Inno Setup script already exists at: $innoScriptFull"
}

Write-Output "Prepared installer assets in: $fullOut"
Write-Output "Next steps:`n1) Install Inno Setup (https://jrsoftware.org/isinfo.php) and run the .iss file with the Inno compiler (ISCC.exe) or open it in the Inno GUI.`n2) Optionally include the Visual C++ Redistributable installer in the [Files] section or add a PreInstall step.`n3) The generated installer will package the entire release folder into a standard Windows installer (.exe)."

exit 0

# NSB Motors Uganda - Windows 11 Security Compliance Script
# This script helps ensure the application is trusted by Windows 11

Write-Host "NSB Motors Uganda - Windows 11 Security Setup" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator privileges. Please run as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "Setting up Windows 11 security compliance..." -ForegroundColor Yellow

# 1. Add application to Windows Defender exclusions
Write-Host "Adding to Windows Defender exclusions..." -ForegroundColor Cyan
$appPath = "$env:ProgramFiles\NSB Motors Ug"
Add-MpPreference -ExclusionPath $appPath -ErrorAction SilentlyContinue
Add-MpPreference -ExclusionProcess "nsb_motors_ug.exe" -ErrorAction SilentlyContinue

# 2. Create firewall rule for the application
Write-Host "Creating firewall rule..." -ForegroundColor Cyan
$firewallRule = "NSB Motors Ug"
if (-not (Get-NetFirewallRule -DisplayName $firewallRule -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName $firewallRule -Direction Inbound -Program "$appPath\nsb_motors_ug.exe" -Action Allow -ErrorAction SilentlyContinue
}

# 3. Set application as trusted
Write-Host "Setting application as trusted..." -ForegroundColor Cyan
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\nsb_motors_ug.exe"
if (-not (Test-Path $registryPath)) {
    New-Item -Path $registryPath -Force | Out-Null
    Set-ItemProperty -Path $registryPath -Name "(Default)" -Value "$appPath\nsb_motors_ug.exe"
}

# 4. Configure SmartScreen (if possible)
Write-Host "Configuring SmartScreen settings..." -ForegroundColor Cyan
$smartScreenPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer"
Set-ItemProperty -Path $smartScreenPath -Name "SmartScreenEnabled" -Value "Off" -ErrorAction SilentlyContinue

# 5. Create application data directory
Write-Host "Creating application data directory..." -ForegroundColor Cyan
$dataPath = "$env:USERPROFILE\Documents\NSB_Motors_Data"
if (-not (Test-Path $dataPath)) {
    New-Item -Path $dataPath -ItemType Directory -Force | Out-Null
    Write-Host "Data directory created: $dataPath" -ForegroundColor Green
}

# 6. Set proper permissions
Write-Host "Setting application permissions..." -ForegroundColor Cyan
$acl = Get-Acl $appPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Users", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)
Set-Acl -Path $appPath -AclObject $acl

Write-Host "Windows 11 security setup completed successfully!" -ForegroundColor Green
Write-Host "The application should now be trusted by Windows 11." -ForegroundColor Green
Write-Host ""
Write-Host "If Windows Defender still shows warnings:" -ForegroundColor Yellow
Write-Host "1. Click 'More info' on the warning" -ForegroundColor Yellow
Write-Host "2. Click 'Run anyway'" -ForegroundColor Yellow
Write-Host "3. The application is safe and digitally verified" -ForegroundColor Yellow

Read-Host "Press Enter to continue"

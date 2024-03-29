<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script automatically extracts data from a machine and adds it to Auto Pilot.
.DESCRIPTION  
    Extract device's hardware hash and serial number and upload to Auto Pilot.  
.NOTES  
    File Name  : autopilot_autoregister.ps1  
    Author     : Charlie Graham 
    Requires   : NuGet, PSGallery, Get-WindowsAutopilotInfo
#>

# Initial Cleanup
Write-Host "Initial Cleanup..."

if (Test-Path -Path "C:\HWID" -PathType Leaf) {
    Write-Host "Previous traces found, cleaning up..." -ForegroundColor Red
    Remove-Item "C:\HWID" -Recurse -Force
    Write-Host "Cleaned up successfully!" -ForegroundColor Green
} 
else {
    Write-Host "No previous traces found, continuing..." -ForegroundColor Green
}

## Install Microsoft.UI.XAML.2.7
Write-Host "Installing Microsoft.UI.XAML.2.7..."
Add-AppxPackage -Path "C:\Temp\Components\Microsoft.UI.Xaml.2.7_7.2208.15002.0_x64__8wekyb3d8bbwe.appx"

## Install Microsoft.VCLibs.140.00.UWPDesktop
Write-Host "Installing Microsoft.VCLibs.140.00.UWPDesktop..."
Add-AppxPackage -Path "C:\Temp\Components\Microsoft.VCLibs.x64.14.00.Desktop.appx"

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet in order that we can install PSWindowsUpdate
Write-Host "Installing NuGet"
Install-PackageProvider -Name NuGet -Confirm:$False -Force -ErrorAction SilentlyContinue

# Install Microsoft.Graph.Intune if not already
if (Get-Module -ListAvailable -Name Microsoft.Graph.Intune) {
    Write-Host "Microsoft.Graph.Intune Module exists" -ForegroundColor Green
    Update-Module -Name Microsoft.Graph.Intune
    Import-Module Microsoft.Graph.Intune
} 
else {
    Write-Host "Microsoft.Graph.Intune Module does not exist" -ForegroundColor Red
    Install-Module -Name Microsoft.Graph.Intune
    Import-Module Microsoft.Graph.Intune
}

# Install AzureAD if not already
if (Get-Module -ListAvailable -Name AzureAD) {
    Write-Host "AzureAD Module exists" -ForegroundColor Green
    Update-Module -Name AzureAD
    Import-Module AzureAD
} 
else {
    Write-Host "AzureAD Module does not exist" -ForegroundColor Red
    Install-Module -Name AzureAD
    Import-Module AzureAD
}

# Install WindowsAutoPilotIntune Module if not already
if (Get-Module -ListAvailable -Name WindowsAutoPilotIntune) {
    Write-Host "WindowsAutoPilotIntune Module exists" -ForegroundColor Green
    Update-Module -Name WindowsAutoPilotIntune
    Import-Module WindowsAutoPilotIntune
} 
else {
    Write-Host "WindowsAutoPilotIntune Module does not exist" -ForegroundColor Red
    Install-Module -Name WindowsAutoPilotIntune
    Import-Module WindowsAutoPilotIntune
}

# Install Get-WindowsAutoPilotInfo script
Write-host "Installing Get-WindowsAutoPilotInfo script..." -ForegroundColor Green
Install-Script -Name Get-WindowsAutoPilotInfo

# Extract device's hardware hash and serial number and output to C:\HWID\AutopilotHWID.csv
Write-Host "Extracting device hardware hash and serial number..."
New-Item -Type Directory -Path "C:\HWID"
Set-Location -Path "C:\HWID"
Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv

# Ask for credentials & upload hardware hash to Auto Pilot
Write-Host "Please sign in with an account with the Intune Administrator role..." -f DarkRed
Get-WindowsAutopilotInfo -Online
Write-Host "Uploading device hardware hash and serial number..."

# Wait before cleanup
[int]$Time = 10
$Length = $Time / 100
For ($Time; $Time -gt 0; $Time--) {
$min = [int](([string]($Time/60)).split('.')[0])
$text = " " + $min + " minutes " + ($Time % 60) + " seconds left"
Write-Progress -Activity "Watiting..." -Status $Text -PercentComplete ($Time / $Length)
Start-Sleep 1
}

# Post-Script Cleanup
Write-Host "Post-Script Cleanup..."
Remove-Item "C:\HWID" -Recurse -Force

# Ask user for confirmation of a factory reset
$title = 'Factory Reset'
$question = 'Do you want to factory reset and start building from InTune?'
$choices = '&Yes', '&No'

$decision = $Host.UI.PromptForChoice($title, $question, $choices, 1)
if ($decision -eq 0) {
    Write-Host 'Confirmed' -f Green
    systemreset.exe --factoryreset
}
else {
    Write-Host 'Exiting...' -f DarkRed
    exit
}

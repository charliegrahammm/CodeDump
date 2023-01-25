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

# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host "Launching in Admin mode" -f DarkRed
    $pwshexe = (Get-Command 'powershell.exe').Source
    Start-Process $pwshexe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# Initial Cleanup
Write-Host "Initial Cleanup..."
Remove-Item "C:\HWID" -Recurse -Force

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
[int]$Time = 5
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
    Write-Host 'Cancelled' -f DarkRed
    exit
}

<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script asks for a machines name and serial number and removes it from Auto Pilot.
.DESCRIPTION  
    Manually enter a device's hardware name and serial number and remove from Auto Pilot.  
.NOTES  
    File Name  : autopilot_remove.ps1  
    Author     : Charlie Graham 
    Requires   : NuGet, PSGallery
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

# Ask for Serial Number
$SerialNumber = Read-Host -Prompt 'Enter devices Serial Number'

# Ask for Computer Name
$ComputerName = Read-Host -Prompt 'Enter devices Computer Name'

# Ask for credentials
Write-Host "Please sign in with an Office 365 Administrator account..." -f DarkRed

# Remove device from AutoPilot
Connect-MSGraph
Get-AutoPilotDevice | Where-Object SerialNumber -eq $SerialNumber | Remove-AutopilotDevice
Write-Host "Removing device from AutoPilot..."

# Ask for credentials
Write-Host "Please sign in again with an Office 365 Administrator account..." -f DarkRed

# Remove device from AzureAD
Connect-Azuread
Get-AzureADDevice | Where-Object DisplayName -Match $ComputerName | Remove-AzureADDevice
Write-Host "Removing device from AzureAD..."

PAUSE
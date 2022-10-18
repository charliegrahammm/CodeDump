<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script automatically extracts data from a machine and removes it from Auto Pilot.
.DESCRIPTION  
    Extract device's hardware hash and serial number and remove from Auto Pilot.  
.NOTES  
    File Name  : autopilot_autoremove.ps1  
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

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet if not already
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

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

# Ask for credentials
Write-Host "Please sign in with an Office 365 Administrator account..." -f DarkRed

# Remove device from AutoPilot
Write-Host "Removing device from AutoPilot..."
Connect-MSGraph
Get-AutoPilotDevice | Where-Object SerialNumber -eq (Get-WmiObject -class Win32_Bios).SerialNumber | Remove-AutopilotDevice

# Ask for credentials
Write-Host "Please sign in again with an Office 365 Administrator account..." -f DarkRed

# Remove device from AzureAD
Write-Host "Removing device from AzureAD..."
Connect-Azuread
Get-AzureADDevice | Where-Object DisplayName -Match $env:COMPUTERNAME | Remove-AzureADDevice

# Ask user for confirmation of a factory reset
$title = 'Factory Reset'
$question = 'Do you want to factory reset?'
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

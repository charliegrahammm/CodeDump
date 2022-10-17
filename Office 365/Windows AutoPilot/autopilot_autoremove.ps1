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

# Install dependencies
Write-Host "Allowing PSGallery..."
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
# Install NuGet
Write-Host "Installing NuGet..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Confirm:$false
# Install Get-AzureADDevice if necessary
Write-Host "Installing Get-AzureADDevice if necessary..."
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Install-Script -Name Get-AzureADDevice
# Install Connect-MSGraph if necessary
Write-Host "Installing Connect-MSGraph if necessary..."
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Install-Script -Name Connect-MSGraph
# Install Connect-AzureAD if necessary
Write-Host "Installing Connect-AzureAD if necessary..."
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Install-Script -Name Connect-AzureAD

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

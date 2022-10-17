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

# Install dependencies
Write-Host "Allowing PSGallery..."
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
# Install NuGet
Write-Host "Installing NuGet..."
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ForceBootstrap -Confirm:$false
# Install Get-WindowsAutopilotInfo  
Write-Host "Installing Get-WindowsAutopilotInfo..."
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Install-Script -Name Get-WindowsAutopilotInfo

# Extract device's hardware hash and serial number and output to C:\HWID\AutopilotHWID.csv
# Write-Host "Extracting device hardware hash and serial number..."
# New-Item -Type Directory -Path "C:\HWID"
# Set-Location -Path "C:\HWID"
# Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv

# Ask for credentials
Write-Host "Uploading device hardware hash and serial number..."
Write-Host "Please sign in with an account with the Intune Administrator role..." -f DarkRed

# Upload hardware hash to Auto Pilot 
Get-WindowsAutopilotInfo -Online

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

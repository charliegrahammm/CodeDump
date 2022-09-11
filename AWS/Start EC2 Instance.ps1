# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue." -ForegroundColor White -BackgroundColor Red 
    Start-Sleep 1
    Write-Host "Launching in Admin mode" -ForegroundColor White -BackgroundColor Green
    $pwshexe = (Get-Command 'powershell.exe').Source
    Start-Process $pwshexe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# Install Module if not detected
if (Get-Module -ListAvailable -Name SomeModule) {
    Write-Host "Module exists" -ForegroundColor White -BackgroundColor Green
} 
else {
    Write-Host "Module does not exist, installing..." -ForegroundColor White -BackgroundColor Red 
    Install-Module -Name AWS.Tools.EC2
}

# List instances Available
Write-Host "Listing available Instances"
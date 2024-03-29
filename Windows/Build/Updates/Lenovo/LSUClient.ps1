<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script will automatically pull Lenovo System Updates from https://download.lenovo.com and install them silently. 
.DESCRIPTION  
    The standard version of this script is designed to be ran manually.
.NOTES  
    File Name  : LSUClient.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell V2, LSUClient, NuGet
#>

# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue." -ForegroundColor White -BackgroundColor Red 
    Start-Sleep 1
    Write-Host "Launching in Admin mode" -ForegroundColor White -BackgroundColor Green
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

# Install LSUClient if not already
if (Get-Module -ListAvailable -Name LSUClient) {
    Write-Host "LSUClient Module exists" -ForegroundColor Green
    Update-Module -Name LSUClient
    Import-Module LSUClient
} 
else {
    Write-Host "LSUClient does not exist" -ForegroundColor Red
    Install-Module -Name LSUClient
    Import-Module LSUClient
}

# Show system info
gcim Win32_ComputerSystem | Format-List Manufacturer, Model, SystemFamily 

# Gather updates in a loop
Write-Host "Gathering system updates..." -ForegroundColor Green
$MaxRounds = 3
for ($Round = 1; $Round -le $MaxRounds; $Round++) {
    Write-Host "Starting round $Round"
    $updates = Get-LSUpdate -Verbose
    Write-Host "$($updates.Count) updates found"
    Write-Host $updates

    if ($updates.Count -eq 0) {
        break;
    }

    # Download them all to the local disk
    $updates | Save-LSUpdate

    # Then install
    $updates | Install-LSUpdate
}

# Cleanup Files
Write-Output "Cleaning up..."
if (Test-Path -Path $env:TEMP\LSUPackages) {
Remove-Item -Path $env:TEMP\LSUPackages -Recurse
}
else {
    Write-Host "Nothing to clean up"
}

# Prompt for reboot
Restart-Computer -Confirm:$true

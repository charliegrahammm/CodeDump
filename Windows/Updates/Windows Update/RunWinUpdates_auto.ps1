<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script automatically runs Windows Updates. The auto version of this script must be ran as an administrator.
.DESCRIPTION  
    This script will automatically install any necessary modules, pull down a list of required updates from Microsoft's servers and install them. It may need to be ran multiple times.
.NOTES  
    File Name  : RunWinUpdates_auto.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2, PSWindowsUpdate
#>

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet if not already
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

# Install PSWindowsUpdate if not already
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Write-Host "PSWindowsUpdate Module exists" -ForegroundColor Green
    Update-Module -Name PSWindowsUpdate
    Import-Module PSWindowsUpdate
} 
else {
    Write-Host "PSWindowsUpdate does not exist" -ForegroundColor Red
    Install-Module -Name PSWindowsUpdate
    Import-Module PSWindowsUpdate
}

# Clear previous job
Write-Host "Clearing previous job..."
Clear-WUJob

# Check for Windows Updates
Write-Host "Checking for updates..."
$updates = Get-WindowsUpdate
Write-Host $updates.count updates available
if ($updates.Count -eq 0) {
    Write-Host "No Updates Available"
    break
}

# Run Windows Updates and reboot automatically
Write-Host "Installing updates..." 
Install-WindowsUpdate -AcceptAll -IgnoreReboot 

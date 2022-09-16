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
    The auto version of this script is designed to run in the background using PDQ or a scheduled task. The task must be ran as an administrator.
.NOTES  
    File Name  : LSUClient_auto.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell V2, LSUClient, NuGet
#>

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet if not already
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

# Install LSUClient if not already
if (Get-Module -ListAvailable -Name LSUClient) {
    Write-Output "LSUClient Module exists" 
    Import-Module LSUClient
} 
else {
    Write-Output "LSUClient does not exist"
    Install-Module -Name LSUClient
    Import-Module LSUClient
}

# Gather updates in a loop
Write-Output "Gathering updates..."
$MaxRounds = 3
for ($Round = 1; $Round -le $MaxRounds; $Round++) {
    Write-Output "Starting round $Round"
    $updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended } -Verbose
    Write-Output "$($updates.Count) updates found"
    Write-Output $updates

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
Remove-Item -Path $env:TEMP\LSUPackages -Recurse

# Gather updates after installation
Write-Output "Gathering updates..."
$updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended } -Verbose
Write-Output "$($updates.Count) updates found"
Write-Output $updates
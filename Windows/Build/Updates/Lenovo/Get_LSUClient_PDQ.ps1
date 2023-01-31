<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script will automatically pull Lenovo System Updates from https://download.lenovo.com. To be used as a PDQ PowerShell Scanner.
.DESCRIPTION  
    The PDQ version of this script is designed to run as a PDQ PowerShell scanner. The task must be ran as an administrator.
.NOTES  
    File Name  : Get_LSUClient_PDQ.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell V2, LSUClient, NuGet
#>

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet in order that we can install PSWindowsUpdate
Write-Host "Installing NuGet"
Install-PackageProvider -Name NuGet -Confirm:$False -Force -ErrorAction SilentlyContinue

# Install LSUClient if not already
if (Get-Module -ListAvailable -Name LSUClient) {
    Update-Module -Name LSUClient -Force
    Import-Module LSUClient
} 
else {
    Install-Module -Name LSUClient -Force
    Import-Module LSUClient
}

# Gather updates in a loop
$updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended } -Verbose

[PSCustomObject]@{
    UpdatesOutstanding     = $updates.count
}
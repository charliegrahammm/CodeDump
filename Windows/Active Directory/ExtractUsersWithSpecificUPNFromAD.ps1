<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script extracts a list of users from AD with a specific UPN suffix.
.DESCRIPTION  
    Pulls users from a specific AD OU with a specified UPN suffix and exports to C:\Temp\users.csv. Must be ran using domain administrator credentials.
.NOTES  
    File Name  : ExtractUsersWithSpecificUPNFromAD.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
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
Write-Host "Allowing PSGallery" -ForegroundColor Green
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet if not already
Write-Host "Install NuGet" -ForegroundColor Green
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

# Install ActiveDirectory if not already
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Host "ActiveDirectory exists" -ForegroundColor Green
    Import-Module ActiveDirectory
} 
else {
    Write-Host "ActiveDirectory does not exist" -ForegroundColor Red
    Install-Module -Name ActiveDirectory
    Import-Module ActiveDirectory
}

# Extract User Information
$UPNSuffix = Read-Host -Prompt 'Input UPN Suffix - e.g @pharmaxo.com'
$OrgUnit = "OU=Users,OU=Corsham,DC=pharmaxo,DC=local"
$ExtractedUsers = Get-ADUser -Filter "userPrincipalName -like '*$UPNSuffix' -and enabled -eq 'TRUE'" -Properties samaccountname,userprincipalname,enabled,proxyaddresses,company -SearchBase $OrgUnit | Select-Object samaccountname,userprincipalname,enabled,company, @{L = "ProxyAddresses"; E = { ($_.ProxyAddresses -like 'smtp:*') -join ";"}} 

# Start transcript
Start-Transcript -Path C:\Temp\Extract-ADUsers.log -Append

# Export to CSV
Write-Host "Exporting CSV"
$ExtractedUsers | Export-CSV -Path "C:\temp\users.csv" -Force

# Stop transcript
Stop-Transcript

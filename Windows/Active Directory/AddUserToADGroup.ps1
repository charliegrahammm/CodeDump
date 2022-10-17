<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script adds users in a csv to an AD Group.
.DESCRIPTION  
    Pulls users from a csv file and adds them to a specified AD Group. Must be ran using domain administrator credentials.
.NOTES  
    File Name  : AddUserToADGroup.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."
    Start-Sleep 1
    Write-Host " Launching in Admin mode" -f DarkRed
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
    Update-Module -Name ActiveDirectory
    Import-Module ActiveDirectory
} 
else {
    Write-Host "ActiveDirectory does not exist" -ForegroundColor Red
    Install-Module -Name ActiveDirectory
    Import-Module ActiveDirectory
}

# Gather information
$Users = Read-Host -Prompt 'Input file path of csv file - e.g C:\Temp\users.csv (no "")'
$Group = Read-Host -Prompt 'Input AD group name'

# Start transcript
Start-Transcript -Path C:\Temp\Add-ADUsers.log -Append

# Import the data from CSV file and assign it to variable
$ADUser = Import-Csv $Users

# Add users to group
foreach ($User in $Users) {

# Retrieve AD user group membership
$ExistingGroups = Get-ADPrincipalGroupMembership $ADUser.SamAccountName | Select-Object Name

# User already member of group
    if ($ExistingGroups.Name -eq $Group) {
        Write-Host "$UPN already exists in $Group" -ForeGroundColor Yellow
    }
    else {
        # Add user to group
        Add-ADGroupMember -Identity $Group -Members $ADUser.SamAccountName
        Write-Host "Added $UPN to $Group" -ForeGroundColor Green
    }
}
Stop-Transcript
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

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet if not already
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

# Install ActiveDirectoryModule if not already
if (Get-Module -ListAvailable -Name ActiveDirectoryModule) {
    Write-Host "ActiveDirectoryModule exists" -ForegroundColor Green
    Update-Module -Name ActiveDirectoryModule
    Import-Module ActiveDirectoryModule
} 
else {
    Write-Host "ActiveDirectoryModule does not exist" -ForegroundColor Red
    Install-Module -Name ActiveDirectoryModule
    Import-Module ActiveDirectoryModule
}

# Gather information
$Users = Read-Host -Prompt 'Input file path of csv file'
$Group = Read-Host -Prompt 'Input AD group name'

# Start transcript
Start-Transcript -Path C:\Temp\Add-ADUsers.log -Append

# Import the data from CSV file and assign it to variable
$Users = Import-Csv $Users

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
        Add-ADGroupMember -Identity $Group -Members $ADUser.SamAccountName -WhatIf
        Write-Host "Added $UPN to $Group" -ForeGroundColor Green
    }
}
Stop-Transcript
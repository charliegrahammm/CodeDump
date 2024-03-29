<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script extracts a list of users from a specified AD group.
.DESCRIPTION  
    Pulls users from a specified AD group and exports as a CSV to C:\Temp\GroupMembership. Must be ran using domain administrator credentials.
.NOTES  
    File Name  : ExtractADGroupMembership.ps1  
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
Write-Host "Installing NuGet" -ForegroundColor Green
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201

# Install ActiveDirectory if not already
if (Get-Module -ListAvailable -Name ActiveDirectory) {
    Write-Host "ActiveDirectory exists, importing..." -ForegroundColor Green
    Update-Module -Name ActiveDirectory
    Import-Module ActiveDirectory
} 
else {
    Write-Host "ActiveDirectory does not exist, installing..." -ForegroundColor Red
    Install-Module -Name ActiveDirectory
    Import-Module ActiveDirectory
}

# Create C:\Temp\GroupMembership Folder if it doesnt exist
if (Test-Path -Path C:\temp\GroupMembership -PathType Container) {
    Write-Host "Path already exists..." -ForegroundColor Green
} 
else {
    Write-Host "Creating Path..." -ForegroundColor Green
    New-Item -Path "C:\Temp\GroupMembership" -ItemType Directory
}

# Loop until user declines to run again
do {
    # Request user input for AD Group Name
    $GroupName = Read-Host -Prompt 'Input AD group name'

    # Load the Active Directory Module
    Import-Module -Name ActiveDirectory

    # Extract list of users
    Get-ADGroupMember -identity $GroupName | Select-Object name | Export-csv -path c:\temp\GroupMembership\$GroupName.csv -Notypeinformation -Force
    
    # Check if file was successfully created
    if (Test-Path -Path C:\temp\GroupMembership\$GroupName.csv -PathType Leaf) {
        Write-Host "Extract file created successfully" -ForegroundColor Green
    }
    else {
        Write-Host "There was a problem extracting users from the specified AD group" -ForegroundColor Red
    }

    # Ask user if they want to run again
} until($Host.UI.PromptForChoice('', 'Do you want to extract another group', ('&Yes', '&No'), 0))

pause
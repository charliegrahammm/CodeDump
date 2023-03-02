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
    Write-Host "Launching in Admin mode" -f DarkRed
    $pwshexe = (Get-Command 'powershell.exe').Source
    Start-Process $pwshexe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Start transcript
Start-Transcript -Path C:\Temp\AddUserToADGroup.log -Append

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

# Set Delimiter
$Delimiter = ","

# Request user input for provided data format
Function Get-ProjectType {
$type=Read-Host "
CSV Data Format:
1 - DisplayName
2 - Email
3 - UserPrincipalName
Please choose the format of the data you are providing"
    Switch ($type){
        1 {$choice="DisplayName"}
        2 {$choice="Email"}
        3 {$choice="UserPrincipalName"}
    }
    return $choice
}
$Filter = Get-ProjectType

# Request user input for location of CSV
$Path = Read-Host -Prompt 'Input file path of csv file - e.g C:\Temp\users.csv (no "")'

# Request user input for AD Group Name
$GroupName = Read-Host -Prompt 'Input AD group name'

Function Add-UsersToGroup {
    <#
    .SYNOPSIS
      Get users from the requested DN
    #>
    process{
        # Import the CSV File
        $users = (Import-Csv -Path $path -Delimiter $delimiter -header "name").name

        # Find the users in the Active Directory
        $users | ForEach {
            $user =  Get-ADUser -filter "$filter -eq '$_'" | Select ObjectGUID 

            if ($user) {
                Add-ADGroupMember -Identity $groupName -Members $user
                Write-Host "$_ added to the group"
            }else {
                Write-Warning "$_ not found in the Active Directory"
            }
        }
    }
}

# Load the Active Directory Module
Import-Module -Name ActiveDirectory

# Add user from CSV to given Group
Add-UsersToGroup

# Stop Transcript
Stop-Transcript

pause
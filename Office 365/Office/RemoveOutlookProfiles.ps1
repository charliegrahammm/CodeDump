<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script removes all Outlook 2013, 2016 and 365 profiles from a machine for the logged in user.
.DESCRIPTION  
    Removes all outlook profiles for the logged in user. Must be ran as the logged in user. It is recommended to reboot before and after this script has ran.
.NOTES  
    File Name  : RemoveOutlookProfiles.ps1
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Specify parameters
$User = $env:USERNAME
$Path = "C:\Users\" + $User + "\AppData\Local\Microsoft\Outlook"
$Key16 = "HKCU:\SOFTWARE\Microsoft\Office\16.0\Outlook\Profiles"
$Key15 = "HKCU:\SOFTWARE\Microsoft\Office\15.0\Outlook\Profiles"

# Kill Office Applications
Stop-Process -Name OUTLOOK -Force -EA SilentlyContinue
Write-Output "Outlook is closing..." 
Stop-Process -Name EXCEL -Force -EA SilentlyContinue
Write-Output "Excel is closing..." 
Stop-Process -Name WINWORD -Force -EA SilentlyContinue
Write-Output "Word is closing..." 
Stop-Process -Name POWERPNT -Force -EA SilentlyContinue
Write-Output "Powerpoint is closing..." 
Stop-Process -Name VISIO -Force -EA SilentlyContinue
Write-Output "Visio is closing..." 
Stop-Process -Name ONENOTE -Force -EA SilentlyContinue
Write-Output "OneNote is closing..." 
Stop-Process -Name MSPUB -Force -EA SilentlyContinue
Write-Output "Publisher is closing..." 
Stop-Process -Name MSACCESS -Force -EA SilentlyContinue
Write-Output "Access is closing..." 

# Locate data files
$TestPath = Test-Path -Path $Path\*.ost
$GciPath = Get-ChildItem -Path $Path -Recurse -Include *.ost, *.nst

# Remove data files
if ($TestPath -eq $TRUE) {
    Remove-Item $GciPath -EA SilentlyContinue
}
else {
    Write-Output ".OST not found, continuing..." -BackgroundColor Green -ForegroundColor Black
}

# Test key path
$TestPath16 = Test-Path -Path $Key16 -IsValid
$TestPath15 = Test-Path -Path $Key15 -IsValid

# Delete key
if ($TestPath16 -eq $TRUE) {
    Remove-Item $Key16 -Recurse -EA SilentlyContinue
    Write-Output "Outlook 2016 profiles are removed."
}
elseif ($TestPath15 -eq $TRUE) {
    Remove-Item $Key15 -Recurse -EA SilentlyContinue
    Write-Output "Outlook 2013 profiles are removed."
}
else {
    Write-Output "Outlook 2016 and Outlook 2013 not found."
}

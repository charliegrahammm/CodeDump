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
Write-Host "Outlook is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name EXCEL -Force -EA SilentlyContinue
Write-Host "Excel is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name WINWORD -Force -EA SilentlyContinue
Write-Host "Word is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name POWERPNT -Force -EA SilentlyContinue
Write-Host "Powerpoint is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name VISIO -Force -EA SilentlyContinue
Write-Host "Visio is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name ONENOTE -Force -EA SilentlyContinue
Write-Host "OneNote is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name MSPUB -Force -EA SilentlyContinue
Write-Host "Publisher is closing..." -BackgroundColor Green -ForegroundColor Black
Stop-Process -Name MSACCESS -Force -EA SilentlyContinue
Write-Host "Access is closing..." -BackgroundColor Green -ForegroundColor Black

# Locate data files
$TestPath = Test-Path -Path $Path\*.ost
$GciPath =  Get-ChildItem -Path $Path -Recurse -Include *.ost,*.nst

# Remove data files
if ($TestPath -eq $TRUE){
Remove-Item $GciPath -EA SilentlyContinue
}
else{
Write-Host ".OST not found, continuing..." -BackgroundColor Green -ForegroundColor Black
}

# Test key path
$TestPath16 = Test-Path -Path $Key16 -IsValid
$TestPath15 = Test-Path -Path $Key15 -IsValid

# Delete key
if ($TestPath16 -eq $TRUE){
Remove-Item $Key16 -Recurse -EA SilentlyContinue
Write-Host "Outlook 2016 profiles are removed." -BackgroundColor Green -ForegroundColor Black
}
elseif ($TestPath15 -eq $TRUE){
Remove-Item $Key15 -Recurse -EA SilentlyContinue
Write-Host "Outlook 2013 profiles are removed." -BackgroundColor Green -ForegroundColor Black
}
else{
Write-Host "Outlook 2016 and Outlook 2013 not found." -BackgroundColor Red -ForegroundColor Black
}

<# 
.SYNOPSIS  
    This script automatically extracts the HWID of a machine to be imported into InTune.
.DESCRIPTION  
    Extract device's hardware hash and serial number then copies the file to a shared location for upload into InTune.  
.NOTES  
    File Name  : ExtractHWID.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Extract Hardware Information
New-Item -Type Directory -Path "C:\HWID"
Set-Location -Path "C:\HWID"
$env:Path += ";C:\Program Files\WindowsPowerShell\Scripts"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Install-Script -Name Get-WindowsAutopilotInfo
Get-WindowsAutopilotInfo -OutputFile AutopilotHWID.csv

# Rename file 
Rename-Item -Path "C:\HWID\AutopilotHWID.csv" -NewName "C:\HWID\AutopilotHWID-$($env:COMPUTERNAME).csv"

# Copy file to shared location
Move-Item -Path C:\HWID\*.csv -Destination "\\svr-fs-1\SDrive\IT\HWID"

# Wait 2 seconds
Start-Sleep 2
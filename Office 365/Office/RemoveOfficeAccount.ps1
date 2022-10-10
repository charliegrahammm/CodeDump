<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script removes all Office accounts from a machine including Microsoft Teams for the logged in user.
.DESCRIPTION  
    Removes all Office accounts from a machine by deleting the entry from a users %localappdata%\Packages. Must be ran as the logged in user. It is recommended to reboot before and after this script has ran.
.NOTES  
    File Name  : RemoveOfficeAccount.ps1
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Remove Reg Key
$Regkeypath = "HKCU:\Software\Microsoft\Office\Teams" 
$value = $null -eq (Get-ItemProperty $Regkeypath).HomeUserUpn
If ($value -eq $False) { 
    Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Office\Teams" -Name "HomeUserUpn"
    Write-Output "The registry value Sucessfully removed" 
} 
Else { Write-Output "The registry value does not exist" }

# Get Desktop-config.json
$TeamsFolders = "$env:APPDATA\Microsoft\teams"
try {
    $SourceDesktopConfigFile = "$TeamsFolders\desktop-config.json"
    $desktopConfig = (Get-Content -Path $SourceDesktopConfigFile | ConvertFrom-Json)
}
catch { Write-Output "Failed to open Desktop-config.json" }

# Overwrite the desktop-config.json
Write-Output "Modify desktop-Config.Json"
try {
    $desktopConfig.isLoggedOut = $true
    $desktopConfig.upnWindowUserUpn = ""; #The email used to sign in
    $desktopConfig.userUpn = "";
    $desktopConfig.userOid = "";
    $desktopConfig.userTid = "";
    $desktopConfig.homeTenantId = "";
    $desktopConfig.webAccountId = "";
    $desktopConfig | ConvertTo-Json -Compress | Set-Content -Path $SourceDesktopConfigFile -Force
}
catch { Write-Output "Failed to overwrite desktop-config.json" }
Write-Output "Modify desktop-Config.Json - Finished"

# Delete the Cookies file. This is a fix for when the joining as anonymous, and prevents the last used guest name from being reused.
try {
    Get-ChildItem "$TeamsFolders\Cookies" | Remove-Item
}
catch { Write-Output "Failed to delete the cookies file" }
Write-Output "Delete cookies file - Finished"

# Lastly delete the storage.json, this corrects some error that MSTeams otherwise would have when logging in again.
try {
    Get-ChildItem "$TeamsFolders\storage.json" | Remove-Item
}
catch { Write-Output "Failed to delete storage.json" }
Write-Output "Delete storage.json - Finished"

# Try to remove the Link School/Work account if there was one. It can be created if the first time you sign in, the user all
$LocalPackagesFolder = "$env:LOCALAPPDATA\Packages"
$AADBrokerFolder = Get-ChildItem -Path $LocalPackagesFolder -Recurse -Include "Microsoft.AAD.BrokerPlugin_*";
$AADBrokerFolder = $AADBrokerFolder[0];
Get-ChildItem "$AADBrokerFolder\AC\TokenBroker\Accounts" | Remove-Item -Recurse -Force

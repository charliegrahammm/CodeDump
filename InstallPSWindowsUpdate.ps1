# +----------------------------------+---------------------------------------------+
# |   ___    ____    _   _   _       | Title:   InstallPSWindowsUpdate.ps1         |
# |  / _ \  |  _ \  | | | | | |      | Author:  Matt Whalley                       |
# | | | | | | |_) | | |_| | | |      | Date:    09/05/2019                         |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                |
# |  \__\_\ |_|     |_| |_| |_____|  |                                             |
# +----------------------------------+---------------------------------------------+
# | DESCRIPTION:                                                                   |
# | Installs the PSWindowsUpdateModule.                                            |
# | Needs to be run prior to FireAndForgetWindowsUpdates.ps1 so that the required  |
# | modules are installed.                                                         |
# |                                                                                |
# | Uses this:                                                                     |
# | https://www.petri.com/manage-windows-updates-with-powershell-module            |
# |                                                                                |
# | REVISIONS:                                                                     |
# | 09/05/2019 - Matt Whalley - Version 1.0                                        |
# |  - Script Created.                                                             |
# |                                                                                |
# +--------------------------------------------------------------------------------+

# Install NuGet in order that we can install PSWindowsUpdate
Write-Host "Installing NuGet"
Install-PackageProvider -Name NuGet -Confirm:$False -Force -ErrorAction SilentlyContinue
Write-Host

# Install PSWindowsUpdate
If(-Not(Get-InstalledModule PSWindowsUpdate -ErrorAction SilentlyContinue)){
	Write-Host "Installing PSWindowsUpdate"
    Install-Module PSWindowsUpdate -Confirm:$False -Force
} Else {
	Write-Host "PSWindowsUpdate is already installed"
}
Write-Host

# Install Microsoft Update
$ServiceManagers = Get-WUServiceManager
If (-Not($ServiceManagers.ServiceID -Contains "7971f918-a847-4430-9279-4a52d1efe18d")) {
	Write-Host "Adding Microsoft Update Service Manager to PSWindowsUpdate"
	Add-WUServiceManager -ServiceID "7971f918-a847-4430-9279-4a52d1efe18d" -Confirm:$False
} Else {
	Write-Host "Microsoft Update Service Manager is configured"
}
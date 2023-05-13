<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script runs my standard build.
.DESCRIPTION  
    Run this to automatically run LSUClient and Windows Updates as well as install various standard applications using winget. Must be ran as Administrator.
.NOTES  
    File Name  : StandardBuild.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2, winget
#>

# Change directory to scripts folder in C:\Temp
Set-Location "C:\Temp\Build"

## Install Apps
Write-Host "Installing Apps..."
winget install -e --id ShareX.ShareX;winget install -e --id Mozilla.Firefox;winget install -e --id Notepad++.Notepad++;winget install -e --id Spotify.Spotify;winget install -e --id VSCodium.VSCodium;winget install -e --id REALiX.HWiNFO;winget install -e --id Klocman.BulkCrapUninstaller;winget install -e --id AgileBits.1Password;winget install -e --id Microsoft.WindowsTerminal;winget install -e --id Git.Git;winget install -e --id Appest.TickTick;winget install -e --id Olivia.VIA;winget install wingetui

# Run LSUClient_auto
.\"\Updates\Lenovo\LSUClient_auto.ps1"

# Run RunWinUpdates_auto
Write-Host "Running Windows Updates..."
.\"\Updates\Windows Update\FireAndForget\FireAndForgetWindowsUpdates.ps1"

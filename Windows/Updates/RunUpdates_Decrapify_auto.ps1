<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script runs LSUClient_auto.ps1 and RunWinUpdates_auto.ps1.
.DESCRIPTION  
    Run this to automatically run LSUClient and Windows Updates. Must be ran as Administrator. You can either copy all files from "Updates" to C:\Temp or run "CopyFilesLocally.ps1" (although this is reliant on the files being on the D:Drive).
.NOTES  
    File Name  : RunUpdates_auto.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Change directory to scripts folder in C:\Temp
Set-Location "C:\Temp"

# Decrapify
Write-Host "Running Decrapifier Script..."
.\"Decrapify.ps1"

# Run LSUClient_auto
.\"\Lenovo\LSUClient_auto.ps1"

# Run RunWinUpdates_auto
Write-Host "Running Windows Updates..."
.\"\Windows Update\FireAndForget\FireAndForgetWindowsUpdates.ps1"

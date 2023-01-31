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
Set-Location "C:\Temp\Build"

# Install applications
## Install VCRedist
Write-Host "Installing VCRedist..."
Invoke-WebRequest -Uri https://aka.ms/vs/17/release/vc_redist.x64.exe -OutFile "C:\Temp\Build\vc_redist.x64.exe"
.\vc_redist.x64.exe /install /quiet /norestart

## Install Microsoft.UI.XAML.2.7
Write-Host "Installing Microsoft.UI.XAML.2.7..."
Add-AppxPackage -Path "C:\Temp\Build\Components\Microsoft.UI.Xaml.2.7_7.2208.15002.0_x64__8wekyb3d8bbwe.appx"

## Install Microsoft.VCLibs.140.00.UWPDesktop
Write-Host "Installing Microsoft.VCLibs.140.00.UWPDesktop..."
Add-AppxPackage -Path "C:\Temp\Build\Components\Microsoft.VCLibs.x64.14.00.Desktop.appx"

## Install WinGet
function Start-WinGetUpdate {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false, HelpMessage = "Decide if you want to skip the WinGet version check, default it set to false")]
        [switch]$SkipVersionCheck = $false
    )

    #Check if script was started as Administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
        Write-Error ("{0} needs admin privileges, exiting now...." -f $MyInvocation.MyCommand)
        break
    }

    # =================================
    #         Static Variables
    # =================================
    #
    # GitHub url for the latest release
    [string]$GitHubUrl = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"

    # The headers and API version for the GitHub API
    [hashtable]$GithubHeaders = @{
        "Accept"               = "application/vnd.github.v3+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    #

    # =================================
    #     Collecting some data
    # =================================
    #
    # Checks if WinGet is installed and if it's installed it will collect the current installed version of WinGet
    [version]$CheckWinGet = $(try { (Get-AppxPackage -Name Microsoft.DesktopAppInstaller).version } catch { $Null })

    <## Checking what architecture your running
    # To Install visualcredist use vc_redist.x64.exe /install /quiet /norestart
    # Now we also need to verify that's the latest version and then download and install it if the latest version is not installed
    # When this is added no need to install Microsoft.VCLibs as it's included in the VisualCRedist
    # Don't have the time for it now but this will be added later#>

    $Architecture = $(Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty SystemType)
    switch ($Architecture) {
        "x64-based PC" {
            [string]$VisualCRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
            [string]$VCLibsUrl = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
            [string]$Arch = "x64"
        }
        "ARM64-based PC" {
            [string]$VisualCRedistUrl = "https://aka.ms/vs/17/release/vc_redist.arm64.exe"
            [string]$VCLibsUrl = "https://aka.ms/Microsoft.VCLibs.arm64.14.00.Desktop.appx"
            [string]$Arch = "arm64"
        }
        "x86-based PC" {
            [string]$VisualCRedistUrl = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
            [string]$VCLibsUrl = "https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx"
            [string]$Arch = "arm64"
        }
        default {
            Write-Error "Your running a unsupported architecture, exiting now..."
            break
        }
    }

    # Checking if Microsoft.VCLibs is installed
    $CheckVCLibs = $(Get-AppxPackage -Name "Microsoft.VCLibs.140.00" -AllUsers | Where-Object { $_.Architecture -eq $Arch })
    #
    $VCLibsOutFile = "$env:TEMP\Microsoft.VCLibs.140.00.$($Arch).appx"

    # Checking if it's a newer version of WinGet to download and install if the user has used the -SkipVersionCheck switch.
    # If WinGet is not installed this section will still run to install WinGet.
    if ($SkipVersionCheck -eq $false -or $null -eq $CheckWinGet) {
        if ($null -eq $CheckWinGet) {
            Write-Output = "WinGet is not installed, downloading and installing WinGet..."
        }
        else {
            Write-Output = "Checking if it's any newer version of WinGet to download and install..."
        }

        # Collecting information from GitHub regarding latest version of WinGet
        try {
            if ($PSVersionTable.PSVersion.Major -ge 7) {
                [System.Object]$GithubInfoRestData = Invoke-RestMethod -Uri $GitHubUrl -Method Get -Headers $GithubHeaders -TimeoutSec 10 -HttpVersion 3.0 | Select-Object -Property assets, tag_name
            }
            else {
                [System.Object]$GithubInfoRestData = Invoke-RestMethod -Uri $GitHubUrl -Method Get -Headers $GithubHeaders -TimeoutSec 10 | Select-Object -Property assets, tag_name
            }
            [string]$latestVersion = $GithubInfoRestData.tag_name.Substring(1)

            [System.Object]$GitHubInfo = [PSCustomObject]@{
                Tag         = $latestVersion
                DownloadUrl = $GithubInfoRestData.assets | where-object { $_.name -like "*.msixbundle" } | Select-Object -ExpandProperty browser_download_url
                OutFile     = "$env:TEMP\WinGet_$($latestVersion).msixbundle"
            }
        }
        catch {
            Write-Error @"
   "Message: "$($_.Exception.Message)<code data-enlighter-language="n" class="EnlighterJSRAW">n
   "Error Line: "$($_.InvocationInfo.Line)</code>
"@
            break
        }

        # Checking if the installed version of WinGet are the same as the latest version of WinGet
        if ($CheckWinGet -le $GitHubInfo.Tag) {
            Write-Output "WinGet has a newer version $($GitHubInfo.Tag), downloading and installing it..."
            Invoke-WebRequest -UseBasicParsing -Uri $GitHubInfo.DownloadUrl -OutFile $GitHubInfo.OutFile

            Write-Output "Installing version $($GitHubInfo.Tag) of WinGet..."
            Add-AppxPackage $($GitHubInfo.OutFile)
        }
        else {
            Write-OutPut "Your already on the latest version of WinGet $($CheckWinGet), no need to update."
        }
    }

    # If Microsoft.VCLibs is not installed it will download and install it
    if ($null -eq $CheckVCLibs) {
        try {
            Write-Output "Microsoft.VCLibs is not installed, downloading and installing it now..."
            Invoke-WebRequest -UseBasicParsing -Uri $VCLibsUrl -OutFile $VCLibsOutFile

            Add-AppxPackage $VCLibsOutFile
        }
        catch {
            Write-Error "Something went wrong when trying to install Microsoft.VCLibs..."
            Write-Error @"
   "Message: "$($_.Exception.Message)<code data-enlighter-language="n" class="EnlighterJSRAW">n
   "Error Line: "$($_.InvocationInfo.Line)</code>
"@
            break
        }
    }

    # Starts to check if you have any softwares that needs to be updated
    Write-OutPut "Checks if any software needs to be updated"
    try {
        WinGet.exe upgrade --all --silent --force --accept-source-agreements --disable-interactivity --include-unknown
        Write-Output "Everything is now updated."
    }
    catch {
        Write-Error @"
   "Message: "$($_.Exception.Message)<code data-enlighter-language="n" class="EnlighterJSRAW">n
   "Error Line: "$($_.InvocationInfo.Line)</code>
"@
    }

}

Start-WinGetUpdate

## Install Apps
Write-Host "Installing Apps..."
winget install -e --id Greenshot.Greenshot;winget install -e --id Mozilla.Firefox;winget install -e --id Notepad++.Notepad++;winget install -e --id Spotify.Spotify;winget install -e --id VSCodium.VSCodium;winget install -e --id REALiX.HWiNFO;winget install -e --id Klocman.BulkCrapUninstaller;winget install -e --id AgileBits.1Password;winget install -e --id Microsoft.WindowsTerminal;winget install -e --id Git.Git;winget install -e --id Appest.TickTick;winget install -e --id Olivia.VIA;winget install -e --id VideoLAN.VLC

# Run LSUClient_auto
.\"\Updates\Lenovo\LSUClient_auto.ps1"

# Run RunWinUpdates_auto
Write-Host "Running Windows Updates..."
.\"\Updates\Windows Update\FireAndForget\FireAndForgetWindowsUpdates.ps1"
<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script sets the desktop wallpaper for all monitors as C:\temp\wallpaper.jpg
.DESCRIPTION  
    First copy an image (jpeg or jpg) to C:\Temp\. Must be ran as the logged in user.
.NOTES  
    File Name  : SetWallpaper.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Create function
Function Set-Wallpaper {
    <#
        .SYNOPSIS
            Applies a specified wallpaper to the current user's desktop
        
        .PARAMETER Image
            Provide the full path to the image
        
        .EXAMPLE
            Set-WallPaper -Image "C:\Wallpaper\Default.jpg"
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [string]
        $Image
    )
     
    Add-Type -TypeDefinition @"
    using System;
    using System.Runtime.InteropServices;
     
    public class Params
    {
        [DllImport("User32.dll",CharSet=CharSet.Unicode)]
        public static extern int SystemParametersInfo (Int32 uAction,
                                                       Int32 uParam,
                                                       String lpvParam,
                                                       Int32 fuWinIni);
    }
"@ 
     
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
     
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
    
    if ($PSCmdlet.ShouldProcess($Image)) {
        [void][Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
    }
}

# Check if file exists, rename if it does.
$filename = "C:\temp\*.jpg", "C:\temp\*.jpeg"
if (Test-Path -path $filename) {
    Write-Host "File exists, renaming..." -ForegroundColor Green
    Get-ChildItem "C:\temp\*.jpg", "C:\temp\*.jpeg" | Rename-Item -NewName wallpaper.jpg -Force
} 
else {
    Write-Host "File does not exist" -ForegroundColor Red
    break
}

# Set wallpaper
Write-Host "Setting Wallpaper..." -ForegroundColor Green
Set-Wallpaper -Image C:\temp\wallpaper.jpg

# Post-Script Cleanup
Write-Host "Cleaning up..."
Remove-Item C:\Temp\wallpaper.jpg
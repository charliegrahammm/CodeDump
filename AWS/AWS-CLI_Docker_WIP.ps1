<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script will automatically install the AWS CLI and Docker. 
.DESCRIPTION  
    You will need to run this script as an Administrator. If you dont run as admin, the script will self-elevate.
.NOTES  
    File Name  : AWS-CLI_Docker_install.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell V2
#>

# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue." -ForegroundColor White -BackgroundColor Red 
    Start-Sleep 1
    Write-Host "Launching in Admin mode" -ForegroundColor White -BackgroundColor Green
    $pwshexe = (Get-Command 'powershell.exe').Source
    Start-Process $pwshexe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# Install Modules if not detected
$r = Get-WmiObject Win32_Product | Where-Object { $_.Name -match 'AWS Command Line Interface v2' }

# Install AWS CLI
if ($null -eq $r) {
    Write-Host "AWS CLI does not exist, installing..." -ForegroundColor Red
    $command = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12"
    Invoke-Expression $command
    Invoke-WebRequest -Uri "https://awscli.amazonaws.com/AWSCLIV2.msi" -Outfile C:\AWSCLIV2.msi
    $arguments = "/i `"C:\AWSCLIV2.msi`" /quiet"
    Start-Process msiexec.exe -ArgumentList $arguments -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
} 
else {
    Write-Host "AWS CLI exists" -ForegroundColor White -BackgroundColor Green
    $arguments = "/i `"C:\AWSCLIV2.msi`" /quiet"
    Start-Process msiexec.exe -ArgumentList $arguments -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
}

# Install Chocolatey
if(test-path "C:\ProgramData\chocolatey\choco.exe"){
    Write-Host "Chocolatey installed"
}
else{
    Write-Host "Chocolatey does not exist, installing..." -ForegroundColor Red
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))    
}

# Install Docker Desktop
choco install docker-desktop

# # Configure credentials if not already
# if (Test-Path -Path $env:userprofile\.aws\credentials -PathType Leaf) {
#     Write-Host "AWS credentials found" -ForegroundColor White -BackgroundColor Green
# } 
# else {
#     Write-Host "AWS Credentials missing, please specify..." -ForegroundColor White -BackgroundColor Red
#     aws configure set default.region us-west-2
#     aws configure set default.output yaml
#     aws configure
# }

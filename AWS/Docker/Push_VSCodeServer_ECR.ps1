<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script will pull the latest linuxserver/code-server docker image and push it to AWS ECR.
.DESCRIPTION  
    Pulls the latest linuxserver/code-server docker image from docker hub and pushes it to AWS ECR
.NOTES  
    File Name  : ScriptName.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell V2, AWS CLI, Docker
#>

# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
If (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue."-f DarkRed
    Start-Sleep 1
    Write-Host "Launching in Admin mode" -f Green
    $pwshexe = (Get-Command 'powershell.exe').Source
    Start-Process $pwshexe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}

# Pull latest docker image
docker pull linuxserver/code-server

# Gather stdin
$stdin = Read-Host -Prompt 'Input your password-stdin'

# Authenticate against AWS
aws ecr get-login-password --region region | docker login --username AWS --password-stdin $stdin.dkr.ecr.region.amazonaws.com

# Build image
docker build -t vscode-server .

# Tag image
docker tag vscode-server:latest $stdin.dkr.ecr.eu-west-2.amazonaws.com/vscode-server:latest

# Push image
docker push $stdin.dkr.ecr.eu-west-2.amazonaws.com/vscode-server:latest
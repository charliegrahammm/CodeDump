<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script will automatically pull a list of EC2 instances using the credentials you set up in the region you configure. It will then ask you which instance you wish to start.  
.DESCRIPTION  
    It uses the AWS CLI to do this so you will need to run as Administrator. If you dont run as admin, the script will self-elevate.

    You will be best off setting the below: 

    Access Key ID: <YOUR ACCESS KEY ID>
    Secret Access Key: <YOUR SECRET ACCESS KEY>
    Default Region Name: eu-west-2
    Default Output Format: table
.NOTES  
    File Name  : StopEC2Instance.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell V2, AWS CLI
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
$r = Get-WmiObject Win32_Product | Where { $_.Name -match 'AWS Command Line Interface v2' }

# Install AWS CLI
if ($r -eq $null) {
    Write-Host "AWS CLI does not exist, installing..." -ForegroundColor White -BackgroundColor Red 
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

# Configure credentials if not already
if (Test-Path -Path $env:userprofile\.aws\credentials -PathType Leaf) {
    Write-Host "AWS credentials found" -ForegroundColor White -BackgroundColor Green
} 
else {
    Write-Host "AWS Credentials missing, please specify..." -ForegroundColor White -BackgroundColor Red
    aws configure set default.region us-west-2
    aws configure set default.output yaml
    aws configure
}

# Show list of instance names and allow user to choose one
$choice = aws ec2 describe-instances --query "Reservations[].Instances[].Tags[].Value" | Out-GridView -PassThru

if ($choice) {
    # If an item was selected and user pressed `OK`
    $chosenInstance = $choice.replace("- ", "")
}
else {
    # If user clicked `Cancel` or closed the window
    Write-Host "User Cancelled" -ForegroundColor White -BackgroundColor Red
    exit
}

# Extract InstanceID for chosen instance and cleanup
$choiceInstanceID = aws ec2 describe-instances --filters Name=tag:Name,Values=$chosenInstance --query 'Reservations[*].Instances[*].{Instance:InstanceId}'
$chosenInstanceID = $choiceInstanceID.replace("- - Instance: ", "")

# Start chosen instance
Write-Host "Starting chosen instance..." -ForegroundColor White -BackgroundColor Green
aws ec2 stop-instances --instance-ids $chosenInstanceID


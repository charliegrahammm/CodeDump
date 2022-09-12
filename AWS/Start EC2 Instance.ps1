# This will self elevate the script with a UAC prompt since this script needs to be run as an Administrator in order to function properly.
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "You didn't run this script as an Administrator. This script will self elevate to run as an Administrator and continue." -ForegroundColor White -BackgroundColor Red 
    Start-Sleep 1
    Write-Host "Launching in Admin mode" -ForegroundColor White -BackgroundColor Green
    $pwshexe = (Get-Command 'powershell.exe').Source
    Start-Process $pwshexe -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"{0}`"" -f $PSCommandPath) -Verb RunAs
    Exit
}


## Install Modules if not detected
# Install AWS.Tools.EC2
if (Get-Module -ListAvailable -Name AWS.Tools.EC2) {
    Write-Host "Module exists" -ForegroundColor White -BackgroundColor Green
    Import-Module AWS.Tools.EC2
} 
else {
    Write-Host "Module does not exist, installing..." -ForegroundColor White -BackgroundColor Red 
    Install-Module -Name AWS.Tools.EC2
    Import-Module AWS.Tools.EC2
}

# Setup credentials if not stored
$testCred = Get-AWSCredential -ProfileName Automation

if ("Amazon.Runtime.BasicAWSCredentials" -eq $testCred) {
    Write-Host "Profile exists" -ForegroundColor White -BackgroundColor Green
} 
else {
    Write-Host "Profile does not exist" -ForegroundColor White -BackgroundColor Red 
    #    $accessKey = Read-Host -Prompt "Enter your Access Key"
    #    $secretKey = Read-Host -Prompt "Enter your Secret Key"
    $accessKey = "AKIARSCFFDZIJC67XG75"
    $secretKey = "XskUr+sKTmM0hWAbArDIDI3+xaKzyfwTSE9mF+6G"

    Set-AWSCredential -AccessKey $accessKey -SecretKey $secretKey -StoreAs Automation  
}

# Sign in with stored ec2-cli IAM
Set-AWSCredential -ProfileName Automation

# List instances Available
Write-Host "Listing available Instances"

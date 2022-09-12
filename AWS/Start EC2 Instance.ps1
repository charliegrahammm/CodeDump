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
    aws --version
} 
else {
    Write-Host "AWS CLI exists" -ForegroundColor White -BackgroundColor Green
    $arguments = "/i `"C:\AWSCLIV2.msi`" /quiet"
    Start-Process msiexec.exe -ArgumentList $arguments -Wait
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    aws --version
}

# Setup credentials if not stored
<# $accessKey 
$secretKey
$region = eu-west-2
$outputFormat = json #>

aws configure --profile Automation

<# # Setup credentials if not stored
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
Write-Host "Listing available Instances" #>

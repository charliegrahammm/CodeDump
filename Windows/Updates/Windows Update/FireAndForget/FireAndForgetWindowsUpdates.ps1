<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script continuously runs, installs Windows Updates, reboots, logs back in and runs again until all available updates are installed. 
.DESCRIPTION  
    Checks for updates using PSWindowsUpdate. If updates are found the computer is set to automatically login with specified credentials and continue running updates.
.NOTES  
    File Name  : FireAndForgetWindowsUpdates.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2, PSWindowsUpdate
#>

# Force TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Allow PSGallery Repository
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted

# Install NuGet if not already
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install PSWindowsUpdate if not already
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Write-Host "PSWindowsUpdate Module exists" -ForegroundColor Green
    Update-Module -Name PSWindowsUpdate
    Import-Module PSWindowsUpdate
} 
else {
    Write-Host "PSWindowsUpdate does not exist" -ForegroundColor Red
    Install-Module -Name PSWindowsUpdate
    Import-Module PSWindowsUpdate
}

$TranscriptFilename = "C:\Windows\Temp\FireAndForgetUpdates - $(get-date -f "yyyy-MM-dd HH.mm.ss").txt"
Start-Transcript -Path $TranscriptFilename

Try {
	$ScheduledTaskName = "FireAndForgetWindowsUpdates"

	# Load assembly for Windows Forms.
	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

	# Directory Services (used for account validation)
	Add-Type -AssemblyName System.DirectoryServices.AccountManagement
	$objDS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine')

	Write-Host
	Write-Host "--== Fire And Forget Windows Updates ==--"

	# Get and install all updates
	Write-Host -NoNewLine "Checking for Windows Updates ... "
	If (Get-WindowsUpdate) {
		# We have updates to install.
		Write-Host -ForegroundColor Red "Outstanding Updates Found!"
		
		# Obtain credentials for user
		$CredentialsValid = $False
		While (-Not($CredentialsValid)) {
		
			# If we don't already have stored credentials
			If (-Not(Test-Path "$($env:TEMP)\LocalUserCredentials.xml")) {
				Write-Host "No stored credentials found. Please enter local user credentials."
			}
			Else {
				Write-Host -NoNewLine "Stored credentials were found"
				# Read in the user credentials from the file
				$UserCredentials = Import-CliXml "$($env:TEMP)\LocalUserCredentials.xml"
				$LocalUsername = $UserCredentials.GetNetworkCredential().Username
				$LocalPassword = $UserCredentials.GetNetworkCredential().Password

				# Verify that the credentials are valid
				$CredentialsValid = $objDS.ValidateCredentials($LocalUsername, $LocalPassword)
				If ($CredentialsValid) {
					Write-Host -NoNewLine " and they are "
					Write-Host -ForegroundColor Green "Valid"
				}
				Else {
					Write-Host -NoNewLine " but they are "
					Write-Host -ForegroundColor Red "Invalid"
				}
			}
		
			If (-Not($CredentialsValid)) {
				Write-Host "Prompting for user credentials. Enter your Username and Password"
				# Read in user credentials and then export to an encrypted XML file
				# Note: this file is only decrypted on the computer on which is created by the account who created it.
				Get-Credential | Export-CliXml "$($env:TEMP)\LocalUserCredentials.xml"

				# Read in the user credentials from the file
				$UserCredentials = Import-CliXml "$($env:TEMP)\LocalUserCredentials.xml"
				$LocalUsername = $UserCredentials.GetNetworkCredential().Username
				$LocalPassword = $UserCredentials.GetNetworkCredential().Password

				# Verify that the credentials are valid
				$CredentialsValid = $objDS.ValidateCredentials($LocalUsername, $LocalPassword)
				
				If (-Not($CredentialsValid)) {
					Write-Host -NoNewLine "Entered credentials are "
					Write-Host -NoNewLine -ForegroundColor Red "Invalid"
					Write-Host ". Prompting for re-entry."
					$Return = [System.Windows.Forms.MessageBox]::Show("The credentials you entered were not valid for the local machine. Try again?", "Invalid Credentials", [System.Windows.Forms.MessageBoxButtons]::OKCancel)	
					If ($Return -eq "Cancel") {
						Write-Host "Operation was cancelled by user."
						Return
					}
				}
				Else {
					Write-Host -NoNewLine "Entered credentials are "
					Write-Host -ForegroundColor Green "Valid"
				}
			}
		}
		
		# Set the machine to auto-login as LocalUser
		Write-Host "Setting Auto-Login for user"
		$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"

		Set-ItemProperty $RegPath "AutoAdminLogon" -Value "1" -type String 
		Set-ItemProperty $RegPath "DefaultUsername" -Value "$LocalUsername" -type String 
		Set-ItemProperty $RegPath "DefaultPassword" -Value "$LocalPassword" -type String

		# Set a scheduled task to re-run this script
		Write-Host "Setting a scheduled task to re-run this script at the logon of user"

		$ScheduledTask = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue
		If ($ScheduledTask) {
			# Remove the Scheduled Task if it already exists
			Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$False -ErrorAction SilentlyContinue
		}

		# Create the scheduled task
		$STT = New-ScheduledTaskTrigger -AtLogon -User $LocalUsername
		$ActionArguments = "-NoProfile -ExecutionPolicy Bypass -File ""$PSCommandPath"""
		# $ActionArguments = "-NoProfile -ExecutionPolicy Bypass ""Test"""
		$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $ActionArguments
		$STP = New-ScheduledTaskPrincipal $LocalUsername -RunLevel Highest
		$STS = New-ScheduledTaskSettingsSet -RestartInterval (New-TimeSpan -Minutes 1) -RestartCount 3 -StartWhenAvailable -Compatibility Win8
		$ScheduledTask = New-ScheduledTask -Trigger $STT -Action $Action -Principal $STP -Settings $STS
		Register-ScheduledTask -TaskName $ScheduledTaskName -InputObject $ScheduledTask
			
		# Clear previous job
		Write-Host "Clearing previous job..."
		Clear-WUJob

		# Check for Windows Updates
		Write-Host "Checking for updates..."
		$updates = Get-WindowsUpdate
		Write-Host $updates.count updates available

		# Run Windows Updates and reboot automatically
		Write-Host "Installing updates..." 
		Install-WindowsUpdate -AcceptAll -IgnoreReboot 

	}
 Else {
		# No more updates to install
		Write-Host -ForegroundColor Green "No Outstanding Updates Found!"

		# Remove the auto-login settings for LocalUser
		Write-Host "Removing Auto-Login for user"
		$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		Set-ItemProperty $RegPath "AutoAdminLogon" -Value "0" -type String 
		Set-ItemProperty $RegPath "DefaultUsername" -Value "" -type String 
		Set-ItemProperty $RegPath "DefaultPassword" -Value "" -type String

		# Remove the Scheduled Task
		Write-Host "Removing the scheduled task to re-run this script at the logon of user"
		$ScheduledTask = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue
		If ($ScheduledTask) {
			# Delete
			Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$False -ErrorAction SilentlyContinue
		}

		# Remove stored credentials
		If (Test-Path "$($env:TEMP)\LocalUserCredentials.xml") {
			Remove-Item -Path "$($env:TEMP)\LocalUserCredentials.xml" -Force
		}

		Write-Host -ForegroundColor Green "Fire And Forget Windows Updates are now complete."
	} 
}
Finally {
	Stop-Transcript | Out-Null
	
	# Reboot
	Restart-Computer -Force
}
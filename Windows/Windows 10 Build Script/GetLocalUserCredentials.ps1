# +----------------------------------+---------------------------------------------+
# |   ___    ____    _   _   _       | Title:   GetLocalUserCredentials.ps1        |
# |  / _ \  |  _ \  | | | | | |      | Author:  Matt Whalley                       |
# | | | | | | |_) | | |_| | | |      | Date:    16/07/2019                         |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                |
# |  \__\_\ |_|     |_| |_| |_____|  |                                             |
# +----------------------------------+---------------------------------------------+
# | DESCRIPTION:                                                                   |
# | Gets the Local User credentials and stores them to an encrypted                |
# | credential file. This is so that credentials can be entered at the beginning   |
# | of the build scripts so you can just walk away after starting the run.         |
# |                                                                                |
# | REVISIONS:                                                                     |
# | 16/07/2019 - Matt Whalley - Version 1.0                                        |
# |  - Script Created.                                                             |
# |                                                                                |
# +--------------------------------------------------------------------------------+

# Load assembly for Windows Forms.
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null

# Directory Services (used for account validation)
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$objDS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext('machine')

# Obtain credentials for localuser
$CredentialsValid = $False
While (-Not($CredentialsValid)) {

	# If we don't already have stored credentials
	If (-Not(Test-Path "$($env:TEMP)\LocalUserCredentials.xml")) {
		Write-Host "No stored credentials found. Please enter local user credentials."
	} Else {
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
		} Else {
			Write-Host -NoNewLine " but they are "
			Write-Host -ForegroundColor Red "Invalid"
		}
	}

	If (-Not($CredentialsValid)) {
		Write-Host "Prompting for user credentials"
		# Read in user credentials and then export to an encrypted XML file
		# Note: this file is only decrypted on the computer on which is created by the account who created it.
		Get-Credential "localuser" | Export-CliXml "$($env:TEMP)\LocalUserCredentials.xml"

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
			$Return = [System.Windows.Forms.MessageBox]::Show("The credentials you entered were not valid for the local machine. Try again?","Invalid Credentials",[System.Windows.Forms.MessageBoxButtons]::OKCancel)	
			If ($Return -eq "Cancel") {
				Write-Host "Operation was cancelled by user."
				Return
			}
		} Else {
			Write-Host -NoNewLine "Entered credentials are "
			Write-Host -ForegroundColor Green "Valid"
		}
	}
}
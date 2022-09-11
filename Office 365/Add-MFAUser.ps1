# +----------------------------------+---------------------------------------------+
# |   ___    ____    _   _   _       | Title:   Add-MFAUser.ps1                    |
# |  / _ \  |  _ \  | | | | | |      | Author:  Matt Whalley                       |
# | | | | | | |_) | | |_| | | |      | Date:    10/03/2020                         |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                |
# |  \__\_\ |_|     |_| |_| |_____|  |                                             |
# +----------------------------------+---------------------------------------------+
# | DESCRIPTION:                                                                   |
# | Adds a user to Microsoft Multi-Factor Authentication Server.                   |
# | Sends an email to the user if required.                                        |
# |                                                                                |
# | PARAMETERS:                                                                    |
# | Credential 		- PowerShell Credential Object. Used to connect to MFA Server. |
# | Username 		- String. User to add to MFA. Must be a valid AD user.         |
# | Phone	    	- String. Mobile Phone Number of the User                      |
# | CountryCode	   	- String. Country Code for Mobile Phone Number.                |
# | SendEmail		- Switch. Send an email to the user.                           |
# | EmailProfile	- String. Name of email profile to use when sending email.     |
# | Help	    	- Switch. Display help for this script.                        |
# |                                                                                |
# | REVISIONS:                                                                     |
# | 10/03/2020 - Matt Whalley - Version 1.0                                        |
# |  - Script Created.                                                             |
# |                                                                                |
# +--------------------------------------------------------------------------------+

# http://sqlthing.blogspot.com/2018/04/managing-azure-mfa-server-with.html

Param (
	$Credential,
	[string]$Username,
	[string]$Phone,
	[string]$CountryCode = "44",
	[switch]$SendEmail,
	[string]$EmailProfile,
	[switch]$Help
)

Function Add-MFAUser {

	Param (
		[string]$FirstName,
		[string]$LastName,
		[string]$Username,
		[string]$EmailAddress,
		[string]$Phone,
		[string]$CountryCode
	)

	# Objects to pass to addUserSettings
	$Mode = New-Object ($ns + ".Mode")
	$Mode = "smsText"

#	$Mode = New-Object ($ns + ".Mode")
#	$Mode = "smsText"

	$SmsDirection  = New-Object ($ns + ".SmsDirection")
	$SmsDirection = "twoWay"

	$SmsMode  = New-Object ($ns + ".SmsMode")
	$SmsMode = "otp"


	$addUserSettings = New-Object ($ns + ".addUserSettings")
	$addUserSettings.FirstName = $FirstName
	$addUserSettings.LastName = $LastName
	$addUserSettings.EmailAddress = $EmailAddress
	$addUserSettings.CountryCode = $CountryCode
	$addUserSettings.Phone = $Phone
	$addUserSettings.Enabled = $True
#	$addUserSettings.Mode = $Mode
	$addUserSettings.SmsDirection = $SmsDirection
	$addUserSettings.SmsMode = $SmsMode
	

	$SendMFAEmail = $False
	$ErrorCode = New-Object ($ns + ".Error")

	# Add the User
	Try {
		Write-Host -NoNewLine " - Attempting to add user to MFA"
		$Result = $Proxy.AddUser($Username, $AddUserSettings, $SendMFAEmail, $Null, [ref]$ErrorCode)
		
		If ($Result) {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "User added."
			Return $True
		} Else {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Red "Could not add user. Error Code: $($ErrorCode.Code), Error Description: $($ErrorCode.Description)"
			Return $False
		}
		
	} Catch {
		Write-Host -NoNewLine " - "
		Write-Host $_.Exception.Message
		Return $False
	}

}

Function Send-Email {

	Param (
		[string]$FirstName,
		[string]$EmailAddress,
		[string]$Subject,
		[string]$Body,
		[string]$SMTPServer,
		[string]$FromEmail,
		[string]$FromDisplayName,
		$Attachments
	)
	
	$From = New-Object System.Net.Mail.MailAddress($FromEmail, $FromDisplayName)
	
	$MailParams = @{
		 To = $EmailAddress
		 From = $SMTPUsername
		 Subject = $Subject
		 Body = $Body
	}

	Write-Host -NoNewLine " - Sending Email"
	
	Try {
		Send-MailMessage -From $From -To $EmailAddress -Subject "$Subject" -Body $Body -BodyAsHTML -Attachments $Attachments -Priority High -dno onSuccess, onFailure -SmtpServer $SMTPServer -ErrorAction Stop
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Green "OK!"
		Return $True
	} Catch {
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Red "Failed! Error: $($_.Exception.Message)."
		Return $False
	}
		
	# Send-MailMessage @MailParams -BodyAsHTML -Priority High -Port $Port -SmtpServer $SMTPServer -UseSSL -Credential $creds	

}

# ------------------------------------- Start of Main Script Body -------------------------------------

	If ($PSBoundParameters.Count -Eq 0) {$Help = $True}

	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ Verify / Process Parameters ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	If ($Help) {
		Write-Host
		Write-Host "PARAMETERS:"
		Write-Host "Credential		- PowerShell Credential Object. Used to connect to MFA Server."
		Write-Host "Username		- String. User to add to MFA. Must be a valid AD user."
		Write-Host "Phone			- String. Mobile Phone Number of the User"
		Write-Host "CountryCode		- String. Country Code for Mobile Phone Number."
		Write-Host "SendEmail		- Switch. Send an email to the user."
		Write-Host "EmailProfile		- String. Name of email profile to use when sending email."
		Write-Host "Help			- Switch. Display help for this script."
		Write-Host
		Write-Host "Examples:"
		Write-Host "If you don't specify Credential, you will be prompted to enter one."
		Write-Host ".\Add-MFAUser.ps1 -Username ""tronald.dump"" -Phone ""0898505050"" -SendEmail -EmailProfile ""QPHLUser_Win10VPN"""
		Write-Host
		Write-Host "Otherwise, you can set a credential like"
		Write-Host '$Credential = Get-Credential'
		Write-Host "And then pass it into the script like so -"
		Write-Host '.\Add-MFAUser.ps1 -Credential $Credential -Username "tronald.dump" -Phone "0898505050" -SendEmail -EmailProfile "QPHLUser_Win10VPN"'

		Write-Host
		Return
	}

# Import Active Directory Module
Import-Module ActiveDirectory

$ScriptPath = Split-Path $MyInvocation.MyCommand.Path -Parent
$AUARootPath = Split-Path $ScriptPath -Parent
$ScriptName = $MyInvocation.MyCommand.Name 

# Include the ini functions
. "$AUARootPath\Ancillary Scripts\IniFunctions\Ini_Functions.ps1"

# General ini file
$GeneralIni = "$ScriptPath\MFA-Functions.ini"

Write-Host
Write-Host -NoNewLine " - Opening config '$GeneralIni'"
# If the settings.ini file is found at the specified location
If (!(Test-Path $GeneralIni)) {
	# If ini file not found, quit
	Write-Host -NoNewLine " - "
	Write-Host -ForegroundColor Red "Failed. Couldn't find file!" 
	Return $False
} Else {
	Write-Host -NoNewLine " - "
	Write-Host -ForegroundColor Green "OK."
}

# Initial Values
$BoolCredentialsOK = $False
$BoolConnected = $False

	Write-Host -NoNewLine " - Checking Credential Parameter"
	# Check Credentials are passed as parameter
	If (!($Credential)) {
		# If not, get some
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Red "None entered! Prompting user."
		$Credential = Get-Credential -Message "Please enter Credential to connect to MFA Server in DOMAIN\Username format"
	} Else {
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Green "OK."
	}

	# Check that Credentials are available
	Write-Host -NoNewLine " - Confirming Credential"
	If ($Credential.UserName) {
		If ($Credential.GetNetworkCredential().Password) {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "Credential is Available."
			
			# Authenticate Credentials
			$CurrentDomain = "LDAP://" + ([ADSI]"").distinguishedName
			$Domain = New-Object System.DirectoryServices.DirectoryEntry($CurrentDomain,$Credential.UserName,$Credential.GetNetworkCredential().Password)

			Write-Host -NoNewLine " - Authenticating Credential"
			If ($Domain.name -eq $null) {
				Write-Host -NoNewLine " - "
				Write-Host -ForegroundColor Red "Failed - please verify the username and password."
				$BoolCredentialsOK = $False
				
			} Else{
				Write-Host -NoNewLine " - "
				Write-Host -ForegroundColor Green "Successfully authenticated with domain '$($Domain.name)'."
				$BoolCredentialsOK = $True
			}
			
		} Else {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Red "No password available in Credential."
			$BoolCredentialsOK = $False
		}
	} Else {
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Red "No username available in Credential."
		$BoolCredentialsOK = $False
	}

	If (!($BoolCredentialsOK)) {Return $False}

	Write-Host -NoNewLine " - Checking UserName Parameter"
	# Check for Username
	If ($UserName) {

		# Get the AD User
		$ADUser = Get-ADUser -Identity $Username -Properties *
		
		# If we find one
		If ($ADUser) {
			# Get the user information
			$FirstName = $ADUser.GivenName
			$LastName = $ADUser.Surname
			$EmailAddress = $ADUser.EmailAddress
			$Username = $ADUser.UserPrincipalName
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "Found AD User record for '$Username'."
		} Else {
			# Otherwise quit
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Red "Couldn't find an AD User record for '$Username'"
			Return $False
		}
	
	} Else {
		# Missing info, quit
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Red "UserName is required!"
		Return $False
	}
	
	Write-Host -NoNewLine " - Checking Phone Parameter"
	If (!($Phone)) {
		# Missing info, quit
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Red "missing!" 
		Return $False
	} Else {
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Green "OK."
		
		# Strip out non-digits
		$Phone = $Phone -Replace "\D"
	}
	
	Write-Host -NoNewLine " - Checking CountryCode Parameter"
	If (!($CountryCode)) {
		# Missing info, quit
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Red "missing!" 
		Return $False
	} Else {
		Write-Host -NoNewLine " - "
		Write-Host -NoNewLine -ForegroundColor Green "exists. "
		
		# Strip out non-digits
		$CountryCode = $CountryCode -Replace "\D"
		
		# Country code can be 3 digits, TODO: Proper validation.
		#If ($CountryCode.Length -eq 2) {
		#	Write-Host -NoNewLine -ForegroundColor Green "Is valid."
		#} Else {
		#	Write-Host -NoNewLine -ForegroundColor Red "Is invalid!"
		#	Return $False
		#}
	}
	
	Write-Host -NoNewLine " - Checking SendEmail Parameter"
	If ($SendEmail) {
	
		Write-Host -NoNewLine " - "
		Write-Host -ForegroundColor Green "SendEmail parameter set."
	
	 	Write-Host -NoNewLine " - Reading ini file '"
		Write-Host -NoNewLine -ForegroundColor Magenta "$GeneralIni"
		Write-Host "'"
		Write-Host -NoNewLine "     - Reading SMTPServer"
		# Read settings from ini file
		$SMTPServer = Get-IniValue -IniFilePath $GeneralIni -Section "EmailSettings" -Key "SMTPServer"
		
		If (!($SMTPServer)) {
			# If no SMTPServer in ini, quit
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Red "Not found!" 
			Return $False
		} Else {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "'$SMTPServer'. OK."
		}
		
		Write-Host -NoNewLine "     - Reading FromEmail"
		$FromEmail = Get-IniValue -IniFilePath $GeneralIni -Section "EmailSettings" -Key "FromEmail"
		
		If (!($FromEmail)) {
			# If no FromEmail in ini, quit
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Red "Not found!" 
			Return $False
		} Else {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "'$FromEmail'. OK."
		}
		
		Write-Host -NoNewLine "     - Reading FromDisplayName"
		$FromDisplayName = Get-IniValue -IniFilePath $GeneralIni -Section "EmailSettings" -Key "FromDisplayName"
	
		If (!($FromDisplayName)) {
			# If no FromEmail in ini, quit
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Red "Not found!" 
			Return $False
		} Else {
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "'$FromDisplayName'. OK."
		}

		Write-Host -NoNewLine " - Checking EmailProfile Parameter"
		# If we're sending an email, we need the email profile
		If ($EmailProfile) {
			
			Write-Host -NoNewLine " - "
			Write-Host -ForegroundColor Green "'$EmailProfile'. OK."
			
			# Build Paths
			$EmailProfilePath = "$ScriptPath\EmailTemplates\$EmailProfile"
			$EmailProfileIni = "$EmailProfilePath\Settings.ini"
			$EmailBodyPath = "$EmailProfilePath\EmailBody.txt"

			Write-Host -NoNewLine " - Reading ini file '"
			Write-Host -NoNewLine -ForegroundColor Magenta "$EmailProfileIni"
			Write-Host -NoNewLine "'"
			# If the settings.ini file is found at the specified location
			If (Test-Path $EmailProfileIni) {
			
				Write-Host
				Write-Host -NoNewLine "     - Reading Subject"
				# Get the subject from the ini file
				$Subject = Get-IniValue -IniFilePath $EmailProfileIni -Section "EmailSettings" -Key "Subject"
				
				If (!($Subject)) {
					# If no subject in ini, quit
					Write-Host -NoNewLine " - "
					Write-Host -ForegroundColor Red "Not found!" 
					Return $False
				} Else {
				Write-Host -NoNewLine " - "
					Write-Host "'$Subject'. OK."
				}

				Write-Host -NoNewLine "     - Reading Attachments"
				# Get the attachment list from the ini file
				$Attachments = Get-IniValue -IniFilePath $EmailProfileIni -Section "EmailSettings" -Key "Attachments"

				# If we return a value
				If ($Attachments) {
					# Split into an array
					$Attachments = $Attachments.Split(";")
					#Prepend path to filename
					$Attachments = $Attachments | ForEach-Object {"$EmailProfilePath\$_"}
					Write-Host -NoNewLine " - "
					Write-Host "$($Attachments.Count) attachments." 
				} Else {
					Write-Host -NoNewLine " - "
					Write-Host "No attachments."
				}
			
			} Else {
				# If ini file not found, quit
				Write-Host -NoNewLine " - "
				Write-Host -ForegroundColor Red "File not found!" 
				Return $False
			}
			
			Write-Host -NoNewLine " - Reading EmailBody from '$EmailBodyPath'"
			# If the EmailBody.txt file is found 
			If (Test-Path $EmailBodyPath) {
			
				# Read the content in
				$Body = Get-Content -Path $EmailBodyPath
				
				If (!($Body)) {
					# If no text in EmailBody.txt, quit
					Write-Host -NoNewLine " - "
					Write-Host -ForegroundColor Red "File empty!" 
					Return $False
				} Else {
					Write-Host -NoNewLine " - "
					Write-Host -ForegroundColor Green "OK."
				}
				
			} Else {
				# If body file not found, quit
				Write-Host -NoNewLine " - "
				Write-Host -ForegroundColor Red "File not found!" 
				Return $False
			}
		
		} Else {
			Write-Host -ForegroundColor Red " - Missing. Since you have specified 'SendEmail', you must specify the EmailProfile to use!" 
			Return $False
		}	
		#
	} Else {
		#False or Not Specified - Default to False
		$SendEmail = $False
		
		Write-Host -NoNewLine " - "
		Write-Host "Not set, default to False."
	}
	
	# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Connect to MFA Server

# Read settings from ini file
Write-Host -NoNewLine " - Reading ini file '"
Write-Host -NoNewLine -ForegroundColor Magenta "$GeneralIni"
Write-Host "'"
Write-Host -NoNewLine "     - Reading MFAServer"
$MFAServerURL = Get-IniValue -IniFilePath $GeneralIni -Section "MFAServer" -Key "URL"

If (!($MFAServerURL)) {
	# If no MFAServerURL in ini, quit
	Write-Host -NoNewLine " - "
	Write-Host -ForegroundColor Red "not found!" 
	Return $False
} Else {
	Write-Host -NoNewLine " - "
	Write-Host -ForegroundColor Green "'$MFAServerURL'. OK."
}

Try {
	# Create a WS Proxy to the SOAP Azure MFA WebService SDK Endpoint
	$Proxy = New-WebServiceProxy -Uri $MFAServerURL -Credential $Credential -ErrorAction Stop
	
	If (!($Proxy)) {
		Write-Host -ForegroundColor Red " - Couldn't connect to MFA Web Service! Reminder - you must enter your credentials in DOMAIN\admin.username format e.g. PHARMAXO\mw.admin" 
		Return $False
	}
	
} Catch {
	Write-Host $_.Exception.Message
	Return $False
}
 
# Get Namespace for Objects
$ns = $proxy.GetType().Namespace

$ErrorCode = New-Object ($ns + ".Error")

$AddUserResult = (Add-MFAUser -FirstName $FirstName -LastName $LastName -Username $Username -EmailAddress $EmailAddress -Phone $Phone -CountryCode $CountryCode)

If ($AddUserResult) {
	If ($SendEmail) {
		$Body = $Body.Replace("#FirstName#", $FirstName)
		
		$PhoneWithCC = "(+$CountryCode) $Phone"
		
		$Body = $Body.Replace("#Phone#", $PhoneWithCC)
	
		$SendEmailResult = (Send-Email -FirstName $FirstName -EmailAddress $EmailAddress -Subject $Subject -Body $Body -SMTPServer $SMTPServer -FromEmail $FromEmail -FromDisplayName $FromDisplayName -Attachments $Attachments)	
		If ($SendEmailResult) {
			Return $True
		} Else {
			Return $False
		}
	} Else {
		Return $True
	}
} Else {
	Return $False
}
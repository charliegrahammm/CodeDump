# |   ___    ____    _   _   _       | Title:   check_confluence_backups.ps1                    |
# +----------------------------------+----------------------------------------------------------+
# |  / _ \  |  _ \  | | | | | |      | Author:  Charlie Graham                                  |
# | | | | | | |_) | | |_| | | |      | Date:    17/05/2021                                      |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                             |
# |  \__\_\ |_|     |_| |_| |_____|  |                                                          |
# +----------------------------------+----------------------------------------------------------+
# | DESCRIPTION:                                                                                |
# | Script for Nagios. Checks the status of the Confluence Backup job using AtlasCloud-Backup   |
# |                                                                                             |
# | REVISIONS:                                                                                  |
# | 19/07/2021 - Matt Whalley - Version 1.1                                                     |
# | - Fixed error output not being captured.                                                    |
# | - Added additional check for text "Error" in returned data.                                 |
# |                                                                                             |
# | 17/05/2021 - Charlie Graham - Version 1.0                                                   |
# |  - Script Created.                                                                          |
# |                                                                                             |
# +---------------------------------------------------------------------------------------------+

# Set local parameters to be passed from PRTG sensor
Param (
	[string]$HostName
)	

# Create parameter to be used by Invoke-Command containing script block and target hostname
$parameters = @{
	ComputerName = "$HostName"
	ScriptBlock = {
		
	cd E:\Backup\Confluence\AutomatedBackupScript
	
	# Set 7Zip File Path as "sz" alias
	set-alias sz "$env:ProgramFiles\7-Zip\7z.exe" 
	
	# Specify 7Zip file location
	$7zfile = "E:\Backup\Confluence\AutomatedBackupScript\zip\config.7z" 
	
	# Read in encrypted ZIP password
	$7zCreds = Import-Clixml -Path "E:\Backup\Confluence\AutomatedBackupScript\encrypted_zip_password.xml"
	$7zPass = $7zCreds.GetNetworkCredential().Password 
	
	# Extract YAML file from encrypted ZIP
	$7zResult = [string] (& sz x $7zfile "-p$7zpass" -aoa 2>&1)
	
	# $BackupResult = node . assert-status
	# The above doesn't capture error output - see https://stackoverflow.com/questions/15437244/how-to-pipe-all-output-of-exe-execution-in-powershell - (Matt - 19/07/2021)
	
	$BackupResult = [string] (& node . assert-status 2>&1)
	
	# Delete temporary YAML
	cd "E:\Backup\Confluence\AutomatedBackupScript"
	Remove-Item -Path "E:\Backup\Confluence\AutomatedBackupScript\config.yml" -Force
	# Remove-Item ".\config.yml" -Force 

}}

# Run the command on the specified target and set results as $rtncode
$rtnCode = Invoke-Command @parameters


#Calculate exit code outside of Invoke-Command
If (!$rtnCode -eq 1){
	Write-Host "CRITICAL! Confluence Backup Unhealthy.`n$BackupResult"
	Exit 2
	
} ElseIf (!$rtnCode -eq 0){
	
	If ($BackupResult -Like "*Error*") {
		Write-Host "WARNING! Confluence Backup Status Unknown.`n$BackupResult"
		Exit 1
	}
	Else {
		Write-Host "OK. Confluence Backup Healthy.`n$BackupResult"
		Exit 0
	}
	
} Else {
	 Write-Host "WARNING! Confluence Backup Status Unknown.`n$BackupResult"
	Exit 1
}

Catch {

Write-Host "WARNING: Failure in checking script!\n$($_.Exception)) at line $($_.InvocationInfo.ScriptLineNumber)"
Exit 1

}
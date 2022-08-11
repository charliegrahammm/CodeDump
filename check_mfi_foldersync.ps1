# +----------------------------------+----------------------------------------------------------+
# |   ___    ____    _   _   _       | Title:   check_mfi_foldersync.ps1                        |
# |  / _ \  |  _ \  | | | | | |      | Author:  Michael Camacho                                 |
# | | | | | | |_) | | |_| | | |      | Date:    13/04/2022                                      |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                             |
# |  \__\_\ |_|     |_| |_| |_____|  |                                                          |
# +----------------------------------+----------------------------------------------------------+
# | DESCRIPTION:                                                                                |
# | Script for Nagios. Checks the status of the MFI FolderSync using S3 Browser                 |
# |                                                                                             |
# | 13/04/2022 - Michael Camacho - Version 1.0                                                  |
# |  - Script Created.                                                                          |
# |                                                                                             |
# +---------------------------------------------------------------------------------------------+

# Set local parameters to be passed from PRTG sensor
Param (
	[string]$HostName
)	

# Create parameter to be used by Invoke-Command containing script block and target hostname
$parameters = @{
	ComputerName = "$Hostname"
	ScriptBlock = {
	
$recentS3Sync = "C:\Jobs\MFIView-FolderSync\recent.txt"

Try {
	$syncCompletedCheck = get-content $recentS3Sync | Select-String "Synchronization completed.$"
	$syncCompletedTime = if ($syncCompletedCheck -match "\[I\].*?(\[.*\])") {$matches[1].trim('[]')}
	$syncCompletedFileComparison = get-content $recentS3Sync | Select-String "Completed:" 
	$syncCompletedValues = if ($syncCompletedFileComparison -match ".*\] (.*)") {$matches[1]}
	$errorsS3Reported = Get-Content $recentS3Sync | Select-String -Pattern '\[I\]' -NotMatch
	
	if ($syncCompletedCheck -eq $null) {
		write-output "CRITICAL: Sync not completed yet, likely that the job is still running."
		Exit 2
	} elseif ($errorsS3Reported -eq $null) {
		write-output "Sync completed at $syncCompletedTime. Files $syncCompletedValues"
		Exit 0
	} else {
		write-output "S3 ran into the following errors:`n`n" ($errorsS3Reported -join "`n`n")
		Exit 1
	}

} Catch {
	write-output "Script ran into an error.$($_.Exception) at line $($_.InvocationInfo.ScriptLineNumber)"
    Exit 1
}
}
}

# Run the command on the specified target
Invoke-Command @parameters
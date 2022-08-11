# +----------------------------------------+---------------------------------------------+
# |  ██████╗ ██████╗ ██╗  ██╗██╗           | Title:   check_log_file.ps1                 | 
# | ██╔═══██╗██╔══██╗██║  ██║██║           | Author:  Matt Whalley                       |
# | ██║   ██║██████╔╝███████║██║           | Date:    15/03/2018                         |
# | ██║▄▄ ██║██╔═══╝ ██╔══██║██║           | Version: 1.0                                |
# | ╚██████╔╝██║     ██║  ██║███████╗      |                                             |
# |  ╚══▀▀═╝ ╚═╝     ╚═╝  ╚═╝╚══════╝      |                                             |
# +----------------------------------------+---------------------------------------------+
# | Description:                                                                         |
# | Checks a log file for an error pattern and a recovery pattern. If the error time     |
# | occurs after the last recovery, it is flagged as an unrecovered error.               |
# |                                                                                      |
# | Revision History:                                                                    |
# | 15/03/2018 - Matt Whalley - Version 1.0                                              |
# |  - Script Created                                                                    |
# |                                                                                      |
# +--------------------------------------------------------------------------------------+


# Set local parameters to be passed from PRTG sensor
Param (
	[string]$HostName,
	[string]$LogFile,
	[string]$ErrorPattern,
	[string]$RecoveryPattern 
)	

# Create parameter to be used by Invoke-Command containing script block and target hostname
$parameters = @{
	ComputerName = "$Hostname"
	ScriptBlock = {

# Translate local $TaskName to $TaskName within Invoke-Command	
$LogFile = $Using:LogFile	
$ErrorPattern = $Using:ErrorPattern
$RecoveryPattern = $Using:RecoveryPattern

# Return the last line containing an error
$ErrorResult = Select-String -Path $LogFile -Pattern $ErrorPattern -AllMatches | Select Line

If ($ErrorResult -ne $Null) {	
	If ($ErrorResult.Count -gt 1) {
		$ErrorResult = $ErrorResult[-1].Line
	} Else {
		$ErrorResult = $ErrorResult.Line
	}
	
} Else {
	$OutString = "OK: Log file indicates no errors."
	Write-Host $OutString
	Exit 0
}

# Extract the time from the line (first 24 characters) and convert to a DateTime
$ErrorTime = [DateTime]$ErrorResult.SubString(0,24)

# Return the last line containing an recovery
$RecoveryResult = Select-String -Path $LogFile -Pattern $RecoveryPattern -AllMatches | Select Line
If ($RecoveryResult -ne $Null) {
	If ($RecoveryResult.Count -gt 1) {
		$RecoveryResult = $RecoveryResult[-1].Line
	} Else {
		$RecoveryResult = $RecoveryResult.Line
	}
} Else {
	$OutString = "CRITICAL: Log file indicates an unrecovered error!"
	Write-Host $OutString
	Exit 2
}

# Extract the time from the line (first 24 characters) and convert to a DateTime
$RecoveryTime = [DateTime]$RecoveryResult.SubString(0,24)

If ($RecoveryTime -gt $ErrorTime) {
	$OutString = "OK: Log file indicates no unrecovered errors."
	Write-Host $OutString
	Exit 0
} Else {
	$OutString = "CRITICAL: Log file indicates an unrecovered error!"
	Write-Host $OutString
	Exit 2
}}}


Invoke-Command @parameters
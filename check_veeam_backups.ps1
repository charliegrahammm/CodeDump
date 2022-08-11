# +----------------------------------+----------------------------------------------------------+
# |   ___    ____    _   _   _       | Title:   check_veeam_backups.ps1                         |
# |  / _ \  |  _ \  | | | | | |      | Author:  Matt Whalley                                    |
# | | | | | | |_) | | |_| | | |      | Date:    07/02/2021                                      |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                             |
# |  \__\_\ |_|     |_| |_| |_____|  |                                                          |
# +----------------------------------+----------------------------------------------------------+
# | DESCRIPTION:                                                                                |
# | Script for Nagios. Checks the status of all Veeam backup jobs using the Veeam               |
# | PowerShell cmdlets.                                                                         |
# |                                                                                             |
# | IMPORTANT NOTE:                                                                             |
# | We need to change a couple of values in nsclient.ini on the target server for this to       |
# | work properly as the returned data can be larger than the default payload for Nagios.       |
# |                                                                                             |
# | Add the following line to the [/settings/NRPE/server] section                               |
# | (add both lines if the section does not exist)                                              |
# |                                                                                             |
# |     [/settings/NRPE/server]                                                                 |
# |     payload length=8192                                                                     |
# |                                                                                             |
# | Save the file and restart the NSClient++ service.                                           |
# |                                                                                             |
# | Make sure that the check_nrpe command on the Nagios server is configured to use the same    |
# | e.g.                                                                                        |
# | ./check_nrpe -P 8192 -2 -t 120 -H backup-01.pharmaxo.local -c check_veeam_backups           |
# |                                                                                             |
# | Additionally, make sure that you adjust the timeout to 120 under [/settings/default]        |
# |                                                                                             |
# | YOU WILL HAVE TO UPDATE ANY OTHER NRPE CHECKS FOR THE SERVER TO USE THE SAME PAYLOAD SIZE!  |                                                                                          |
# |                                                                                             |
# |                                                                                             |
# | REVISIONS:                                                                                  |
# | 07/02/2021 - Matt Whalley - Version 1.0                                                     |
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

Function Get-JobResults {

	Param (
		$Backups,
		$BackupSessions,
		$BackupResults
	)

	ForEach ($Backup In $Backups) {
	
		$Name = $Backup.Name
			
		<#
			We process Backup jobs and BackupSync Jobs separately, as the BackupSync jobs report their status in an odd way.
			If the job is currently idle, it can return a status of 'None' so we need to get the latest success or failure message from the logs.
		#>
		
		Try {
			
			If (($Backup.Type -ne "BackupSync") -And ($Backup.JobType -ne "BackupSync")) {
				# Not Backup Copy Job
				
				
				# IsScheduleEnabled is the flag for Backup Jobs, ScheduleEnabled is the flag for Computer (Agent) Backup Jobs.
				If (($Backup.IsScheduleEnabled) -Or $Backup.ScheduleEnabled) {
					# Job is enabled
				
					$LastSession = $BackupSessions | Where {$_.JobId -eq $Backup.Id} | Sort-Object -Property EndTime
					
					If ($LastSession) {
						$JobStatus = $LastSession[$LastSession.Count - 1].Result
						$JobCreationTime = $LastSession[$LastSession.Count - 1].CreationTime
					} Else {
						$JobStatus = "Unknown"
						$JobCreationTime = "RUN TIME NOT KNOWN "
					}
				} Else {
					# Job is disabled
					$JobStatus = "Disabled"
					$JobCreationTime = "JOB IS DISABLED    "
				}
							
			} Else {
				# Backup Copy Job.
				<# 
					These can return a status of 'None' via the session logs because they're fucking weird. 
					Instead, get the actual log for each job and then the latest success or failure message
				#>
				
				$CopyJob = Get-VBRJob -Name $Name
				
				If ($CopyJob) {
				
					If ($CopyJob.IsScheduleEnabled) {
						# Job is enabled
						
						$AgentLogs = $CopyJob.FindLastSession().Logger.GetLog().UpdatedRecords | Sort-Object -Descending -Property UpdateTime
						
						# Loop through agent logs and find most recent message which is either a success or failure.
						ForEach ($AgentLog In $AgentLogs) {
						
							$JobCreationTime = $AgentLog.StartTime
						
							If ($AgentLog.Status -eq "EFailed") {
								# Last Status was Failed! We have an issue
								$JobStatus = "Failed"
								Break
							} ElseIf ($AgentLog.Status -eq "ESucceeded") {
								# Last Status was Successful! No issues
								$JobStatus = "Success"
								Break
							} Else {
								# Last Status was Something else (Probably ENone). Keep looking.
							}
						}
					} Else {
						# Job is disabled.
						$JobStatus = "Disabled"
						$JobCreationTime = "JOB IS DISABLED    "
					}
				
				} Else {
					# Couldn't get handle on job.
					$JobStatus = "Unknown"
					$JobCreationTime = "RUN TIME NOT KNOWN "
				}
			}
		} Catch {
			$JobStatus = "Unknown"
			$JobCreationTime = "RUN TIME NOT KNOWN "	
		}
		
		# Lets only report jobs which were not a success.
		If ($JobStatus -ne "Success") {
			$BackupResults += "$JobCreationTime - $("$JobStatus".ToUpper()) - '$Name'"
		}
		
		If ($JobStatus -eq "Failed"){
			$Critical = $True
		} ElseIf ($JobStatus -eq "Success") {
			# Null
		} Else {
			$Warning = $True
		}
	}
	
	Return $BackupResults, $Critical, $Warning
}

<# --------------------------------------------------- Start Of Main Script Body --------------------------------------------------- #>

<# Debugging
	$TranscriptFilename = "c:\temp\check_veeam_backups $(get-date -f "yyyy-MM-dd HH.mm.ss").txt"
	Start-Transcript -Path $TranscriptFilename
#>

# Initial Values
	$Critical = $False
	$Warning = $False
	$BackupResults = @()

<#

	Get-VBRJob used to return all backup jobs for both standard backups and Computer (agent) backups.
	This is now deprecated, so we have to run Get-VBRJob for standard backups (& copy jobs) and Get-VBRComputerBackupJob for Computer jobs.
 
#>

Try {

	# Import Veeam PowerShell Module
	Import-Module Veeam.Backup.PowerShell -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	
	# Standard Backup Jobs (& Copy Jobs)
		# Get-VBRJob is deprecated for Agent jobs, but still returns them so we have to filter them out.
		$Backups = Get-VBRJob -WarningAction Ignore | Where {$_.TypeToString -NotLike "*Agent*"} | Sort-Object -Property JobType, Name
		
		# Read last 2 months of results into memory, rather than querying individually for each job. This is quicker.
		$BackupSessions = Get-VBRBackupSession | Where {$_.EndTime -ge (Get-Date).AddMonths(-2)} | Sort-Object -Property EndTime

		# Get Results
		$BackupResults, $Critical, $Warning = Get-JobResults -Backups $Backups -BackupSessions $BackupSessions -BackupResults $BackupResults
		
	# Computer (Agent) Backup Jobs
		$AgentBackups = Get-VBRComputerBackupJob | Sort-Object -Property Name
		
		# Read last 2 months of results into memory, rather than querying individually for each job. This is quicker.
		$AgentBackupSessions = Get-VBRComputerBackupJobSession | Where {$_.EndTime -ge (Get-Date).AddMonths(-2)} | Sort-Object -Property EndTime

		# Get Results
		$BackupResults, $Critical, $Warning = Get-JobResults -Backups $AgentBackups -BackupSessions $AgentBackupSessions -BackupResults $BackupResults

	# Computer (Agent) Backup Copy Jobs
		$AgentBackupCopies = Get-VBRComputerBackupCopyJob | Sort-Object -Property Name
		
		# Get Results
		$BackupResults, $Critical, $Warning = Get-JobResults -Backups $AgentBackupCopies -BackupSessions $BackupSessions -BackupResults $BackupResults

	$BackupResultsString = $BackupResults -Join "`n"

	# Calculating #Exit code
	If ($Critical){
		Write-Host "CRITICAL! One or more failed jobs.`n$BackupResultsString"
		Exit 2
		
	} ElseIf ($Warning) {
		Write-Host "WARNING! One or more jobs disabled or with unknown status.`n$BackupResultsString"
		Exit 1
	} Else {
		Write-Host "OK. No failed or unknown jobs.`n$BackupResultsString"
		Exit 0
	}

} Catch {
	
	Write-Host "WARNING: Failure in checking script!\n$($_.Exception)) at line $($_.InvocationInfo.ScriptLineNumber)"
	Exit 1
	
} Finally {
	
	# Remove Veeam PowerShell Module
	Remove-Module Veeam.Backup.PowerShell -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
	
	<# Debugging
		# Stop Transcript
		Stop-Transcript | Out-Null
	#>
}}}

Invoke-Command @parameters
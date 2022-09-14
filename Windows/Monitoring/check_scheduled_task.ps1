# +----------------------------------------+------------------------------------+
# | ___       _   _        _   ___ _   _   | Title:  check_scheduled_task.ps1   | 
# || _ ) __ _| |_| |_     /_\ / __| | | |  | Author: Matt Whalley               |
# || _ \/ _` |  _| ' \   / _ \\__ \ |_| |  | Date:   25/04/2017	                |
# ||___/\__,_|\__|_||_| /_/ \_\___/\___/   | Version: 1.3                       |
# +----------------------------------------+------------------------------------+
# | DESCRIPTION:                                                                |
# | Script for use with Nagios.                                                 |
# | Checks that a scheduled task ran within a specified interval and that the   |
# | return value was a success. Outputs return codes expected by Nagios         |
# |                                                                             |
# | It used the 'schtasks' tool to grab the details of scheduled tasks.         |
# | This is to ensure that it will run in PowerShell 1.0 which doesn't have     |
# | lovely cmdlets like 'Get-ScheduledTask'                                     |
# |                                                                             | 
# | PARAMETERS:                                                                 |
# | TaskName - Name of the Scheduled Task to check                              |
# | RunInterval - Interval at which the Scheduled Task runs                     |
# |                                                                             |
# | REVISIONS:                                                                  |
# | 09/02/2017 - Matt Whalley - Version 1.0                                     |
# |  - Script Created                                                           |
# |                                                                             |
# | 18/04/2017 - Matt Whalley - Version 1.1                                     |
# | - Added additional comments, added switch section. Changed return value     |
# |   formatting                                                                |
# |                                                                             |
# | 20/04/2017 - Matt Whalley - Version 1.2                                     |
# | - Added a fudge to convert string :BS: to backslash, as nagios refused to   |
# |   pass it even with various escape character combos.                        |
# | - Changed the way that the string returned from schtasks is parsed from     |
# |   CMD 'findstr' to PowerShell 'Select-String'                               |
# | - Changed handling of return value 267009, as it means the task is still    |
# |   running, not that it's fallen over                                        |
# |                                                                             |
# | 25/04/2017 - Matt Whalley - Version 1.3                                     |
# | - Added a section to trap more return codes from schtasks.exe               |
# |                                                                             |
# +-----------------------------------------------------------------------------+

# Set local parameters to be passed from PRTG sensor
Param (
	[string]$HostName,
	[string]$TaskName
)	

# Create parameter to be used by Invoke-Command containing script block and target hostname
$parameters = @{
	ComputerName = "$Hostname"
	ScriptBlock  = {	

		# Translate local $TaskName to $TaskName within Invoke-Command
		$TaskName = $Using:TaskName

		$ExitCode = 0

		#$VerbosePreference="Continue" to display on screen, $VerbosePreference="SilentlyContinue" to hide.
		$VerbosePreference = "SilentlyContinue"
		#$VerbosePreference = "Continue"
		$TaskName = $TaskName -Replace "_", " "
		$TaskName = $TaskName -Replace ":BS:", "\" # fudge to get past nagios refusing to pass backslashes

		# Find the line containing the 'Schedule Type' and extract data
		$RawSchedule = $(schtasks /query /FO LIST /V /TN "$TaskName" | Select-String "Schedule Type" | Out-String).trim()
		$Schedule = $RawSchedule.substring(14).trim()

		# Find line containing 'Last Run Time' and extract data
		$RawLastRun = $(schtasks /query /FO LIST /V /TN "$TaskName" | Select-String "Last Run Time" | Out-String).trim()
		$LastRun = Get-Date $RawLastRun.substring(14).trim()

		# Find line containing 'Last Result' and extract data
		$RawLastResult = $(schtasks /query /FO LIST /V /TN "$TaskName" | Select-String "Last Result" | Out-String).trim()
		$LastResult = [int]$RawLastResult.substring(12).trim()

		# Determine the interval frequency in minutes
		Switch ($Schedule) { 
			"Daily" {
				# Read the 'Days' line
				$RawFrequency = $(schtasks /query /FO LIST /V /TN "$TaskName" | Select-String "Days:" | Out-String).trim()
				$RawFrequency = $RawFrequency.substring(5).Trim()
				# Calculate the frequency in minutes (1440 minutes in 1 day, or 24 hours)
				$Frequency = [int]($RawFrequency -replace 'Every (\d+) day\(s\)', '$1') * 1440
			}
		
			"Weekly" {
				# Read 'Months' line. (This also displays weekly repetitions)
				$RawFrequency = $(schtasks /query /FO LIST /V /TN "$TaskName" | Select-String "Months:" | Out-String).trim()
				$RawFrequency = $RawFrequency.substring(7).Trim()
				# Calculate the frequency in minutes (10080 minutes in 1 week)
				$Frequency = [int]($RawFrequency -replace 'Every (\d+) week\(s\)', '$1') * 10080
			} 
			"Monthly" {
				# Monthly logic is too complicated to deal with in this script. Or at least, I can't be bothered to do it at the moment.			
			} 
		}

		# Determine result based on return code
		Switch ($LastResult) { 
			0 { # - The operation completed successfully.
				$ResultStatus = "Good"
				$ShowStopper = $False
			}
			1 { # - Incorrect function called or unknown function called. 2 File not found.
				$ResultStatus = "Incorrect function / File not found"
				$ShowStopper = $True
			}
			10 { # - The environment is incorrect. 
				$ResultStatus = "Incorrect Environment"
				$ShowStopper = $True
			}
			259 { # - STILL_ACTIVE
				$ResultStatus = "Still Active"
				$ShowStopper = $False
			}
			267008 { # - Task is ready to run at its next scheduled time. 
				$ResultStatus = "Ready"
				$ShowStopper = $False
			}
			267009 { # - Task is currently running. 
				$ResultStatus = "Running"
				$ShowStopper = $False
			}
			267010 { # - The task will not run at the scheduled times because it has been disabled. 
				$ResultStatus = "Disabled"
				$ShowStopper = $True
			}
			267011 { # - Task has not yet run. 
				$ResultStatus = "Not yet run"
				$ShowStopper = $False
			}
			267012 { # - There are no more runs scheduled for this task. 
				$ResultStatus = "No more runs scheduled"
				$ShowStopper = $True
			}
			267013 { # - One or more of the properties that are needed to run this task on a schedule have not been set. 
				$ResultStatus = "Missing properties"
				$ShowStopper = $True
			}
			267014 { # - The last run of the task was terminated by the user. 
				$ResultStatus = "Terminated by user"
				$ShowStopper = $False
			}
			267015 { # - Either the task has no triggers or the existing triggers are disabled or not set. 
				$ResultStatus = "No triggers"
				$ShowStopper = $True
			}
			2147750671 { # - Credentials became corrupted. 
				$ResultStatus = "Credentials corrupt"
				$ShowStopper = $True
			}
			2147750687 { # - An instance of this task is already running. 
				$ResultStatus = "Already running"
				$ShowStopper = $False
			}
			-2147020576 { # - An instance of this task is already running. 
				$ResultStatus = "Already running"
				$ShowStopper = $False
			}
			2147943645 { # - The service is not available (is "Run only when an user is logged on" checked?). 
				$ResultStatus = "Service not available"
				$ShowStopper = $True
			}
			3221225786 { # - The application terminated as a result of a CTRL+C. 
				$ResultStatus = "Terminated via CTRL-C"
				$ShowStopper = $False
			}
			3228369022 { # - Unknown software exception.
				$ResultStatus = "Software exception"
				$ShowStopper = $True
			}
			default {
				$ResultStatus = "Unknown / Bad"
				$ShowStopper = $True
			}
		}

		# Determine whether the task ran within its specified interval
		If (($Frequency -ne $Null) -And ($Frequency -ne "")) {
			$DateNow = Get-Date
			If ($LastRun -lt $DateNow.AddMinutes(-$Frequency)) {
				#Didn't run within specified interval
				$RunStatus = "outside"
			}
			Else {
				$RunStatus = "within"
			}
		}

		# Powershell fudges the date. Force to UK format
		$LastRun_Text = $(Get-date $LastRun -format 'dd/MM/yyyy hh:mm:ss')

		If (($RunStatus -ne $Null) -And ($RunStatus -ne "")) {
			$Interval_Text = "($RunStatus specified interval)"
		}

		If ($ShowStopper -eq $True -or $RunStatus -eq "outside") {
			$OutString = "2:Last Run - $LastRun_Text $Interval_Text / Last Result - $LastResult (" + $ResultStatus + ")"
			Write-Host $OutString
			Exit 2
		}
		Else {
			$OutString = "0:Last Run - $LastRun_Text $Interval_Text Last Result - $LastResult (" + $ResultStatus + ")"
			Write-Host $OutString
			Exit 0
		}
	}
}

Invoke-Command @parameters

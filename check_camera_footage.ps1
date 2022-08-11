# +----------------------------------+------------------------------------------+
# |   ___    ____    _   _   _       | Title:   check_camera_footage.ps1        |
# |  / _ \  |  _ \  | | | | | |      | Author:  Matt Whalley                    |
# | | | | | | |_) | | |_| | | |      | Date:    09/11/2018                      |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.2                             |
# |  \__\_\ |_|     |_| |_| |_____|  |                                          |
# +----------------------------------+------------------------------------------+
# | DESCRIPTION:                                                                |
# | Script for use with Nagios.                                                 |
# | Checks that camera footage exists for the previous interval (if in-hours)   |
# | for the camera. Outputs return codes expected by Nagios                     |
# |                                                                             |
# | NOTE: This expects camera recordings to be 30 minutes long and started at   |
# | either on the hour or at the 30 minute mark. Anything else will need a      |
# | rewrite!                                                                    |
# |                                                                             | 
# | PARAMETERS:                                                                 |
# | CameraName  - Name of the Camera to check                                   |
# |                                                                             |
# | REVISIONS:                                                                  |
# | 09/11/2018 - Matt Whalley - Version 1.2                                     |
# | - Script will now look for files with names showing a time within 5         |
# |   minutes of the expected file name.                                        |
# |                                                                             |
# | 20/10/2018 - Matt Whalley - Version 1.1                                     |
# |  - Update script to get camera parameters from the scheduled task.          |
# |  - Script now takes into account the days upon which the scheduled task     |
# |    runs.                                                                    |
# |                                                                             |
# | 19/10/2018 - Matt Whalley - Version 1.0                                     |
# |  - Script Created.                                                          |
# |                                                                             |
# +-----------------------------------------------------------------------------+

Param
(
	[string]$HostName,
	[string]$CameraName
)

$parameters = @{
	ComputerName = "$Hostname"
	ScriptBlock = {	

$CameraName = $Using:CameraName


Function EscapeFile ($FileName)
{
	# Need to output double the backslashes as Nagios will remove one if not escaped.
	$FileEscape = $FileName.Replace("\", "\\")
	
	# We also need to escape Control Characters, otherwise sendmail will treat the body of the email as an attachment
	# 0 (null, NUL, \0, ^@), originally intended to be an ignored character, but now used by many programming languages including C to mark the end of a string.
	# 7 (bell, BEL, \a, ^G), which may cause the device to emit a warning such as a bell or beep sound or the screen flashing.
	# 8 (backspace, BS, \b, ^H), may overprint the previous character.
	# 9 (horizontal tab, HT, \t, ^I), moves the printing position right to the next tab stop.
	# 10 (line feed, LF, \n, ^J), moves the print head down one line, or to the left edge and down. Used as the end of line marker in most UNIX systems and variants.
	# 11 (vertical tab, VT, \v, ^K), vertical tabulation.
	# 12 (form feed, FF, \f, ^L), to cause a printer to eject paper to the top of the next page, or a video terminal to clear the screen.
	# 13 (carriage return, CR, \r, ^M), moves the printing position to the start of the line, allowing overprinting. Used as the end of line marker in Classic Mac OS, OS-9, FLEX (and variants). A CR+LF pair is used by CP/M-80 and its derivatives including DOS and Windows, and by Application Layer protocols such as FTP, SMTP, and HTTP.
	# 26 (Control-Z, SUB, EOF, ^Z). Acts as an end-of-file for the Windows text-mode file i/o.
	# 27 (escape, ESC, \e (GCC only), ^[). Introduces an escape sequence.
	
	$FileEscape = $FileEscape -Replace "\\([0,20,a,A,b,B,c,C,e,E,f,F,n,N,r,R,t,T,v,V])", '\\\$1'
	
	Return $FileEscape
	
}

# Set to true for debugging messages.
$Debug = $False

# Set this to true when installing new cameras, or the footage checks will have a fit and keep killing FFMPEG and the Scheduled Task
$NewCamera = $False

# $VerbosePreference="Continue" to display on screen, $VerbosePreference="SilentlyContinue" to hide.
$VerbosePreference = "SilentlyContinue"

# Drives to check for camera footage (amend if required) Can be an array
$Drives = "D"

# Segment size in minutes (change this to match the segment length of a recording).
# Note, this script expects to find recordings at the 1 hour or 30 minute mark, so might require refactoring slightly if this is changed!
# Note, the 20% 'fudge factor' to allow time for the file to actually be written out.
$SegmentSize = 30
$SegmentSize = ($SegmentSize * 1.20)

# Subfolder for the Scheduled Tasks
$TaskSubfolder = "Camera Recording\"

Try {

	# Get the Start Time from the Scheduled Task
	$RawStartTime = $(schtasks /query /FO LIST /V /TN "$TaskSubfolder$CameraName" | Select-String "Start Time:" | Out-String).trim()
		
	If ($RawStartTime -Like "*N/A*") {
		# If we didn't get the start time from the Start Time field in the schtasks output, try to get it from the next run time instead.
		$RawStartTime = $(schtasks /query /FO LIST /V /TN "$TaskSubfolder$CameraName" | Select-String "Next Run Time:" | Out-String).trim()
		$StartTime = $($RawStartTime.substring(14).trim()).substring(11).Trim()		
	} Else {
		$StartTime = $RawStartTime.substring(11).trim()
	}

	$CameraStart = $StartTime.substring(0,5)

	# Get the End Time from the Scheduled Task
	$RawEndTime = $(schtasks /query /FO LIST /V /TN "$TaskSubfolder$CameraName" | Select-String "Task To Run:" | Out-String).trim()
	$EndTime = $RawEndTime.substring(12).trim()
	
	# When run from the Nagios check, the returned $EndTime value comes back split up into separate lines.
	# Oddly, this doesn't happen when run directly from PowerShell! Fix this by removing these characters.
	$EndTime = $EndTime -replace "`t|`n|`r","" 
	
	$EndTime | where { $_ -match ".*-FinishTime (\d\d:\d\d)" } | Out-Null
	$CameraEnd = $matches[1]

	# Get the Schedule Type from the Scheduled Task
	$RawSchedule = $(schtasks /query /FO LIST /V /TN "$TaskSubfolder$CameraName" | Select-String "Schedule Type:" | Out-String).trim()
	$Schedule = $RawSchedule.substring(14).trim()

	# Get the Scheduled Task State from the Scheduled Task
	$RawTaskState = $(schtasks /query /FO LIST /V /TN "$TaskSubfolder$CameraName" | Select-String "Scheduled Task State:" | Out-String).trim()
	$TaskSchedule = $RawTaskState.substring(21).trim()

	If ($TaskSchedule -eq "Disabled")
	{
		Write-Host "WARNING: Scheduled Task for $CameraName is Disabled!$Info"
		Exit 1
	}

	If ($Schedule -eq "Weekly")
	{
		# Find the line containing the 'Days'.
		$RawDays = $(schtasks /query /FO LIST /V /TN "$TaskSubfolder$CameraName" | Select-String "Days:" | Out-String).trim()
		$Days = $RawDays.substring(5).trim() # This will be a string with days separated by commas - e.g. MON, TUE, WED, FRI
		
		If ($Days -eq "Every day of the week") {
			# Runs on ALL days. 
			$Days = "MON, TUE, WED, THU, FRI, SAT, SUN"
		}
	}
	Else
	{
		# Runs on ALL days. 
		$Days = "MON, TUE, WED, THU, FRI, SAT, SUN"
	}

	$Info = "\nCameraStart = $CameraStart\nCameraEnd = $CameraEnd\nSchedule = $Schedule\nDays = $Days"

	# Find which drive the camera is on
	Foreach ($Drive in $Drives)
	{
		$CameraPath = $Drive + ":\video\$CameraName"
		If (Test-Path $CameraPath) {
			Break
		} Else {
			$CameraPath = ""
		}
	}

	If ($CameraPath -eq "")
	{
		Write-Host "CRITICAL: Couldn't find recording path for $CameraName"
		Exit 2
	}

	# Get the Start Hours and Minutes
	$Pos = $CameraStart.IndexOf(":")
	$StartHours = [int]($CameraStart.Substring(0, $Pos))
	$StartMinutes = [int]($CameraStart.Substring($Pos + 1))

	# Get the End Hours and Minutes
	$Pos = $CameraEnd.IndexOf(":")
	$EndHours = [int]($CameraEnd.Substring(0, $Pos))
	$EndMinutes = [int]($CameraEnd.Substring($Pos + 1))

	# Get the current Date and Time
	$D = (Get-Date)

	$DayNow = $($($D.DayOfWeek.ToString()).Substring(0,3)).ToUpper()

	If ($Debug) {Write-Host "Days = $Days"}
	If ($Debug) {Write-Host "DayNow = $DayNow"}

	# If the task is meant to be running today
	If ($Days -like "*$DayNow*")
	{
		# Determine whether the current time is In Hours or not.
		If ($D.Hour -eq $StartHours) # If the current hour is the start hour
		{
			# ----- TODO If we were using intervals other than $SegmentSize mins, we would need to get the actual start minutes and add $SegmentSize (could take us to the next hour) ------
			If ($D.Minute -ge ($StartMinutes + $SegmentSize)) # Need to wait at least $SegmentSize minutes to actually get some footage!
			{
				# Current hour is the start hour and at least $SegmentSize minutes have elapsed
				If ($Debug) {Write-Host "Current hour is the start hour and at least $SegmentSize minutes have elapsed"}
				$InHours = $True
			}
			Else
			{
				# Current hour is the start hour, but $SegmentSize minutes have not yet elapsed
				If ($Debug) {Write-Host "Current hour is the start hour, but $SegmentSize minutes have not yet elapsed"}
				$InHours = $False
			}
		}
		Else
		{
			If ($D.Hour -gt $StartHours) # If the current hour is greater that the start hour
			{
				If ($D.Hour -eq $EndHours) # If the current hour is the end hour
				{
					If ($D.Minute -lt $EndMinutes) # If the current minute is less than the end minute
					{
						# Current hour is the end hour and current minutes haven't reached the end minute
						If ($Debug) {Write-Host "Current hour is the end hour and current minutes haven't reached the end minute"}
						$InHours = $True
					}
					Else
					{
						# Current hour is the end hour, and we are past the end minute
						If ($Debug) {Write-Host "Current hour is the end hour, and we are past the end minute"}
						$InHours = $False
					}
				}
				Else
				{
					If ($D.Hour -gt $EndHours)
					{
					
						If ($EndHours -lt $StartHours) {
							# End hour is before Start Hour. Assume 24 Hour recording (e.g. 06:00 - 05:59)
							If ($Debug) {Write-Host "Current hour is after the end hour, but end hour is before start hour, so we'll assume 24 hour recording"}			
							$InHours = $True
						} Else {					
							# Current hour is after the end hour
							If ($Debug) {Write-Host "Current hour is after the end hour"}			
							$InHours = $False					
						}
					}
					Else
					{
						# Current hour is after the start hour and not yet the end hour
						If ($Debug) {Write-Host "Current hour is after the start hour and not yet the end hour"}
						$InHours = $True
					}
				}
			}
			Else
			{
				# Current hour is before the start hour
				If ($Debug) {Write-Host "Current hour is before the start hour"}
				$InHours = $False
			}
		}
	}
	Else
	{
		# Task doesn't run today
		If ($Debug) {Write-Host "Task doesn't run today"}
		$InHours = $False
	}


	If ($InHours)
	{

		# See if we can get a handle on the current process for the camera.
		#$ExistingProc = Get-WmiObject Win32_Process -Filter "name='ffmpeg.exe' AND commandline LIKE '%@$($CameraName):%'"
		$ExistingProc = Get-WmiObject Win32_Process -Filter "name='ffmpeg.exe' AND commandline LIKE '%$CameraName%'"
		If ($ExistingProc -eq $NULL) 
		{
			# Whoops! The camera recording isn't running. Restart the Scheduled Task.
			# Start-ScheduledTask -TaskName "$TaskSubfolder\$CameraName" # Can't use - PowerShell V2 on this server.
			& schtasks /end /tn "$TaskSubfolder$CameraName" | Out-Null
			Start-Sleep -Seconds 10
			& schtasks /run /tn "$TaskSubfolder$CameraName" | Out-Null
			Write-Host "WARNING: FFMPEG Process for $CameraName not running. Attempted to start the Scheduled Task!$Info"
			Exit 1
		}

		If ($D.Minute -gt $SegmentSize)
		{
			# If it's more than $SegmentSize minutes past an hour, we should have some footage from the hour mark.
			$ExpectedTimeString = "$($D.Year)-$($D.Month.ToString("00"))-$($D.Day.ToString("00"))_$(($D.Hour).ToString("00"))00"
			
		}
		Else
		{
			# Otherwise, we should have some from the previous 30 minute mark.
			$ExpectedTimeString = "$($D.Year)-$($D.Month.ToString("00"))-$($D.Day.ToString("00"))_$(($D.Hour - 1).ToString("00"))30"
		}
			
		$FileName = $CameraPath + "\" + $ExpectedTimeString + ".mp4"
				
		Try {
				
			# Get the average file size (for 20 smallest files, ignoring files under 20MB) for a recording from this camera.
			# $TotalRecordingSize = ((Get-ChildItem -path $CameraPath -recurse | Where-Object {($_.Length / 1MB) -gt 20}| Where-Object {-Not $_.PSIsContainer } | Sort Length | Select -First 20 | Measure-Object -property length -sum).sum / 1MB)
			# $AverageRecordingSize = [int]($TotalRecordingSize / 20)
		
			########
			
			# Get an average of the recording size from the current time of day

			# Build the Time String for the current time 
			If ((Get-Date).Minute -lt 30) {
				$TimeString = "$((Get-Date).Hour)00"
			} Else  {
				$TimeString = "$((Get-Date).Hour)30"
			}

			# Get all of the items from this time of day for the last 2 weeks (to account for seasonal daylight changes etc.)
			# Maybe we should account for BST / GMT here as well? Bank Holidays?
			$ItemsFromCurrentTime = Get-ChildItem -path $CameraPath -recurse  | Where-Object { $_.FullName -match "\d{4}-\d{2}-\d{2}_$($TimeString).mp4" } | Sort Length | Select -First 14 

			# Get the total size of the recordings
			$TotalRecordingSize =  ($ItemsFromCurrentTime | Measure-Object -property length -sum).sum / 1MB

			$AverageRecordingSize = [int]($TotalRecordingSize / $ItemsFromCurrentTime.Count)
		
			
			########
	
			# Prepend to Info
			$Info = "\nAverage Smallest Recording Size = $($AverageRecordingSize)MB$Info"

			# Escape with \\
			$FileEscape = EscapeFile($FileName)
			
			# Attempt to get a handle on the expected file
			$File = Get-Item $FileName -ErrorAction Stop
					
			# Fudge factor of 65% used with Average Recording Size
			If ([int]($File.Length / 1MB) -gt ($AverageRecordingSize * 0.65)) {
				Write-Host "OK: $FileEscape found with length $([int]($file.Length / 1MB))MB$Info"
				Exit 0
			} Else {
				Write-Host "WARNING: $FileEscape found, but seems too small - $([int]($file.Length / 1MB))MB$Info"
				Exit 1
			}
		} Catch [System.Exception] {
			If ($_.Exception -like "*because it does not exist.*")
			{
				# Expected output file doesn't exist!
				$AccessResult = "not found"			
			}
			Else
			{
				# couldn't access file!
				$AccessResult = "could not be accessed ($($_.Exception))"		
			}
			
			# We couldn't access the _expected_ file name, so get the last written file in the folder
			$LastFile = Get-ChildItem $CameraPath | Sort LastWriteTime | Select -Last 2
			If ($LastFile[1].LastWriteTime -gt $D.AddMinutes(-$SegmentSize))
			{
					
				# Let's look at the last 2 files written.
				# If the recording is running, we'd expect one of these to be the file in progress and one to be the last written recording.
				# Sometimes, a recording can have a filename stamped with a value that is not the exact time we're looking for (e.g. a time of 0701 instead of 0700), so we're
				# going to look within a 5 minute range of the expected time stamp. If we have one, then we're going to take it as a success.
				
				# The expected time stamp in the filename we're looking for on a file
				$ExpectedTime = [datetime]::parseexact($ExpectedTimeString, 'yyyy-MM-dd_HHmm', $Null)
				
				ForEach ($LastFileProc in $LastFile)
				{
					# If it matches the expected time stamp format (e.g 2018-11-09_0701), it should be a completed file.
					If ($LastFileProc.Name -match "\d\d\d\d-\d\d-\d\d_\d\d\d\d.mp4")
					{
						# The actual time stamp in the filename we found
						$LastFileProcDateTime = [datetime]::parseexact($LastFileProc.BaseName, 'yyyy-MM-dd_HHmm', $Null)
						
						# Get the time difference
						$TimeDifference = $ExpectedTime - $LastFileProcDateTime
						# And then in Absolute minutes (ignore + -)
						$TimeDifferenceMins = [math]::abs($Result.TotalMinutes)
						
						If ($TimeDifferenceMins -lt 5)
						{
							# We found one within 5 minutes, this is probably OK.
							$FileEscape = $(EscapeFile($LastFileProc.Name))
							
							# We need to check the recording size though ...
							
							# Fudge factor of 65% used with Average Recording Size
							If ([int]($LastFileProc.Length / 1MB) -gt ($AverageRecordingSize * 0.65)) {
								Write-Host "0:OK"
								Exit 0
							} Else {
								Write-Host "1:WARNING"
								Exit 1
							}
							
						}						
					}
				}		

				$LastFileEscape = EscapeFile $LastFile.Name

				Write-Host "1:WARNING"
				Exit 1
							
			}
			Else
			{

				If (!($NewCamera)) {
			
					# Whoops! We can't find the most recent expected file, and no files have been written within the $SegmentSize minute segment time.
					# FFMPEG or the scheduled task may have gone screwy.
				
					# Start-ScheduledTask -TaskName "$TaskSubfolder\$CameraName" # Can't use - PowerShell V2 on this server.
					# Kill the scheduled task
					& schtasks /end /tn "$TaskSubfolder$CameraName" | Out-Null
					Start-Sleep -Seconds 10
					# Kill FFMPEG
					$ep = Get-Process -Id $existingproc.ProcessId
					$ep.Kill()
					Start-Sleep -Seconds 10
					# Start the Scheduled Task again.
					& schtasks /run /tn "$TaskSubfolder$CameraName" | Out-Null
					
					Write-Host "2:CRITICAL"
					Exit 2
				} Else {
					
					Write-Host "1:WARNING"
					Exit 1
					
				}
			}		
		}
	}
	Else
	{
		Write-Host "0:OK"
		Exit 0
	}
} Catch [System.Exception] {
	Write-Host "1:WARNING"
	Exit 1
}
	}
}
Invoke-Command @parameters
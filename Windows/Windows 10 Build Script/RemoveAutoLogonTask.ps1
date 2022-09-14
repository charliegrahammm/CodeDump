$ScheduledTaskName = "FireAndForgetWindowsUpdates"

		# Remove the auto-login settings for LocalUser
		Write-Host "Removing Auto-Login for LocalUser"
		$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
		Set-ItemProperty $RegPath "AutoAdminLogon" -Value "0" -type String 
		Set-ItemProperty $RegPath "DefaultUsername" -Value "" -type String 
		Set-ItemProperty $RegPath "DefaultPassword" -Value "" -type String
		
		# Remove the Scheduled Task
		Write-Host "Removing the scheduled task to re-run this script at the logon of LocalUser"
		$ScheduledTask = Get-ScheduledTask -TaskName $ScheduledTaskName -ErrorAction SilentlyContinue
		If ($ScheduledTask) {
			# Delete
			Unregister-ScheduledTask -TaskName $ScheduledTaskName -Confirm:$False -ErrorAction SilentlyContinue
		}
		
		# Remove stored credentials
		If (Test-Path "$($env:TEMP)\LocalUserCredentials.xml") {
			Remove-Item -Path "$($env:TEMP)\LocalUserCredentials.xml" -Force
		}
		
		Write-Host -ForegroundColor Green "AutoLogon and Scheduled Task Removed."
		Write-Host  "Installing BitDefender..."
		& "\\bandini\share\Setup\Bitdefender\setupdownloader_[aHR0cHM6Ly9ncmF2aXR5em9uZS5waGFybWF4by5sb2NhbDo4NDQzL1BhY2thZ2VzL0JTVFdJTi8wL2wzZ0YwWi9pbnN0YWxsZXIueG1sP2xhbmc9ZW4tVVM=].exe" /bdparams /silent | Out-Null
		
		# Display notification and Pause
		Write-Host -ForegroundColor Green "All done!"
		Write-Host "Computer will now be domain joined. BitDefender doesn't need to run its first scan - it'll do it once deployed."
		Start-Sleep -Seconds 60
		
		# Remove stored Domain Join credentials
		If (Test-Path "$($env:TEMP)\DomainJoinCredentials.xml") {
			Remove-Item -Path "$($env:TEMP)\DomainJoinCredentials.xml" -Force
		}
		
		# Remove stored computer name
		If (Test-Path "$($env:TEMP)\Build_Computername.txt") {
			Remove-Item -Path "$($env:TEMP)\Build_Computername.txt" -Force
		}
		
		Write-Host -ForegroundColor Red "Machine will need to be domain joined manually."
		Start-Sleep -Seconds 60
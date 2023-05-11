<#============================================================================================#
 | ██████╗ ██████╗ ██╗  ██╗██╗      |     .-.                                                 |
 |██╔═══██╗██╔══██╗██║  ██║██║      |    /   \         .-.                                    |
 |██║   ██║██████╔╝███████║██║      |   /     \       /   \       .-.     .-.     _   _       |
 |██║▄▄ ██║██╔═══╝ ██╔══██║██║      +--/-------\-----/-----\-----/---\---/---\---/-\-/-\/\/---|
 |╚██████╔╝██║     ██║  ██║███████╗ | /         \   /       \   /     '-'     '-'             |
 | ╚══▀▀═╝ ╚═╝     ╚═╝  ╚═╝╚══════╝ |/           '-'         '-'                              |      
 #============================================================================================#>            

<#
.SYNOPSIS
Check-PPMCatchupStatus - Checks PPM webservers to determine catch-up status of WebModulesHost.

.DESCRIPTION
This script is intended for Nagios.
Reads the C:\Logs\patient-management-web-modules.metrics.json file on all of the PPM WEB servers specified and gets the count value from the first instance of the timers key.
Compares this against the max value for each server to determine whether each server is caught up.

Relies on credential files being present for other servers to allow connection to their Log shares.

.PARAMETER Servers
Array of strings containing server names.

.OUTPUTS
Exit codes for Nagios - 
0 OK
1 WARNING
2 CRITICAL
3 UNKNOWN

.EXAMPLE
Check-PPMCatchupStatus -Servers "PPM-WEB-1","PPM-WEB-2","PPM-WEB-3"

.NOTES
Author:   Matt Whalley
Created:  26/07/2021
LastEdit: 15/10/2021

.LINK
https://qphlit.atlassian.net/wiki/spaces/QI/pages/197361717/PPM+Catch-up+Status+Nagios+Check
#>

Param (
	[Parameter(Mandatory=$True)][array]$Servers
)

Function Get-Readiness {
	<#
	.SYNOPSIS
	Get-Readiness - Gets the readiness state from the specified server.

	.DESCRIPTION
	Gets the count value from the first timers key in the patient-management-web-modules.metrics.json on the specified server.

	.PARAMETER Server
	The server from which to retrieve the readiness value.
	
	.PARAMETER LogPath
	The path of the log file, not including the server name.
	
	.OUTPUTS
	Array containing a boolean value indicating whether the operation was successful.
	It it was, then it also returns the readiness value.
	If not successful, boolean false.

	.EXAMPLE
	$Readiness = Get-Readiness -Server "PPM-WEB-2" -LogPath "\c$\Logs\patient-management-web-modules.metrics.json"

	.NOTES
	Author:   Matt Whalley
	LastEdit: 26/07/2021
	#>
	
	Param (
		[Parameter(Mandatory=$True)][string]$Server,
		[Parameter(Mandatory=$True)][string]$LogPath,
		[object]$Credential
	)

	$Readiness = $Null

	Try {
		$MetricsJSON = Get-Content -Path "\\$($Server)$($LogPath)"
		$Metrics = $MetricsJSON | ConvertFrom-Json
		
		$CountMetric = $Metrics.contexts.timers | Where {($_.name -eq "WebModule EventBus All Messages") -Or ($_.name -eq "WebModule EventBus All Events")}
		
		If ($CountMetric) {
			$Readiness = $CountMetric.count
		}

		If ($Readiness) {
			Return @{Readiness=$Readiness; Success=$True}
		} Else {
			Return @{Success=$False}
		}
		
	} Catch {
		Return @{Success=$False}
	}
}

Function Get-MaxReadiness {
	<#
	.SYNOPSIS
	Get-MaxReadiness - Gets the max readiness state from the specified server.

	.DESCRIPTION
	Reads the max readiness of the specified server from a file.

	.PARAMETER Server
	The server from which to retrieve the readiness value.
	
	.PARAMETER LogPath
	The path of the log file, not including the server name.
	
	.OUTPUTS
	Array containing a boolean value indicating whether the operation was successful.
	It it was, then it also returns the max readiness value.
	If not successful, boolean false.

	.EXAMPLE
	$Readiness = Get-MaxReadiness -Server "PPM-WEB-2" -LogPath "\c$\Logs" -CurrentReadiness $ThisServer.CurrentReadiness

	.NOTES
	Author:   Matt Whalley
	Created:  26/07/2021
	LastEdit: 14/10/2021
	#>
	
	Param (
		[Parameter(Mandatory=$True)][string]$Server,
		[Parameter(Mandatory=$True)][string]$LogPath,
		[Parameter(Mandatory=$True)][int]$CurrentReadiness,
		[object]$Credential
	)

	Try {
		$ServerReadinessFile = "\\$($env:computername)$($LogPath)\$($Server)-max-readiness.log"
		
		# If we have a max readiness file
		If (Test-Path -Path $ServerReadinessFile) {
			
			# Get the last max readiness from the file.
			$ServerMaxReadiness = Get-Content -Path $ServerReadinessFile
					
			If ($ServerMaxReadiness) {
				# If max server readiness read
				If ($CurrentReadiness -gt $ServerMaxReadiness) {
					# If the current readiness is greater than the maximum readiness, set the current readiness as the maximum readiness.
					Set-Content -Path $ServerReadinessFile -Value $CurrentReadiness

					Return @{MaxReadiness=$CurrentReadiness; Success=$True}
				} Else {
					# Otherwise return the max readiness from the file.
					Return @{MaxReadiness=$ServerMaxReadiness; Success=$True}
				}
				
			} Else {
				# We didn't get the max readiness successfully.
				Return @{Success=$False}
			}
			
		} Else {
			# No max readiness file found. Create one with current readiness.
			Set-Content -Path $ServerReadinessFile -Value $CurrentReadiness

			Return @{MaxReadiness=$CurrentReadiness; Success=$True}
		}
		
	} Catch {
		# Something went wrong.
		Return @{Success=$False}
	}
}

Function Get-ServerStatus {
	<#
	.SYNOPSIS
	Get-ServerStatus - Gets the current status of the specified server.

	.DESCRIPTION
	Gets the current readiness and whether the server is up to date.

	.PARAMETER Server
	The server to check.
	
	.PARAMETER Credential
	The credentials to use (if any)
	
	.OUTPUTS
	Array containing the current server readines, and whether it is up to date.
	
	.EXAMPLE
	$ServerStatus = Get-ServerStatus -Server "PPM-WEB-1"

	.NOTES
	Author:   Matt Whalley
	LastEdit: 26/07/2021
	#>
	
	Param (
		[Parameter(Mandatory=$True)][string]$Server,
		[object]$Credential
	)
	
	Try {
	
		$ValueWithin = 200 # 200 seems a 'safe' value based on some brief manual monitoring of the JSON.
		$LogPath = "\Logs"
		$PPMLogFileName = "patient-management-web-modules.metrics.json"
		$PPMLogFilePath = "$LogPath\$PPMLogFileName"
		
		# Get the current readiness of the server
			$ServerReadiness = Get-Readiness -Server $Server -LogPath $PPMLogFilePath
			If (!($ServerReadiness.Success)) {
				# Warning. Couldn't get readiness of this server.
				Write-Host "WARNING: Readiness could not be read from $Server."
				Exit 1
			}
		
		# Get the maximum readiness of the server.
			$ServerMaxReadiness = Get-MaxReadiness -Server $Server -LogPath $LogPath -CurrentReadiness $ServerReadiness.Readiness
			If (!($ServerMaxReadiness.Success)) {
				Write-Host "WARNING: Max readiness could not be read for $Server."
				Exit 1
			}
		
		# Determine whether the server is up to date.
			$ServerUpToDatePercentage = [math]::Round(($ServerReadiness.Readiness / $ServerMaxReadiness.MaxReadiness) * 100, 2)
			
			If ($ServerReadiness.Readiness -ge $ServerMaxReadiness.MaxReadiness) {
				# This server is up to date.
				$ServerUpToDate = $True
			} Else {
				If (($ServerMaxReadiness.MaxReadiness - $ServerReadiness.Readiness) -le $ValueWithin) {
					# This server is mostly caught up with its maximum. Let's assume it's ready.
					$ServerUpToDate = $True
				} Else {
					$ServerUpToDate = $False
				}
			}
			
		Return @{Readiness=$ServerReadiness.Readiness; MaxReadiness = $ServerMaxReadiness.MaxReadiness; UpToDate=$ServerUpToDate; UpToDatePercentage = $ServerUpToDatePercentage}
	
	} Catch {
		Write-Host "WARNING: Could not get status of $ThisServer."
		Exit 1
	}
}

<# ---------------------------------------------------------- Start of Main Script Body ---------------------------------------------------------- #>
Try {

	# Get Script Path
	$ScriptPath = $(Split-Path $MyInvocation.MyCommand.Path -Parent)

	$LogPath = "\Logs"
	$PPMLogFileName = "patient-management-web-modules.metrics.json"
	$PPMLogFilePath = "$LogPath\$PPMLogFileName"
	
	# Get name of credential file. These are the server initials followed by .service.xml e.g. PPM-WEB-1 --> pw1.service.xml
	$ThisServer = $($env:computername)
	$Inits = $ThisServer | Select-String -Pattern "(.).*-(.).*-(\d*)"
	ForEach ($Match In $Inits.Matches.Groups){
		If ($Match.Value -ne $ThisServer) {
			$ServerInits += [string]$Match.Value
		}
	}
	$ServerInits = $ServerInits.ToLower()
	$ServerCredFileName = "$ScriptPath\Credentials\$ServerInits.service.xml"
	$Credential = Import-CliXml $ServerCredFileName
	
	# Initialise hashtable for statuses
	$ServerStatuses = @{}

	# Get the statuses for each server
	ForEach ($Server In $Servers) {
		# Reset mapped variable
		$Mapped = $Null

		# We only want to map drives for remote servers
		If ($Server -ne $ThisServer) {
			# Rebuild credential as we must pass the username in the format COMPUTERNAME\Username (stored in credfile without COMPUTERNAME so that it can be re-used between machines).
			$UserName = "$Server\$($Credential.GetNetworkCredential().Username)"
			$UserPassword = $Credential.GetNetworkCredential().Password
			$SecStringPassword = ConvertTo-SecureString $UserPassword -AsPlainText -Force
			$CredObject = New-Object System.Management.Automation.PSCredential ($UserName, $SecStringPassword)
			
			# Map Logs share from remote server (we need to do this so that we can use the credential).
			$Mapped = New-PSDrive -Name "$Server Logs" -PSProvider "FileSystem" -Root "\\$Server\Logs" -Credential $CredObject
		}

		# Add to ServerStatus hashtable
		$ServerStatuses += @{$Server = Get-ServerStatus -Server $Server}
		
		If ($Mapped) {
			Remove-PSDrive $Mapped.Name -Force -ErrorAction SilentlyContinue
		}
	}
	
	# Loop through statuses and generate output for Nagios
	ForEach ($Key in $ServerStatuses.Keys) {
		$ServerStatus = $ServerStatuses[$Key]
		If ($ServerStatus.UpToDate) {$UpToDateCount += 1}
		If ($ServerStatusString) {$ServerStatusString += " / "}
		$ServerStatusString += "$Key $($ServerStatus.UpToDatePercentage)% ($($ServerStatus.Readiness)/$($ServerStatus.MaxReadiness))"
	}
	
	$StatusString = "$($UpToDateCount) of $($ServerStatuses.Keys.Count) servers are up to date. $ServerStatusString"
	
	# If all up to date
	If ($UpToDateCount -eq $ServerStatuses.Keys.Count) {
		Write-Host "OK: $StatusString"
		Exit 0
	}
	
	# If none up to date
	If ($UpToDateCount -eq 0) {
		Write-Host "CRITICAL: $StatusString"
		Exit 2
	}

	# If some but not all up to date
	If ($UpToDateCount -lt $ServerStatuses.Keys.Count) {
		Write-Host "WARNING: $StatusString"
		Exit 1
	}

} Catch {
	Write-Host "WARNING: Error in checking script: $($_.Exception.Message) at line $($_.InvocationInfo.ScriptLineNumber)."
	Exit 1
	
} Finally {
	# Clean up mapped logs drives
	ForEach ($Server In $Servers) {
		$Mapped = Get-PSDrive -Name "$Server Logs" -ErrorAction SilentlyContinue
		If ($Mapped) {
			Remove-PSDrive -Name $Mapped.Name -Force -ErrorAction SilentlyContinue
		}
	}
}
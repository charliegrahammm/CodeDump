# Set local parameters to be passed from PRTG sensor
Param (
	[string]$HostName
)	

# Create parameter to be used by Invoke-Command containing script block and target hostname
$parameters = @{
	ComputerName = "$HostName"
	ScriptBlock = { 

Try {

	# Initial Values
	$Unhealthy = $False
	$Output = ""
	
	# \Application Request Routing Server(Order Manager API Server Farm\172.16.1.37)\Health
	$Match = "\\.*\((.*\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})\)\\Health"

	$CounterSets = Get-Counter -ListSet "Application Request Routing Server"
	$CounterPaths = $CounterSets.PathsWithInstances

	ForEach ($CounterPath In $CounterPaths) {
		If ($CounterPath -Like "*\Health") {
			If ($CounterPath -NotLike "*(_Total)\Health") {
				If($CounterPath -Match $Match) {
					$CounterDetails = $($Matches[1]).Split("\")
					$CounterName = $($CounterDetails[0]).Replace(" Server Farm", "")
					$CounterServer = $CounterDetails[1]
					$CounterInfo = "$CounterName / $CounterServer"
				} Else {
					$CounterInfo = $CounterPath
				}
				
				$Counter = Get-Counter -Counter $CounterPath
				If ($Counter.CounterSamples.CookedValue -eq 1) {
					$Output += "`n$CounterInfo = Healthy"
				} Else {
					$Output += "`n$CounterInfo = Unhealthy"
					$Unhealthy = $True
				}
			}
		}	
	}

	# Calculating Exit code
	If ($Unhealthy) {
		Write-Host "CRITICAL! One or more unhealthy instances.`n$Output :CRITICAL"
		Exit 2
	} Else {
		Write-Host "OK. No unhealthy instances.`n$Output :OK"
		Exit 0
	}

} Catch {
	Write-Host "WARNING: Failure in checking script!\n$($_.Exception)) at line $($_.InvocationInfo.ScriptLineNumber) :WARNING"
	Exit 1
}}}
	
# Run the command on the specified target
Invoke-Command @parameters
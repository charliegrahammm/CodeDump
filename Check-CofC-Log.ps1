# Set local parameters to be passed from PRTG sensor
Param (
	[string]$HostName
)	

# Create parameter to be used by Invoke-Command containing script block and target hostname
$parameters = @{
	ComputerName = "$HostName"
	ScriptBlock = {
	
$nlines = 50

try {
    $lines = (&'C:\Program Files\NSClient++\scripts\tail.exe' -$($nlines) 'C:\Program Files (x86)\efeedback Research Ltd\CofC Generator\logs\log.txt')
    $exs = ($lines | Select-String "Subscription dropped|CatchUpError").Count

	$GoodLine = $($lines | Select -Last 1) -match "\d{8}|Generated C:\\CofCs\\.*.pdf"
	
	If ($GoodLine -ne $True)
	{
		If ($exs -gt 0)
		{
			Write-Host "WARNING: Exception logged recently"
			Exit 1
		} 
		Else 
		{
			Write-Host "OK: No exceptions in the last $nlines lines"
			Exit 0
		}
	}
	Else
	{
		Write-Host "OK: Last line of file shows a successful transaction"
		Exit 0
	}
	
} catch [System.Exception] {
    Write-Host "UNKNOWN: Error checking the log file"
    Exit 3
}}}

# Run the command on the specified target
Invoke-Command @parameters

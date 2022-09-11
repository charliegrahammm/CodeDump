$progressBar = '|','/','-','\' 
$jobName = Start-Job -ScriptBlock { GUI CMD here }
while($jobName.JobStateInfo.State -eq "Running") {
    Write-Host "$_`b"
    Start-Sleep -Milliseconds 125
}
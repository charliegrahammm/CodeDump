# Wait
[int]$Time = 5
$Length = $Time / 100
For ($Time; $Time -gt 0; $Time--) {
$min = [int](([string]($Time/60)).split('.')[0])
$text = " " + $min + " minutes " + ($Time % 60) + " seconds left"
Write-Progress -Activity "Watiting..." -Status $Text -PercentComplete ($Time / $Length)
Start-Sleep 1
}
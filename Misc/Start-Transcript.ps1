# Start Transcript
$TranscriptFilename = "C:\Logs\TranscriptName - $(get-date -f "yyyy-MM-dd HH.mm.ss").txt"
Start-Transcript -Path $TranscriptFilename

# Stop Transcript
Stop-Transcript | Out-Null
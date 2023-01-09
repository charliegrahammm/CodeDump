# Copy File from GitHub
Write-Host "Downloading file from GitHub..."

$DownloadedFile = "C:\Temp\CopyFromGitHub.ps1"

Invoke-WebRequest -Uri https://raw.githubusercontent.com/charliegrahammm/CodeDump/main/Misc/CopyFromGitHub.ps1 -OutFile $DownloadedFile

if (Test-Path -Path $DownloadedFile -PathType Leaf) {
    Write-Host "Successfully Downloaded" -ForegroundColor Green
} 
else {
    Write-Host "Download Failed" -ForegroundColor Red
    pause
}
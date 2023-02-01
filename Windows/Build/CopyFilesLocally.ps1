# Remove old files
$Folder = "C:\Temp\Build"

Write-Host "Clearing old files..."
if (Test-Path -Path $Folder) {
    Remove-Item $Folder -Recurse
    Write-Host "Done" -ForegroundColor Green
} 
else {
    Write-Host "Nothing to clean up" -ForegroundColor Green
}

# Create C:\Temp directory
New-Item -Type Directory "C:\Temp" -Force

# Change directory to scripts folder on USB
$ScriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path $ScriptPath
Set-Location $dir

# Copy all relevant files
# Copy-Item -Path ".\Updates\" -Destination "C:\Temp\Build\Updates" -Recurse -Force
Copy-Item -Path $dir -Destination "C:\Temp\Build\" -Recurse -Force


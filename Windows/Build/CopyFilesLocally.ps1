# Remove old files
Remove-Item 'C:\Temp' -Recurse

# Create C:\Temp directory
New-Item -Type Directory "C:\Temp" -Force

# Change directory to scripts folder on USB
$ScriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path $ScriptPath
Set-Location $dir

# Copy all relevant files
# Copy-Item -Path ".\Updates\" -Destination "C:\Temp\Build\Updates" -Recurse -Force
Copy-Item -Path $dir -Destination "C:\Temp\Build\" -Recurse -Force


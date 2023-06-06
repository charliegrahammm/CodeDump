# Create C:\Temp directory
New-Item -Type Directory "C:\Temp" -Force

# Change directory to scripts folder on USB
$ScriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path $ScriptPath
Set-Location $dir

# Copy all relevant files
Copy-Item -Path ".\Components\" -Destination "C:\Temp\Components\" -Recurse -Force
Copy-Item -Path "AutoPilot_AutoRegister.ps1" -Destination "C:\Temp\" -Recurse -Force




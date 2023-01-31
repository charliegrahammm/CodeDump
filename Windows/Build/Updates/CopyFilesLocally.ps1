# Create C:\Temp directory
New-Item -Type Directory "C:\Temp" -Force

# Change directory to scripts folder on USB
$ScriptPath = $MyInvocation.MyCommand.Path
$dir = Split-Path $ScriptPath
Set-Location $dir

# Copy all relevant files
Copy-Item -Path ".\Lenovo\" -Destination "C:\Temp\Lenovo\" -Recurse -Force
Copy-Item -Path ".\Windows Update\" -Destination "C:\Temp\Windows Update\" -Recurse -Force
Copy-Item -Path "RunUpdates_auto.ps1" -Destination "C:\Temp\" -Recurse -Force
Copy-Item -Path "RunUpdates_auto.bat" -Destination "C:\Temp\" -Recurse -Force
Copy-Item -Path "RunUpdates_Decrapify_auto.ps1" -Destination "C:\Temp\" -Recurse -Force
Copy-Item -Path "RunUpdates_Decrapify_auto.bat" -Destination "C:\Temp\" -Recurse -Force




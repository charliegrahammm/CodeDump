# Copy files if not already if not already
if (Get-ChildItem -Path "C:\Temp\Windows Update\FireAndForget") {
    Write-Host "Files already exist" -ForegroundColor Green
    break
} 
else {
    # Create C:\Temp directory
    New-Item -Type Directory "C:\Temp"

    # Change directory to scripts folder on USB
    Set-Location "D:\Scripts\Windows\Updates\"

    # Copy all relevant files
    Copy-Item -Path ".\Lenovo\" -Destination "C:\Temp\Lenovo\" -Recurse -Force
    Copy-Item -Path ".\Windows Update\" -Destination "C:\Temp\Windows Update\" -Recurse -Force
    Copy-Item -Path "RunUpdates_auto.ps1" -Destination "C:\Temp\" -Recurse -Force
    Copy-Item -Path "RunUpdates_auto.bat" -Destination "C:\Temp\" -Recurse -Force
}




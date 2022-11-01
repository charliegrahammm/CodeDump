: Copy all files from "Updates" to the desktop.

@ECHO OFF

cd  %USERPROFILE%\Desktop

ECHO Copying Files...
xcopy /i /y /e ".\Lenovo" "C:\Temp\Lenovo" 
xcopy /i /y /e ".\Windows Update" "C:\Temp\Windows Update"
xcopy /i /y "RunUpdates_auto.ps1" "C:\Temp\"

ECHO Gathering credentials...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\Windows Update\FireAndForget\GatherCredentials.ps1"

ECHO Running updates...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\RunUpdates_auto.ps1"


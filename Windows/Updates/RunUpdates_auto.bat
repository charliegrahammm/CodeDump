@ECHO OFF

ECHO Copying Files...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Scripts\Windows\Updates\CopyFilesLocally.ps1"

ECHO Gathering credentials...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\Windows Update\FireAndForget\GatherCredentials.ps1"

ECHO Running updates...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\RunUpdates_auto.ps1"


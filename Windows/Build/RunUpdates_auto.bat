@ECHO OFF

pushd %~dp0

ECHO Forcing Time Sync...
net stop w32time
w32tm /unregister
w32tm /register
net start w32time
w32tm /resync

ECHO Copying Files...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "CopyFilesLocally.ps1"

ECHO Gathering credentials...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\Build\Updates\Windows Update\FireAndForget\GatherCredentials.ps1"

ECHO Running WinGet updates...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\Build\Updates\WinGet_Update.ps1"

:: ECHO Running Nvidia Updates...
:: PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\Build\Updates\Nvidia-Update.ps1"

ECHO Running System and Windows updates...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Temp\Build\Build Scripts\RunUpdates_auto.ps1"


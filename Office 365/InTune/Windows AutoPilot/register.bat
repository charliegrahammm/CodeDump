@ECHO OFF

pushd %~dp0

ECHO Copying Files...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "CopyFilesLocally.ps1"

ECHO Registering in InTune...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "AutoPilot_AutoRegister.ps1"

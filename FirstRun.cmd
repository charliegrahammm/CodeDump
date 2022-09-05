@ECHO OFF
CLS
ECHO -----------------------------------------------------------------------------------------------------------------
ECHO Fire And Forget Windows Updates will now be performed.
ECHO -----------------------------------------------------------------------------------------------------------------

PowerShell -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Win-10-FireAndForgetWindowsUpdates_BD_Version\InstallPSWindowsUpdate.ps1"
PowerShell -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Win-10-FireAndForgetWindowsUpdates_BD_Version\FireAndForgetWindowsUpdates.ps1"
Timeout 5
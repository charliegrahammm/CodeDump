:: +----------------------------------------+---------------------------------------- +
:: | ___       _   _        _   ___ _   _   | Title:  BuildStandardWin10Office2016.cmd| 
:: || _ ) __ _| |_| |_     /_\ / __| | | |  | Author: Matt Whalley & Charlie Graham   |
:: || _ \/ _` |  _| ' \   / _ \\__ \ |_| |  | Date:   08/08/2017	                  |
:: ||___/\__,_|\__|_||_| /_/ \_\___/\___/   | Version: 1.0.4                          |
:: +----------------------------------------+-----------------------------------------+
:: | Description:                                                                     |
:: | Installs the standard software on a new machine. Activates Windows /             |
:: | Registers for Windows Updates                                                    |
:: |                                                                                  |
:: |  28/05/2021 - Charlie Graham - Version 1.0.4                                     |
:: |  - Added Adobe Reader installation, removed Foxit Reader                         |                                                                             
:: |                                                                                  |
:: |  29/05/2019 - Charlie Graham - Version 1.0.3                                     |
:: |  - Added Foxit Reader installation to solve updating issues                      |                                                                                
:: |                                                                                  |
:: | 25/01/2019 - Matt Whalley - Version 1.0.2                                        |
:: |  - Changed storage location of installers to Bandini so that localuser can       |
:: |    access it.                                                                    |
:: |                                                                                  |
:: | 06/07/2018 - Charlie Graham - Version 1.0.1                                      |
:: |  - Script Updated for Office 2016 & InfoPath 2013                                |
:: |                                                                                  |
:: | 08/08/2017 - Matt Whalley - Version 1.0                                          |
:: |  - Script Created                                                                |
:: +----------------------------------------------------------------------------------+

@ECHO OFF

:: ECHO Getting LocalUser Credentials...
:: PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Win-10-FireAndForgetWindowsUpdates_BD_Version\GetLocalUserCredentials.ps1"

ECHO Getting Encrypted Credentials...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\GetEncryptedCredentials\GetEncryptedCredentials.ps1"

ECHO Getting Computer Name for Domain Join...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\DomainJoin\GetComputerName.ps1"

ECHO Setting TimeZone...
:: This is necessary as some images have the wrong time zone .. oops
tzutil.exe /s "GMT Standard Time"

ECHO Activating Windows...
:: Install Key
CSCRIPT \windows\system32\slmgr.vbs /ipk JRPXH-KDN2J-9FVVD-2W3F3-WQKR4
:: Activate
CSCRIPT \windows\system32\slmgr.vbs /ato

ECHO Installing .NET Framework 3.5...
DISM /Online /NoRestart /Enable-Feature /FeatureName:NetFx3 /All

ECHO Installing Lenovo USB-C Dock Ethernet Driver
"\\bandini\share\Setup\Build Scripts\Lenovo USB-C Ethernet Driver\thinkpad_thunderbolt-3_dock_and_usb-c_dock_driver_v10017.exe" /verysilent /norestart

ECHO Running De-crapifier...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Win10-Initial-Setup-Script\Win10.ps1" -include "\\bandini\share\Setup\Build Scripts\Win10-Initial-Setup-Script\Win10.psm1" -preset "\\bandini\share\Setup\Build Scripts\Win10-Initial-Setup-Script\Default.preset"

ECHO Removing Provisioned Packages...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Win10-Remove-Provisioned-Packages\RemoveProvisionedPackages.ps1"

ECHO Disabling Xbox Services...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Win-10-Disable-Xbox-Services\Disable-Xbox-Services.ps1"

ECHO Setting Permissions for Ivanti Agent...
icacls "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys" /grant SYSTEM:F /T
icacls "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys" /grant PHARMAXO\builder:F /T
icacls "C:\ProgramData\Microsoft\Crypto\RSA\MachineKeys" /grant localuser:F /T

ECHO Running OneDrive Killer...
CMD /C "\\bandini\share\Setup\Build Scripts\Win-10-OneDrive-Killer\DeleteOneDrivePermanently.cmd"

ECHO Installing Microsoft Office 2016...
"\\bandini\share\Setup\Office2016\setup.exe" /configure ""\\bandini\share\Setup\Office2016\config.xml"

ECHO Installing Microsoft InfoPath 2013...
pushd "\\bandini\share\Setup\InfoPath2013\"
setup.exe /config "\\bandini\share\Setup\InfoPath2013\infopathr.ww\config.xml"
popd

ECHO Installing Microsoft Teams...
msiexec.exe /i "\\bandini\share\Setup\Teams\Teams_windows_x64.msi" ALLUSERS=1 /qn /norestart

ECHO Installing TeamViewer Host...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\Install-TeamViewer-QPHL-Host\Install-TeamViewer-QPHL-Host.ps1"

ECHO Installing Adobe Reader...
%SYSTEMROOT%\System32\taskkill.exe /f /im AcroRd32.exe
"\\bandini\share\Setup\Adobe Acrobat\Reader\DC\Continuous\AcroRdrDC1500720033_MUI.exe" /sAll /rs /msi EULA_ACCEPT=YES AgreeToLicense=Yes RebootYesNo=No
del "%PUBLIC%\Desktop\Acrobat Reader DC.lnk" /F
REG ADD "HKLM\SOFTWARE\Adobe\Adobe ARM\1.0\ARM" /v iCheckReader /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" /v bUpdater /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" /v bAcroSuppressUpsell /t REG_DWORD /d 1 /f
REG ADD "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" /v bUpdater /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Wow6432Node\Adobe\Adobe ARM\1.0\ARM" /v iCheckReader /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" /v bUpdater /t REG_DWORD /d 0 /f
REG ADD "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown" /v bAcroSuppressUpsell /t REG_DWORD /d 1 /f
REG ADD "HKLM\SOFTWARE\Policies\Adobe\Acrobat Reader\DC\FeatureLockDown\cServices" /v bUpdater /t REG_DWORD /d 0 /f
msiexec.exe /p "\\bandini\share\Setup\Adobe Acrobat\Reader\DC\Continuous\AcroRdrDCUpd2100120155_MUI.msp" /qn /norestart /log output.log
REG ADD "HKLM\SOFTWARE\Adobe\Acrobat Reader\DC\Installer" /v ENABLE_CHROMEEXT /t REG_SZ /d 0 /f
REG ADD "HKLM\SOFTWARE\WOW6432Node\Adobe\Acrobat Reader\DC\Installer" /v ENABLE_CHROMEEXT /t REG_SZ /d 0 /f

ECHO Disable Nvidia Control Panel...
PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File "\\bandini\share\Setup\Build Scripts\DisableNvidiaControlPanel.ps1"

:: ECHO Installing Foxit Reader...
:: msiexec.exe /i "\\bandini\share\setup\Foxit Reader\9.5\FoxitReader_9.5.0.20723_enu_Setup.msi" ALLUSERS=1 /qn /norestart /log output.log TRANSFORMS=FoxitReader1.0.mst

ECHO Installing Google Chrome...
msiexec.exe /i "\\bandini\share\Setup\Google Chrome\GoogleChromeStandaloneEnterprise64.msi"

ECHO Registering for Microsoft Update...
CSCRIPT "\\bandini\share\setup\RegisterMicrosoftUpdate.vbs"

:: ECHO Installing Bitdefender...
:: "\\bandini\share\Setup\Bitdefender\setupdownloader_[aHR0cHM6Ly9ncmF2aXR5em9uZS5waGFybWF4by5sb2NhbDo4NDQzL1BhY2thZ2VzL0JTVFdJTi8wL2wzZ0YwWi9pbnN0YWxsZXIueG1sP2xhbmc9ZW4tVVM=].exe" /bdparams /silent

:: Initiate the Fire And Forget Windows Updates Script
ECHO Starting Fire and Forget Windows Updates
CMD /C "\\bandini\share\Setup\Build Scripts\Win-10-FireAndForgetWindowsUpdates_BD_Version\FirstRun.cmd"

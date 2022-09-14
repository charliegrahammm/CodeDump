# +----------------------------------+------------------------------------------------+
# |   ___    ____    _   _   _       | Title:   Get-ComputerInfo.ps1                  |
# |  / _ \  |  _ \  | | | | | |      | Author:  Matt Whalley                          |
# | | | | | | |_) | | |_| | | |      | Date:    04/08/2020                            |
# | | |_| | |  __/  |  _  | | |___   | Version: 1.0                                   |
# |  \__\_\ |_|     |_| |_| |_____|  |                                                |
# +----------------------------------+------------------------------------------------+
# | DESCRIPTION:                                                                      |
# | Collects information about the current computer and displays it on screen.        |
# | If a user selects an item and clicks OK, it will be copied to their clipboard.    |
# |                                                                                   |
# | REVISIONS:                                                                        |
# | 04/08/2020 - Matt Whalley - Version 1.0                                           |
# |  - Script Created.                                                                |
# |                                                                                   |
# +-----------------------------------------------------------------------------------+

# .Net methods for hiding/showing the console in the background
	Add-Type -Name Window -Namespace Console -MemberDefinition '
	[DllImport("Kernel32.dll")]
	public static extern IntPtr GetConsoleWindow();

	[DllImport("user32.dll")]
	public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
	'

	Function Show-Console
	{
		$consolePtr = [Console.Window]::GetConsoleWindow()

		# Hide = 0,
		# ShowNormal = 1,
		# ShowMinimized = 2,
		# ShowMaximized = 3,
		# Maximize = 3,
		# ShowNormalNoActivate = 4,
		# Show = 5,
		# Minimize = 6,
		# ShowMinNoActivate = 7,
		# ShowNoActivate = 8,
		# Restore = 9,
		# ShowDefault = 10,
		# ForceMinimized = 11

		[Console.Window]::ShowWindow($consolePtr, 1)
	}

	Function Hide-Console
	{
		$consolePtr = [Console.Window]::GetConsoleWindow()
		#0 hide
		[Console.Window]::ShowWindow($consolePtr, 0)
	}


Hide-Console

# Get the QPHL VPN IP Address
	$QPHLVPNProfile = Get-VPNconnection -name "QPHL VPN" -AllUserConnection -ErrorAction SilentlyContinue

	If ($QPHLVPNProfile) {

		Try {
			$QPHLVPN = Get-NetIPAddress -InterfaceAlias "QPHL VPN" -ErrorAction Stop
			
			If ($QPHLVPN) {
				If ($QPHLVPN.IPAddress) {
					$QPHLVPNIP = $QPHLVPN.IPAddress
				} Else {
					$QPHLVPNIP = "Not available. Is VPN connected?"
				}
			} Else {
				$QPHLVPNIP = "Not available. Is VPN connected?"
			}
			
		} Catch {

			$QPHLVPNIP = "Not found. Is VPN configured?"

		}
		
	} Else {

		$QPHLVPNIP = "Profile not found!"

	}

# Get Public IP Address
	Try {
		$PublicIPInfo = Invoke-RestMethod http://ipinfo.io/json -ErrorAction Stop
		$PublicIP = $PublicIPInfo.ip
		
	} Catch {
		$PublicIP = "Unknown"
	}

# Get other system details
	$SystemInfo = Get-CimInstance Win32_OperatingSystem | Select *

# Get uptime in readable format
	$Uptime = (Get-Date) - $SystemInfo.LastBootUpTime
	$UptimeDisplay =  "$($Uptime.Days) days, $($Uptime.Hours) hours, $($Uptime.Minutes) minutes" 

# Generate the fields to output
	$Output =[ordered]@{

		"01. Computer Name" = $SystemInfo.CSName
		"02. Current User" = $env:UserName
		"03. Windows Edition" = $SystemInfo.Caption
		"04. Windows Version" = $SystemInfo.Version
		"05. Windows Release ID" = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").ReleaseId
		"06. Windows Install Date" = $SystemInfo.InstallDate
		"07. OS Architecture" = $SystemInfo.OSArchitecture
		"08. System Status" = $SystemInfo.Status
		"09. Local Date / Time" = $SystemInfo.LocalDateTime
		"10. Last Boot Time" = $SystemInfo.LastBootUpTime
		"11. System Uptime" = $UptimeDisplay
		"12. QPHL VPN IP" = $QPHLVPNIP
		"13. Public IP" = $PublicIP
		
	}

# Get other network connection info and add to output
	$OtherIPInfo = Get-NetIPConfiguration | Where {$_.InterfaceAlias -ne "QPHL VPN"}

	ForEach ($OtherIP in $OtherIPInfo) {
		$Output += @{"$($Output.Count + 1). $($OtherIP.InterfaceAlias) IP" = $OtherIP.IPv4Address.IPAddress}	
	}

# Display the info in a window, setting mode to single.
	$Result = $Output | Out-GridView -Title "Computer Information for $($SystemInfo.CSName) / (Click on an item and then click OK to copy it to the clipboard)" -OutputMode Single

# If the result contains data (i.e. the user selected an item and clicked 'OK'), then copy to the clipboard.
	If ($Result) {Set-Clipboard "$($($Result.Name).Substring(4)): $($Result.Value)"}
	
# We could probably get some more info and add it to the output. E.g. disk health
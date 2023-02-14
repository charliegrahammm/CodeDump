<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script pulls vm storage locations from each defined host and exports the data to a csv.
.DESCRIPTION  
    Pulls the host, computername and configuration location for each VM on the specified host and exports to csv.
.NOTES  
    File Name  : ExportHyperVVMStorage.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Host-
Get-VM -ComputerName vm-host-1 | Select-Object -Property Name, ComputerName, ConfigurationLocation | Export-Csv C:\export\vm-host-1.csv

# Host-2
Get-VM -ComputerName vm-host-2 | Select-Object -Property Name, ComputerName, ConfigurationLocation | Export-Csv C:\export\vm-host-2.csv

# Host-3
Get-VM -ComputerName vm-host-3 | Select-Object -Property Name, ComputerName, ConfigurationLocation | Export-Csv C:\export\vm-host-3.csv

# Host-4
Get-VM -ComputerName vm-host-4 | Select-Object -Property Name, ComputerName, ConfigurationLocation | Export-Csv C:\export\vm-host-4.csv

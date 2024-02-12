<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script extracts a list of users with direct reports from the "Corsham > Users > Left" OU to a csv in C:\Temp.
.DESCRIPTION  
    This script will give you a list of users who have been disabled, but their direct reports havent had their managers updated. This list should be sent to HR to get them to confirm the replacement manager.
.NOTES  
    File Name  : ExtractInactiveUsersWithDirectReports.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

$TargetUsers = Get-ADUser -Filter * -SearchBase “OU=Left,OU=Users,OU=Corsham,DC=pharmaxo,DC=local” | Select-Object -ExpandProperty SamAccountName
#$TargetUser = 'charlie.graham'
$ExportCSV = 'C:\Temp\InactiveUsersWithDirectReports.csv'

# Install ActiveDirectory Module if it doesnt already exist
Import-Module ActiveDirectory

# Make C:\Temp directory
Write-Host "Creating C:\Temp directory..."
New-Item -Path "C:\" -Name "Temp" -ItemType "Directory" -Force


$Properties = @(
    'Name'
    'SamAccountName'
    'Description'
    'Office'
    'telephoneNumber'
    'EmailAddress'
    'DirectReports'
)

$ADUser = foreach ( $TargetUser in $TargetUsers ) {
    Get-ADUser -Identity "$TargetUser" -Properties $Properties
}

$Results = foreach ( $Report in $ADUser.DirectReports ) {
    $PropHash = [ordered]@{}

    foreach ( $Prop in ( $Properties | Where-Object { $_ -ne 'DirectReports' } ) ) {
        $PropHash.Add( $Prop, $ADUser.$Prop )
    }

    $PropHash.Add( 'DirectReport', $Report )

    [pscustomobject]$PropHash
}

$Results |
Export-Csv -Path $ExportCSV -NoTypeInformation
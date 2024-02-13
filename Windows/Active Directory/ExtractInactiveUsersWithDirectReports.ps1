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
    Utilises the Get-DirectReport Function found here - https://thesysadminchannel.com/get-direct-reports-in-active-directory-using-powershell-recursive/
.NOTES  
    File Name  : ExtractInactiveUsersWithDirectReports.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Import ActiveDirectory Module
Import-Module ActiveDirectory

# Make C:\Temp directory
Write-Host "Creating C:\Temp directory..."
New-Item -Path "C:\" -Name "Temp" -ItemType "Directory" -Force

Function Get-DirectReport {
    #requires -Module ActiveDirectory
     
    <#
    .SYNOPSIS
        This script will get a user's direct reports recursively from ActiveDirectory unless specified with the NoRecurse parameter.
        It also uses the user's EmployeeID attribute as a way to exclude service accounts and/or non standard accounts that are in the reporting structure.
      
    .NOTES
        Name: Get-DirectReport
        Author: theSysadminChannel
        Version: 1.0
        DateCreated: 2020-Jan-28
      
    .LINK
        https://thesysadminchannel.com/get-direct-reports-in-active-directory-using-powershell-recursive -   
      
    .PARAMETER SamAccountName
        Specify the samaccountname (username) to see their direct reports.
      
    .PARAMETER NoRecurse
        Using this option will not drill down further than one level.
      
    .EXAMPLE
        Get-DirectReport username
      
    .EXAMPLE
        Get-DirectReport -SamAccountName username -NoRecurse
      
    .EXAMPLE
        "username" | Get-DirectReport
    #>
     
        [CmdletBinding()]
        param(
            [Parameter(
                Mandatory = $false,
                ValueFromPipeline = $true,
                ValueFromPipelineByPropertyName = $true
            )]
     
            [string]  $SamAccountName,
     
            [switch]  $NoRecurse
        )
     
        BEGIN {}
     
        PROCESS {
            $UserAccount = Get-ADUser $SamAccountName -Properties DirectReports, DisplayName
            $UserAccount | select -ExpandProperty DirectReports | ForEach-Object {
                $User = Get-ADUser $_ -Properties DirectReports, DisplayName, Title, EmployeeID
                if ($null -ne $User.EmployeeID) {
                    if (-not $NoRecurse) {
                        Get-DirectReport $User.SamAccountName
                    }
                    [PSCustomObject]@{
                        SamAccountName     = $User.SamAccountName
                        UserPrincipalName  = $User.UserPrincipalName
                        DisplayName        = $User.DisplayName
                        Manager            = $UserAccount.DisplayName
                    }
                }
            }
        }
     
        END {}
     
}

# Specify Left OU
$TargetUsers = Get-ADUser -Filter * -SearchBase “OU=Left,OU=Users,OU=Corsham,DC=pharmaxo,DC=local” | Select-Object -ExpandProperty SamAccountName 

# For each user in the specified Left OU, get their direct report and set as $Results variable
$Results = foreach ( $TargetUser in $TargetUsers ) {
    $TargetUser | Get-DirectReport
 }

# Export $Results as a CSV to C:\Temp
$Results | Export-Csv -Path "C:\Temp\InactiveUsersWithDirectReports.csv" -NoTypeInformation
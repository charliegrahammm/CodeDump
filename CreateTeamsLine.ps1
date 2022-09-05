Install-Module -Name PowerShellGet -Force -AllowClobber
Install-Module -Name MicrosoftTeams -RequiredVersion 3.1.1 -Force -AllowClobber
Connect-MicrosoftTeams
Get-CsOnlineUser | Where-Object LineUri -Like "tel:+*" | Select-Object -Property DisplayName, LineUri | Out-GridView
$name = Read-Host 'Enter the users email' 
$number = Read-Host 'Enter the DDI as +441225 ...'
$type = Read-Host 'Enter Phone number type [DirectRouting][CallingPlan][OperatorConnect]'
Set-CsPhoneNumberAssignment -PhoneNumber $number -Identity $name -PhoneNumberType $type | Set-CsPhoneNumberAssignment -Identity $name -EnterpriseVoiceEnabled $true
Grant-CsTenantDialPlan -Identity $name -PolicyName UK-Bath
Grant-CsOnlineVoiceRoutingPolicy -Identity $name -PolicyName UK-Bath-AllCalls
write-output "DDI Creation Successful"

# Remove-PSSession $sfbSession

# /////////////////////////////
# Set-CsPhoneNumberAssignment
#   -Identity <String>
#   -PhoneNumber <String>
#   -PhoneNumberType <String>
#   [-LocationId <String>]
#   [<CommonParameters>]
# /////////////////////////////
# OnPremLineURI (Set-CsUser) == PhoneNumber (Set-CsPhoneNumberAssignment)

# tel: (string) before -PhoneNumber is uneccassary
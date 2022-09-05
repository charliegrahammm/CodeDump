Install-Module -Name PowerShellGet -Force -AllowClobber
Install-Module -Name MicrosoftTeams -Force -AllowClobber
Connect-MicrosoftTeams
Get-CsOnlineUser | Where-Object LineUri -Like "tel:+*" | Select-Object -Property DisplayName, LineUri | Out-GridView
$name = Read-Host 'Enter the users email' 
$number = Read-Host 'Enter the DDI as +441225 ...'
Set-CsPhoneNumberAssignment -Identity $name -PhoneNumber $number -PhoneNumberType DirectRouting
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
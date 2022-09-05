Import-Module MicrosoftTeams
$sfbSession = New-CsOnlineSession
Import-PSSession $sfbSession -AllowClobber

function CommandBlock {
	$name = Read-Host "What is the username of the user you want to add to the Communal Phone policy"
	Grant-CsTeamsIPPhonePolicy -Identity $name -PolicyName "CAP"
	Grant-CsTeamsCallingPolicy -Identity $name -PolicyName "CAP"
        $previous = $?
        if ( $previous -like "*true*" )
		{
        ECHO "$name added to the policy"
        }
		else
        {
		ECHO "An error occurred.."
		}
}

$result = 0

while ($result -eq 0){
CommandBlock

$message = "Do you want to run again?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Runs script again"

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Exits script"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0)
}

Remove-PSSession $sfbSession
Install-Module AzureADPreview -Force
Connect-AzureAD

function CommandBlock {
	$GroupName = Read-Host "What is the name of the group you would like to disable guest access for? e.g Bath ASU - QC Craft Club Group"
	$template = Get-AzureADDirectorySettingTemplate | ? {$_.displayname -eq "group.unified.guest"}
	$settingsCopy = $template.CreateDirectorySetting()
	$settingsCopy["AllowToAddGuests"]=$False
	$groupID = (Get-AzureADGroup -SearchString $GroupName).ObjectId
	New-AzureADObjectSetting -TargetType Groups -TargetObjectId $groupID -DirectorySetting $settingsCopy
        $previous = $?
        if ( $previous -like "*true*" )
		{
        ECHO "Disabled Guest Access for $GroupName"
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

exit
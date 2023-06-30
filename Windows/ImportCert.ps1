<# 
 ██████╗██╗  ██╗ █████╗ ██████╗ ██╗     ██╗███████╗     ██████╗ ██████╗  █████╗ ██╗  ██╗ █████╗ ███╗   ███╗
██╔════╝██║  ██║██╔══██╗██╔══██╗██║     ██║██╔════╝    ██╔════╝ ██╔══██╗██╔══██╗██║  ██║██╔══██╗████╗ ████║
██║     ███████║███████║██████╔╝██║     ██║█████╗      ██║  ███╗██████╔╝███████║███████║███████║██╔████╔██║
██║     ██╔══██║██╔══██║██╔══██╗██║     ██║██╔══╝      ██║   ██║██╔══██╗██╔══██║██╔══██║██╔══██║██║╚██╔╝██║
╚██████╗██║  ██║██║  ██║██║  ██║███████╗██║███████╗    ╚██████╔╝██║  ██║██║  ██║██║  ██║██║  ██║██║ ╚═╝ ██║
 ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝╚══════╝     ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝

.SYNOPSIS  
    This script will copy and import a specified cert into a specified machines "Cert:\LocalMachine\Personal" cert store
.DESCRIPTION
    You will need to export the public key and store it in a memorable location beforehand. This will copy that file to the specified machine and import it.
.NOTES  
    File Name  : ImportCert.ps1  
    Author     : Charlie Graham 
    Requires   : PowerShell v2
#>

# Ask for input
$CertSource = Read-Host -Prompt 'Input certificate location'
$Machines = Read-Host -Prompt 'Input a machine name'
$CertFileName = Split-Path $CertSource -Leaf

# Copy files to relevant machines
Write-Host "Copying files..." -ForegroundColor Green

foreach ($Computer in $Machines) {
    New-Item -Type Directory "C:\Temp" -Force
    $Destination = "\\$Computer\c$\temp\"
    Copy-Item -Path $CertSource -Destination $Destination
}

# Create parameter to be used by Invoke-Command containing script block and target hostname
Write-Host "Installing cert..." -ForegroundColor Green

$parameters = @{
    ComputerName = "$Machines"
    ScriptBlock  = {

        # Translate local $ to $ within Invoke-Command	
        $Destination = $Using:Destination
        $CertFileName = $Using:CertFileName

        # Import Cert
        $params = @{
            FilePath          = "$Destination\$CertFileName"
            CertStoreLocation = 'Cert:\LocalMachine\My'
        }
        Import-Certificate @params

    }
}
	
Invoke-Command @parameters






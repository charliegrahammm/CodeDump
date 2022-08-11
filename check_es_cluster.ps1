# +----------------------------------------+---------------------------------------------+
# |  ██████╗ ██████╗ ██╗  ██╗██╗           | Title:   check_es_stream.ps1                | 
# | ██╔═══██╗██╔══██╗██║  ██║██║           | Author:  Richard Knight/Charlie Graham/CW   |
# | ██║   ██║██████╔╝███████║██║           | Date:    04/08/2022                         |
# | ██║▄▄ ██║██╔═══╝ ██╔══██║██║           | Version: 1.2                                |
# | ╚██████╔╝██║     ██║  ██║███████╗      |                                             |
# |  ╚══▀▀═╝ ╚═╝     ╚═╝  ╚═╝╚══════╝      |                                             |
# +----------------------------------------+---------------------------------------------+
# | Description:                                                                         |
# | Checks the specified EventStore stream to see if it has updated in the last 5 mins.  |
# |                                                                                      |
# | Revision History:                                                                    |
# |                                                                                      |
# | 05/08/2022 - Jack Harvard (ComputerWorld) - Version 1.2                              |
# |  - Finished script                                                                   |
# | 02/08/2022 - Charlie Graham - Version 1.1                                            |
# |  - Amended formatting                                                                |
# | 02/08/2022 - Richard Knight - Version 1.0                                            |
# |  - Script Created                                                                    |
# |                                                                                      |
# +--------------------------------------------------------------------------------------+

# Set mandatory parameters
Param (
    [Parameter(Mandatory=$true)]
    [string]$HostName,
    [Parameter(Mandatory=$true)]
    [string]$port)

# Specify parameters for Invoke-WebRequest command
$InvokeParams = @{
    Uri = "http://${hostname}:${port}/gossip"
}

# Gather information
try {
    $response = Invoke-WebRequest @InvokeParams
} catch {
    $errorMessage = "Failed to get cluster status from $url. $_"
    Write-Output "<prtg><error>1</error><text>$errorMessage</text></prtg>"
    exit 1;
}

$StatusCode = $response.StatusCode

if ($StatusCode -ne 200) {
    $errorMessage = "The gossip page didn't load correctly."
    Write-Output "<prtg><error>4</error><text>$errorMessage</text></prtg>"
    exit 4;
}

$gossip = ConvertFrom-Json $response.content

# Gets the nodes from the JSON data. (Run this to see the objects you can use)
#$gossip | get-member

# Generate a blank array to hold the node status responses.
$statuses = @("","","")

# Used to set the array values above.
$index = 0

# Presume that the status will be OK. Will be updated if otherwise.
$ExitCode = 0

$DeadNodes = 0

# We loop on each node within the data, checking the status and adding to the statuses array.
$gossip.members | ForEach-Object { 
    $isAlive = if ($_.isAlive = "True") {
        "Alive"
    } else {
        "Dead"
        $ExitCode = 1
        $DeadNodes = $DeadNodes + 1
    }
    # Adds a space to the end of the line if it's not the last one
    $space = if ($index -lt 2) {
        " "
    } else {
        ""
    }
    $status = "[" + $_.state + ": "+ $_.internalTcpIp + " " + $isAlive + "]" + $space
    $statuses[$index] = $status
    $index = $index + 1
}

$FinalMessage = ""

foreach ($status in $statuses) {
    $FinalMessage += $status
}

if ($ExitCode -eq 0) {
    Write-Output $FinalMessage
    exit 0;
} else {
    $errorMessage = "$DeadNodes dead nodes were found!"
    Write-Output "<prtg><error>1</error><text>$errorMessage</text></prtg>"
    exit 1;
}
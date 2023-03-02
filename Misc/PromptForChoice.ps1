Function Get-ProjectType {
    $type=Read-Host "
    1 - gaming
    2 - Home Ent
    3 - Theatrical
    4 - TV and Streaming
    5 - VR
    Please choose"
    Switch ($type){
        1 {$choice="Gaming"}
        2 {$choice="Home Entertainment"}
        3 {$choice="Theatrical"}
        4 {$choice="TV & Streaming"}
        5 {$choice="VR"}
    }
    return $choice
}

$projectType=Get-ProjectType
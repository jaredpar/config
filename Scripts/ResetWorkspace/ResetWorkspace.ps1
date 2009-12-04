param (
    $userName = $("{0}\{1}" -f $env:UserDomain,$env:UserName) )

$server = "http://vstfdevdiv:8080"

function script:New-Tuple()
{
    param ( [object[]]$list= $(throw "Please specify the list of names and values") )

    $tuple = new-object psobject
    for ( $i= 0 ; $i -lt $list.Length; $i = $i+2)
    {
        $name = [string]($list[$i])
        $value = $list[$i+1]
        $tuple | add-member NoteProperty $name $value
    }

    return $tuple
}

function script:Get-Workspaces() { 
    $output = & tf workspaces /s:$server /owner:$userName /format:brief
    $i = 0; 
    # Skip the --- 
    while ( -not ($output[$i] -match "^---.*") ) {
        $i++
    }
    $i++
    while ( $i -lt $output.Length ) {
        $cur = $output[$i]
        if ( $cur -match "^(\w+)\s+(\w+)\s+(\w+).*" ) {
            $value = New-Tuple WorkSpace,$matches[1],Computer,$matches[3]
            Write-Output $value 
        }
        $i++
    }
}

write-host "Getting Workspaces for $userName"
$workspaces = Get-Workspaces
for ( $i = 0 ; $i -lt $workspaces.Count; $i++ ) {
    write-host ("  {0}: {1}->{2}" -f $i,$workspaces[$i].Workspace,$workpaces[$i].Computer)
}
$number = [int32](read-host "Which workspace to migrate: ")
$value = $workspaces[$number]
& tf workspaces /s:$server /updateComputerName:$($value.Computer) $($value.Workspace)


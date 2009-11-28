
function Get-ChangeLists()
{

}

function Find-Unadded()    
{
    param ( [string] $path = ".",
            [string] $include = "*",
            [switch] $recurse )
    pushd $path
    
    $map = @{}
    $notInDepotList = @()
    $output = @(& sd files *)
    foreach ($cur in $output)
    {
        if ( $cur -match ".*\/([a-z0-9.]*)#.*" )
        {
            write-debug ("SD File {0} From {1}" -f $matches[1],$cur)
            $map[$matches[1]] = $true
        }
    }

    foreach ($file in (gci -include $include))
    {
        if ( $file.PSIsContainer )
        {
            continue;
        }

        if ( -not $map.Contains($file.Name) )
        {
            $notInDepotList += $file 
        }
    }

    popd

    if ( $recurse )
    {
        foreach ( $cur in (gci | ? { $_.PSIsContainer }))
        {
            $notInDepotList += SdFindUnadded $cur $true
        }
    }

    $notInDepotList
}


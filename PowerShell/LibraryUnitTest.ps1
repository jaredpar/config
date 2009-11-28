
# Testing

function Assert-Error()
{
    param ( [string]$msg,
            [string]$userMsg )

    if ( $userMsg.Length -gt 0 )
    {
        write-output ("!!!ERRROR!!! {0}: {1}" -f $msg,$userMsg)
    }
    else
    {
        write-output "!!!ERRROR!!! $msg"
    }
}


function Assert-True([bool]$value, [string]$msg)
{
    if ( -not $value )  
    {
        Assert-Error $msg
    }
}

function Assert-False() {
    param ( [bool]$value, [string]$msg="" )
    if ( $value ) { 
        Assert-Error $msg 
    }
}

function Assert-Equal()
{
    param ( $expected,
            $actual,
            [string]$userMsg= $null )
    if ( -not ($expected -eq $actual) )
    {
        $msg = "Values not equal -  Expected: $expected Actual: $actual"
        Assert-Error $msg $userMsg
    }
}

function Assert-NotEqual()
{
    param ( $expected,
            $actual,
            [string]$userMsg= $null )
    if ( $expected -eq $actual )
    {
        $msg = "Values equal - Expected: $expected Actual: $actual"
        Assert-Error $msg $userMsg
    }
}

function Assert-ArrayEqual()
{
    param ( $expectedArray,
            $actualArray,
            [string]$userMsg= $null )
    if ( $expectedArray.Length -ne $actualArray.Length )
    {
        $msg = "Different lengths Expected:{1} Actual:{2}" -f $msg,$expectedArray.Length,$actualArray.Length
        Assert-Error $msg $userMsg
        write-output "Expected"
        write-output $expectedArray
        write-output "Actual"
        write-output $actualArray
        return
    }

    for ( $i = 0; $i -lt $expectedArray.Length; $i++ )
    {
        $expected = $expectedArray[$i]
        $actual = $actualArray[$i]
        Assert-Equal $expected $actual $msg $userMsg
    }
}


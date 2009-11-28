

# Parse out the "tf status" command into usable output
function Get-TfStatus() {
    param ( [string]$path= "." ,
            [switch]$recursive = $false )

    $args = ""
    if ( $recursive ) {
        $args = "/r"
    }
    $output = [string[]](& tf status $path $args)

    # First two lines are junk so skip past it
    for ( $i = 2; $i -lt $output.Length; $i++ ) {
        $name,$edit,$path = $output[$i].Split(" ", [StringSplitOptions]"RemoveEmptyEntries")
        if ( $path -and (test-path $path) ) {
            new-tuple "FileName",$name,"Change",$edit,"FilePath",$path
        }
    }
}


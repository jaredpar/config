
#==============================================================================
# Functions for managing the overal configuration
#==============================================================================


# Update the configuration from the source code server
function Update-Config() {
    param ( [switch]$force=$false )

    # First see if we've updated in the last day 
    $target = join-path $env:temp "Jsh.Update.txt"
    $update = $false
    if ( test-path $target ) {
        $last = [datetime] (gc $target)
        if ( ([DateTime]::Now - $last).Days -gt 1) {
            $update = $true
        }
    } else {
        $update = $true;
    }

    if ( $update -or $force ) {
        write-host "Checking for winconfig updates"
        pushd $Jsh.ConfigPath
        $output = @(& svn update)
        if ( $output.Length -gt 1 ) {
            write-host "WinConfig updated.  Re-running configuration"
            . script common
            cd $Jsh.ScriptPath
            & .\ConfigureAll.ps1
            . .\Profile.ps1
        }

        sc $target $([DateTime]::Now)
        popd
    }
}

# Run all of the configuration scripts
function Configure-All() {
    Update-Config

    & (join-path $Jsh.ScriptPath "ConfigureAll.ps1")
}


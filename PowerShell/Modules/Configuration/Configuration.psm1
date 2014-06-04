

#==============================================================================
# Runs all of the configuration scripts on the machine in order to repair 
# it
#==============================================================================
function Repair-Configuration() { 
    param ([string]$specific = "")
    pushd $PSScriptRoot

    if ( $specific -eq "" ) { 
        $all = @(   'Vim.ps1', 
                    'Git.ps1', 
                    'PowerShell.ps1', 
                    'UnixTools.ps1',
                    'ProductStudio.ps1')
        foreach ( $cur in $all ) {
            write-host "Running $cur"
            & (".\" + $cur) | %{ write-host ("`t{0}" -f $_) } 
        }
    } else { 
        & $PSScriptRoot\$specific 
    }
    popd
}


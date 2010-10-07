

#==============================================================================
# Runs all of the configuration scripts on the machine in order to repair 
# it
#==============================================================================
function Repair-Configuration() { 
    pushd $PSScriptRoot
    $all = @(   'Vim.ps1', 
                'Git.ps1', 
                'PowerShell.ps1', 
                'Reflector.ps1',
                'UnixTools.ps1')
    foreach ( $cur in $all ) {
        write-host "Running $cur"
        & (".\" + $cur) | %{ write-host ("`t{0}" -f $_) } 
    }
    popd
}


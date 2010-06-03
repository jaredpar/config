
if ( -not (test-path env:\MIDROOT) ) {
    write-error "Needs to be run under the midori environment"
    exit
}

$midPath = ${env:MIDROOT}
$winPath = join-path $midPath "Internal\Bin\Windows"

set-alias jjpack (join-path $winPath "jjpack.exe") 


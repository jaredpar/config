
#==============================================================================
# Copy the Midori build into the M# branch and personal development folder 
#==============================================================================
function Copy-MidoriBuild() {
    
    pushd (join-path ${env:MSHARPROOT} "midori\assemblies")
    $source = join-path ${env:MIDORI_OBJROOT} "BuildTools"
    $devPath = (join-path ${env:userprofile} "Midori")
    sd edit *
    foreach ( $i in gci *.dll,*.pdb) {
        copy (join-path $source $i.Name) .
        copy $i.FullName $devPath -force
    }
    popd
}

#==============================================================================
# Specialized M# prompt
#==============================================================================
function prompt() {
    write-host -NoNewLine -ForegroundColor Red "M# "

    if (${env:MIDORI_MSHARP_CHECK} -eq "true") {
        write-host -NoNewLine -ForegroundColor Red "Check "
    }

	write-host -NoNewLine -ForegroundColor Green $(get-location)

	foreach ($entry in (get-location -stack)) {
		write-host -NoNewLine -ForegroundColor Red '+';
	}
	write-host -NoNewLine -ForegroundColor Green '>'
	' '
}


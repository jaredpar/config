
#==============================================================================
# Copy the Midori build into the M# branch and personal development folder 
#==============================================================================
function Copy-MidoriBuild() {
    param ( $branch = "framework",
            $midRoot = "e:\dd\midori" )

    if (-not (test-path env:\DepotRoot)) {
        throw "Must be run under a razzle window";
    }

    $source = join-path $midRoot "branches"
    $source = join-path $source $branch
    $source = join-path $source "Midori.obj\BuildTools"

    $devPath = (join-path $env:userprofile "Midori")
    pushd (join-path $env:DepotRoot "midori\assemblies")
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
    if (${env:MSHARP_PREBUILT_ARG} -eq "live") {
        write-host -NoNewLine -ForegroundColor Red "Live "
    }

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


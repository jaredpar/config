
if ( test-path env:\DepotRoot ) {
    set-alias updatebin (join-path $env:DepotRoot "midori\build\scripts\updatebinaries.cmd")
}


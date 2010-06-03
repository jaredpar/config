
function Get-Razzle() {
    param ( [string]$name="*" )

    foreach ( $letter in Get-LocalDrive ) {
        $ddPath = join-path $letter "dd"
        write-debug "Considering: $ddPath"
        if ( test-path $ddPath ) {
            foreach ( $cur in gcid $ddPath ) {
                if ( -not ( $cur.Name -like $name) ) {
                    continue
                }

                $depotPath = join-path $cur.FullName "src"
                write-debug "Considering: $depotPath"
                if ( test-path $depotPath ) {
                    write-output (New-Tuple "Name",$cur.Name,"DepotPath",$depotPath)
                }
            }
        }
    }
}

# Method to startup a PowerShell razzle environment
function Set-Razzle() {
    param ( [string]$name = $(throw "Provide a name in the map"),
            [string]$arch = "x86",
            [string]$flavor = "chk" ) 

    # Razzle won't run in a 64 bit shell or a non-admin
    if ( (test-win64) -or (-not (test-admin))) {
        write-host "Starting 32 bit admin shell"
        Invoke-CommandAdmin "set-razzle $name $arch $flavor " -dotsource -use32
        return
    }

    $info = get-razzle $name
    if ( $info -eq $null )
    {
        write-output "Error: $name is not a valid razzle entry"
        get-razzle
        return
    }

    # Build up the razzle arguments.  Don't run OACR unless we are in RET
    $razzleArgs = "{0} {1}" -f $arch,$flavor
    if ( $flavor -ne "ret" ) {
        $razzleArgs += " No_OACR"
    }

    # If the custom setrazzle.ps1 command does not exist in the depot at this
    # location then generate it to call my command to load my razzle
    # environment script
    $setRazzle = join-path $info.DepotPath "developer\$($env:username)"
    if ( -not (test-path $setRazzle) ) {
        mkdir $setRazzle | out-null
    }
    $setRazzle = join-path $setRazzle "setrazzle.ps1"
    remove-itemtest $setRazzle
    $myRazzle = join-path $Jsh.ScriptPath "Redmond\LibraryRazzleEnv.ps1"
    $command = '. "' + $myRazzle + '"'
    sc $setRazzle $command

    # Actually start razzle
    . (join-path $info.DepotPath "tools\razzle.ps1") $razzleArgs
}	

# Disable strong name verification on the machine
function Disable-StrongName() {
    $path = join-path (Get-ProgramFiles32) "Microsoft SDKS\Windows\v7.0A\Bin"
    $sn = join-path $path "sn.exe"
    $sn64 = join-path $path "x64\sn.exe" 

    if ( -not (Test-Admin) ) {
        write-error "Must be an admininstrator to run this"
        return
    }

    & $sn -Vr *
    & $sn64 -Vr *
}



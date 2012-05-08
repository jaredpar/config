
# Method to startup a PowerShell razzle environment
function Set-MSharp() {
    param ( [string]$branch = $(throw "Pick a branch"),
            [string]$flavor = "chk" ) 

    # Razzle won't run in a 64 bit shell or a non-admin
    if ( (test-win64) -or (-not (test-admin))) {
        write-host "Starting 32 bit admin shell"
        Invoke-CommandAdmin "set-msharp $branch $flavor " -dotsource -use32
        return
    }

    $path = join-path 'e:\dd\midori\branches' $branch
    $path = join-path $path 'MSharp'
    if ( -not (test-path $path)) {
        write-output "Error: $name is not a valid razzle entry"
        get-razzle
        return
    }

    # Build up the razzle arguments.  Don't run OACR unless we are in RET
    $razzleArgs = $flavor
    $razzleArgs += " No_OACR"
    if ( $flavor -ne "ret" ) {
        $razzleArgs += " No_opt"
    }

    # Actually start razzle
    . (join-path $path "tools\razzle.ps1") $razzleArgs

    import-module MSharp -Global
}	

# Method to startup a Midori environment
function Set-Midori() {
    param ( [string]$branch = $(throw "Pick a branch"))

    $path = join-path 'e:\dd\midori\branches' $branch
    if (-not (test-path $path)) {
        write-error "Branch doesn't exist: $path"
        return
    }

    cd $path
    cd Midori
    . .\setenv.ps1
    import-module Midori -Global
    . set-env 
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

function Set-Midori() {
    param ( [string]$branch = 'framework')

    $path = join-path 'e:\dd\midori\branches' $branch
    $path = join-path $path 'Midori'
    cd $path


    . .\setenv.ps1
    import-module Midori -Global
    Set-Env
}

function Set-MidoriFramework() { Set-Midori 'framework' }

set-alias odd \\midweb\scratch\jaredpar\tools\odd\odd.exe -scope Global
set-alias midf Set-MidoriFramework -scope Global


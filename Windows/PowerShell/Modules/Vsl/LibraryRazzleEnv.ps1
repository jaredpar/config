
# My computer shares
$script:s_compList = 
        "\\vb\public\jaredpar\packs",
        "\\jaredpar05\e$\public\packs",
        "\\jaredpar06\d$\public\packs",
        "\\jaredpar09\d$\public\packs",
        "\\jaredpar01\c$\public\packs"

# Set the prompt
function prompt() {
    write-host -NoNewLine -ForegroundColor Red "Razzle $env:_BuildType "
	write-host -NoNewLine -ForegroundColor Green $(get-location)
	foreach ( $entry in (get-location -stack))
	{
		write-host -NoNewLine -ForegroundColor Red '+';
	}
	write-host -NoNewLine -ForegroundColor Green '>'
	' '
}

function cleanvsassert() {
    $pathList = @()
    $pathList += join-path $env:ProgramFiles "Microsoft Visual Studio 10.0\Common7\IDE"
    $pathList += join-path $env:ProgramFiles "Microsoft Visual Studio 10.0\Common7\IDE\Remote Debugger\x86"
    $pathList += gci $env:windir\Microsoft.Net\Framework\v3* 
    $pathList += join-path $env:SystemRoot "System32"

    foreach ( $cur in $pathList )
    {
        if ( test-path $cur )
        {
            echo "Checking $cur"
            pushd $cur
            remove-itemtest -force vsassert.dll
            remove-itemtest -force vsassert.pdb
            popd
        }
    }
}

function updateVsassert() {
    param ([string]$machine="")

    $root = $env:SystemRoot
    if ( $machine -ne "" ) {
        $root = "\\$machine\c`$\Windows\"
    }
    $target = join-path $root "System32"

    echo "Copying vsassert.dll to System32"
    copy -force $env:DepotRoot\public\internal\EnvSDK\lib\i386\vsassert.dll $target
}

# Deploy the basic compiler bits
function updateVbc()
{
    # Find the framework directory
    $dirlist = @(dir $env:windir\Microsoft.Net\Framework\v4* | sort)
    $frameworkDir = $dirlist[$dirlist.Count - 1]
    echo "Targeting Framework $frameworkDir"

    pushd "$env:_NTPOSTBLD\bin\i386" 

    echo "Copying vbc.exe"
    copy -force vbc.exe $frameworkDir
    echo "Copying vbc.pdb"
    copy -force vbc.pdb $frameworkDir
    echo "Copying vbc7ui.dll"
    copy -force vbc7ui.dll $frameworkDir\1033

    popd
}

# Update the devenv libraries
function updateIde()
{
    param ([string]$machine="")
    pushd "$env:_NTPOSTBLD\bin\i386"
    cd vspkgs

    $root = $env:ProgramFiles
    if ( $machine -ne "" ) {
        $root = "\\$machine\c`$\Program Files"
    }
    $target = join-path $root "Microsoft Visual Studio 10.0\Common7\IDE"

    echo "Target $target"
    safeDeployBinary msvbide.dll $target
    safeDeployBinary 1033\msvbideui.dll $target\1033
    safeDeployBinary vbdebug.dll $target
    safeDeployBinary 1033\vbdebugui.dll $target\1033
    safeDeployBinary Microsoft.VisualBasic.LanguageService.dll (join-path $target PrivateAssemblies)

    $target = join-path $target "CommonExtensions\Microsoft\VB\LanguageService\10.0"
    safeDeployBinary Microsoft.VisualBasic.Editor.dll $target
    safeDeployBinary Microsoft.VisualStudio.VisualBasic.LanguageService.dll $target
 
    popd
    updateVsassert $machine
}

# Safely deploy a new file to a VS drop.  This will force a backup of the original file and then 
# copy over the new file
function safeDeployFile() { 
    param ( [string]$source = $(throw "Need a source"),
            [string]$target = $(throw "Need a target directory"))

    $fileName = split-path -leaf $source
    $orig = join-path $target $fileName
    $origBackup = join-path $target ($fileName + ".orig")
    if ( (test-path $orig) -and (-not (test-path $origBackup) )) { 
        copy $orig $origBackup
    }

    xcopy /dfiy $source $target 
}

function testSafeDeployBinary() {
    param ( [string]$source = $(throw "Need a source"),
            [string]$target = $(throw "Need a target directory"))

    if ( test-path $source ) {
        safeDeployBinary $source $target
    }
}


# Safely deploy a new binary to a VS drop.  This will copy a DLL/EXE and it's binary
function safeDeployBinary() {
    param ( [string]$source = $(throw "Need a source"),
            [string]$target = $(throw "Need a target directory"))
    
    if (-not (test-path $source) ) {
        throw "Source does not exist: $source"
    }

    safeDeployFile $source $target

    # Deploy the PDB
    $pdbFile = [IO.Path]::ChangeExtension($source, "pdb")
    if ( test-path $pdbFile ) {
        safeDeployFile $pdbFile $target
    }
}

# Update the devenv libraries
function updatePlatform()
{
    param ([string]$machine="")

    $sourceList = 
        "$env:_NTPOSTBLD\bin\i386",
        "$env:_NTPOSTBLD\bin\i386\vspkgs"

    $root = $env:ProgramFiles
    if ( $machine -ne "" ) {
        $root = "\\$machine\c`$\Program Files"
    }
    $targets = 
        (join-path $root "Microsoft Visual Studio 10.0\Common7\IDE\Components"),
        (join-path $root "Microsoft Visual Studio 10.0\Common7\IDE")

    write-host "Target $root"
    foreach ($child in (gci $targets)) {
        if ($child.PSIsContainer -or (-not ($child.FullName.endsWith("dll")))) {
            continue
        }

        $file = $sourceList | %{ join-path $_ $child.Name } | ?{ test-path $_ } | select -first 1
        if ($file -eq $null) {
            continue;
        }

        write-host "Copying: $(split-path -leaf $file)"
        $target = split-path $child.FullName
        safeDeployBinary $file $target
    }

    popd
}

function updateEditor() {
    param ([string]$machine="")

    pushd "$env:_NTPOSTBLD\bin\i386\vspkgs"

    $root = $env:ProgramFiles
    if ( $machine -ne "" ) {
        $root = "\\$machine\c`$\Program Files"
    }

    $target = join-path $root "Microsoft Visual Studio 10.0\Common7\IDE"
    testSafeDeployBinary Microsoft.VisualStudio.ComponentModelHost.dll $target
    testSafeDeployBinary Microsoft.VisualStudio.ComponentModelHost.Implementation.dll $target

    $target = join-path $target "CommonExtensions\Platform\Editor"
    safeDeployBinary Microsoft.VisualStudio.Editor.dll $target
    safeDeployBinary Microsoft.VisualStudio.Editor.Implementation.dll $target
    popd
}

# Backup a current edit onto several machines.  Call me paranoid, I don't care :)
function BackupCode([string]$packName, [string]$changelist)
{
    if ( [String]::IsNullOrEmpty($packName) )
    {
        echo "Must enter a name for the backup"
        return
    }

    if ( [String]::IsNullOrEmpty($changeList))
    {
        $changeList = "default"
    }

    # Create the JJPack
    $jjpackName = "$packName.jpk"
    $jjpackPath = join-path $env:temp $jjpackName
    echo "JJ Packing $jjpackName"
    jjpack pack $jjpackPath -f -c $changeList > $env:tmp\jjpack.log
    if ( (-not $?) -or -not (test-path $jjpackPath) )
    {
        echo "!!!Error!!!.  Displaying log for more information"
        cat $env:tmp\jjpack.log
    }

    $bbpackName = "$packName.cmd"
    $bbpackPath = join-path $env:temp $bbpackName
    echo "BB Packing $bbpackName"

    pushd $env:DepotRoot
    bbpack -c $changeList -o $bbpackPath ... > $env:temp\bbpack.log
    if ( (-not $?) -or -not (test-path $bbpackPath) )
    {
        echo "!!!Error!!!.  Displaying log for more information"
        cat $env:tmp\bbpack.log
    }
    popd

    foreach ($comp in $s_compList )
    {
        if ( -not (test-path $comp)  )
        {
            mkdir $comp
        }

        echo "Propating $jjpackName to $comp"
        $target = join-path $comp $jjpackName
        if ( test-path $target )
        {
            echo "!!!Error!!!  Pack already exists"
            continue
        }
        copy $jjpackPath $target

        echo "Propagating $bbpackName to $comp"
        $target = join-path $comp $bbpackName
        if ( test-path $target )
        {
            echo "!!!Error!!! Pack already exists"
            continue
        }
        copy $bbpackPath $target
    }

    del $jjpackPath
    del $bbpackPath
}

function ShareBitsForBuddyTest([int]$bugNumber=-1)
{
    if ( $bugNumber -lt 0 )
    {
        echo "Provide the bug number"
        return
    }

    pushd "$env:_NTPOSTBLD\bin\i386"

    foreach ( $comp in $s_compList )
    {
        $path = join-path $comp ("BuddyTest_" + $bugNumber)
        if ( -not (test-path $path) )
        {
            mkdir $path | out-null
        }

        echo "Processing $path"
        echo "`tCopying msvb7"
        copy --force vspkgs\msvb7* $path
        echo "`tCopying msvb7ui"
        copy --force vspkgs\1033\msvb7* $path
        echo "`tCopying vbc"
        copy --force vbc* $path
        echo "`tCopying vsassert"
        copy --force $(join-path $env:DepotRoot "public\internal\EnvSDK\lib\i386\vsassert.dll") $path
    }

    popd
}

function Untab-Changes() {
    function Filter-Output() {
        begin {}
        process {
            if ( $_ -match '(.*)\s+([a-z]+)\s+([a-z]:.*)' ) {
                $matches[3]
            }
        }
        end {} 
    }
    function Filter-Lines() { 
        begin { $isFirst = $true}
        process {
            if ( $isFirst ) {
                $isFirst = $false    # Don't mess with BOM
                $_
            } elseif ( $_ -match "^(`t+)(.*)" ) {
               $prefix = new-object string " ",($matches[1].Length*4) 
               $prefix + $matches[2]
            } else {
                $_
            }
        }
        end{}
    }

    pushd $env:DepotRoot
    $files = & tf status . /r | Filter-Output
    foreach ( $file in $files ) {
        write-host "Processing $file"
        $lines = gc $file | Filter-Lines 
        $lines | out-file $file -encoding utf8
    }
    popd
}

function updateManagedPort() {
    pushd (join-path $env:DepotRoot "port\Managed\VB\Language\Compiler\CommandLine\bin\Release")
    $target = join-path $env:WinDir "Microsoft.NET\Framework\v3.5"

    write-host "Target is $target"
    copy * $target -force
    popd
}

function updateRascal() {
    param ([string]$target="")

    pushd (join-path $env:DepotRoot "port\Managed\VB\Language\ExpressionEvaluator\bin\Debug")
    if ( $target -eq "" ) {
        $target = "d:\temp\Rascal"
    }

    write-host "Target is $target"
    copy * $target -force
    # regasm  (join-path $target "Microsoft.VisualBasic.ExpressionEvaluator.dll")
    popd
}

function Get-DropData() {
    param ( $dropNumber=$(throw "Provide a drop number" ),
            $dest="e:\dropinfo" )  

    if ( -not (test-path $dest) ) {
        mkdir $dest | out-null
    }
    
    $build = "\\cpvsbuild\drops\dev10\vs_langs\raw\$dropNumber"
    if ( -not (test-path $build) ) {
        throw "Drop does not exist $build" 
    }

    & robocopy /r:2 /mir "$build\sources\csharp"        "$dest\sources\csharp"      *.*
    & robocopy /r:2 /mir "$build\sources\debugger"      "$dest\sources\debugger"    *.*
    & robocopy /r:2 /mir "$build\sources\env"           "$dest\sources\env"         *.*
    & robocopy /r:2 /mir "$build\sources\platform"      "$dest\sources\platform"    *.*
    & robocopy /r:2 /mir "$build\sources\public"        "$dest\sources\public"      *.*
    & robocopy /r:2 /mir "$build\sources\tools"         "$dest\sources\tools"       *.*
    & robocopy /r:2 /mir "$build\sources\vb"            "$dest\sources\vb"          *.*
    & robocopy /r:2 /mir "$build\sources\vscommon"      "$dest\sources\vscommon"    *.*
    & robocopy /r:2 /mir "$build\sources\vsproject"     "$dest\sources\vsproject"   *.*
    & robocopy /r:2 /mir "$build\binaries.x86chk"       "$dest\binaries.x86chk"     *.*
    & robocopy /r:2 /mir "$build\binaries.x86ret"       "$dest\binaries.x86ret"     *.*
}

#==============================================================================
# Sync's all of the build related directories to a specific build label
#==============================================================================
function Sync-Build() {
    param ([string]$label = $(throw "Need a build label"),
           [switch]$force=$false,
           [switch]$publicOnly=$false)
    $f = Get-Ternary $force "Force=True" "Force=False"
    fb sync Label="$label" FileSpec="public/..." $f
    if ( -not $publicOnly ) {
        fb sync Label="$label" FileSpec="tools/..." $f
    }
}

#==============================================================================
# Sync non-build related directories to the latest version.  
#==============================================================================
function Sync-Source() {
    param ([switch]$force=$false)
    pushd $env:DepotRoot
    
    $list = gci |
        ?{ $_.PSIsContainer } |
        %{ $_.Name } |
        ?{ ($_ -ne "public") -and ($_ -ne "tools") } |
        ?{ -not ($_ -match "^obj.*") } |
        ?{ (gci $_ | measure-object).Count -gt 0 }
    foreach ( $cur in $list ) {
        if ( $force ) {
            tf get $cur /r
        } else {
            tf get $cur /r /force
        }
    }

    popd
}


write-host "Loading LibraryRazzle.ps1"

# Make it easy to reload this information when I'm editing it
$Jsh.ScriptMap["razzle"] = $(join-path  $Jsh.ScriptPath "Redmond\LibraryRazzleEnv.ps1" ) 
$Jsh.ScriptMap["sd"] = $(join-path $Jsh.ScriptPath "Redmond\LibrarySourceDepot.ps1")

# Add jump locations
$Jsh.GoMap["vb"] = join-path $env:DepotRoot "vb" 
$Jsh.GoMap["dd"] = $env:DepotRoot
$Jsh.GoMap["lang"] = join-path $env:DepotRoot "vb\Language"
$Jsh.GoMap["bin"] = join-path $env:_NTPOSTBLD "bin\i386"
$Jsh.GoMap["suite"] = join-path $env:DepotRoot "ddsuites\src\vs\vb"

set-alias sync-binaries function:\sync-build

# Load the source depot commands
. script sd

# Remove the annoying red text if I am running an admin shell.  Razzle typically
# has to be run as an administrator and it's annoying to have it show up 
# with the red text.  Not to mention it gets confusing when you have build errors
if ( Test-Admin )
{
	$host.UI.RawUI.ForegroundColor = "White"
}

# Add a dd:\ drive for the enlistment
if ( -not (test-path "dd:\" ) )
{
    new-psdrive -name "dd" -psProvider FileSystem -root (resolve-path $env:DepotRoot) 
}

# Unpop all of the directories so that I can set the location to the depot root
0..(get-location -stack).count | % { pop-location }
cd $env:DepotRoot


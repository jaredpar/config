$script:scriptPath = split-path $MyInvocation.MyCommand.Definition 
$script:crtList = @()   # Versions
$script:redirectList = @()  # DAssembly list
$script:binList = @()

function New-Tuple() {
    param ( [object[]]$list= $(throw "Please specify the list of names and values") )

    $tuple = new-object psobject
    for ( $i= 0 ; $i -lt $list.Length; $i = $i+2) {
        $name = [string]($list[$i])
        $value = $list[$i+1]
        $tuple | add-member NoteProperty $name $value
    }

    return $tuple
}

function script:Get-CrtVersionDate() {
    foreach ( $version in $script:crtList) {
        $a = $version.ToString().Split(".")[2]
        $year = [int]($a[0].ToString()) + 2007
        $day = [int]($a.substring(3,2))
        $month = [int]($a.substring(1,2))
        return new-object DateTime $year,$month,$day,23,0,0
    }
}

# Quick little object for dependent assembly tags in a manifest
function script:New-Dependency() {
    param ( [xml]$elem = $(throw "Need a <dependentAssembly> tag") )
    
    write-debug "New-Dependency $($elem.get_innerxml())"
    $o = new-object PSObject
    $o | add-member NoteProperty "Xml" $elem.dependentAssembly
    $o | add-member ScriptProperty "AssemblyName" {
        $this.Xml.assemblyIdentity.name
    }
    $o | add-member ScriptProperty "AssemblyVersion" {
        $this.Xml.assemblyIdentity.version
    }
    $o | add-member ScriptProperty "IsCrt" {
        $this.AssemblyName -like "Microsoft.VC100.*CRT"
    }
    $o | add-member ScriptProperty "IsDebugCrt" {
        $this.IsCrt -and $this.AssemblyName -like "*Debug*"
    }
    $o | add-member ScriptProperty "HasRedirect" {
        $this.Xml.bindingRedirect -ne $null
    }
    $o | add-member ScriptProperty "OldRedirect" { 
        $this.Xml.bindingRedirect.oldVersion
    }
    $o | add-member ScriptProperty "NewRedirect" { 
        $this.Xml.bindingRedirect.newVersion
    }
    $o | add-member ScriptMethod "CanRedirect" {
        $v = [Version]$args[0]
        if ( $this.OldRedirect -like "*-*" ) {
            $a,$b = $this.OldRedirect.Split("-")
            $low = new-object Version $a
            $high = new-object Version $b
            if ( $v -ge $low -and $v -le $high) { 
                return $true
            }
        } else {
            return (new-object Version $this.OldRedirect) -eq $v
        }

        return $false
    }
    
    return $o
}


# Run a managed executable not built for razzle
function script:Run-Managed() {
    param ( [string]$filePath = $(throw "Need a file"),
            [string]$arg1 = "" )

    $a1 = $env:COMPLUS_InstallRoot
    $a2 = $env:COMPLUS_Version

    $env:COMPLUS_InstallRoot = ""
    $env:COMPLUS_Version = ""
    $output = & $filePath $arg1
    $env:COMPLUS_InstallRoot = $a1
    $env:COMPLUS_Version = $a2

    return $output
}

# Returns the manifest information for a particular file 
function script:Get-Manifest() { 
    param ( [string]$filePath = $(throw "Need a file") )

    $p = join-path $env:tmp "PrintManifest.exe"
    if ( -not (test-path $p) ) {
        copy (join-path $scriptPath "PrintManifest.exe") $p
    }
    $output = Run-Managed $p $filePath 
    return $output[1]
}

# Get the depedency list from a binary manifest
function script:Get-ManifestDependency()  {
    param ( [string]$filePath = $(throw "Need a file") )
    
    $raw = Get-Manifest $filePath
    write-debug $raw
    [xml]$manifest = $raw
    if ( $manifest -eq $null ) { 
        write-host -f red "Could not find a manifest for: $filePath"
        return
    }

    foreach ( $i in $manifest.assembly.dependency ) { 
        new-dependency $i.get_innerXml() 
    }
}

# The version of visual studio much match the version of the CRT we are 
# using in public
function script:Get-PublicCrtVersion() {
    $p = join-path $env:depotroot public\internal\vctools\crt\bin\i386\
    $p = join-path $p "Microsoft.VC100.CRT.manifest"
    [xml]$m = gc $p

    return (new-object Version $m.assembly.assemblyIdentity.version)
}

# Look for the installed versions of the CRT based on the file system.  Reports
# back all of the found versions
function script:Load-InstalledCrtVersionsFileSystem() { 
    $p = join-path $env:windir "winsxs"
    if ( -not (test-path $p) ) {
        write-host -f red "Could not find the SxS directory:" $p
        return @()
    }

    pushd $p
    $list = gci x86_microsoft.vc100.crt*
    foreach ( $d in $list ) {  
        write-debug "Considering $d"
        $v = $d.Name.Split("_")[3]
        write-output (new-object Version $v)
    }
    popd
}

# Look for installed versions of the CRT.  Report back all of the found 
# versions
function script:Load-InstalledCrtVersions() { 
    trap [Exception] {
        write-host -f yellow "WMI not available, searching file system"
        $list = Load-InstalledCrtVersionsFileSystem
        $script:crtList = @( $list )
        return
    }

    $list = get-wmiobject Win32_Product |
        ?{ $_.Name -like "*C++*" } |
        %{ new-object Version $_.Version }
    $script:crtList = @( $list )
}

# Look for all of the binding re-direct information.  This is used to map around 
# various versions of the CRT.
# TODO: Filter out redirects which don't point to a valid version
function script:Load-CrtBindingRedirect() {
    $isVista = [Environment]::OsVersion.Version.Major -gt 5
    if ( $isVista ){ 
        pushd (join-path $env:WinDir "winsxs\manifests")
        $list = gci x86_policy.10.0.microsoft.vc100.*crt*manifest 
        popd
    } else {
        pushd (join-path $env:WinDir "winsxs\policies")
        $list = gci x86_policy.10.0.microsoft.vc100.*crt* | 
            %{ gci $_ -re -in *.policy }
        popd
    }

    foreach ( $f in $list ) { 
        if ( $f -eq $null ) {
            continue;
        }

        write-debug "Considering $f"
        $m = [xml](gc $f)
        foreach ( $d in $m.assembly.dependency ) {
            write-debug $d.get_innerxml()
            $o = new-dependency $d.get_innerxml()
            if ( $o.AssemblyName -like "Microsoft.VC100.*CRT" -and $o.HasRedirect ) {
                $script:redirectList = @( $redirectList + $o )
            }
        }
    }
          
}

# Get the list of binaries to scan
function script:Get-BinaryList() { 

    #devenv 
    $vspath = join-path $env:ProgramFiles "Microsoft Visual Studio 10.0"
    $idePath= join-path $vspath "Common7\IDE"

    write-output (join-path $idePath "devenv.exe")
    write-output (join-path $idePath "msvb7.dll")
    write-output (join-path $idePath "msvbide.dll")
    write-output (join-path $vsPath "VC#\VCSPackages\cslangsvc.dll")
    write-output (join-path $vsPath "Common7\Packages\Debugger\cscompee.dll")
}

function script:Load-BinaryList() {
    function Load-Single() { 
        param ([string]$filePath) 
        if ( -not (test-path $filePath) ) {
            write-host -f red "Binary missing: $filePath"
            return
        }
        $dep = Get-ManifestDependency $filePath
        $name = split-path -leaf $filePath
        new-tuple "Name",$name,"FilePath",$filePath,"DependencyList",$dep
    }
    function Load-Impl() { 
        Get-BinaryList | %{ Load-Single $_ }
    }

    function Load-VsAssert() {
        $needed = $false
        foreach ( $dep in ($script:binList |%{$_.DependencyList} )) {
            if ($dep.IsDebugCrt) { 
                $needed = $true
            }
        }

        if ( $needed ) { 
            write-debug "Vsassert needed"
            $p = join-path $env:WinDir "System32\vsassert.dll"
            Load-Single $p
        } 
    }

    $script:binList += Load-Impl
    $script:binList += Load-VsAssert
}

function script:Check-CrtDependency() {
    param ( [string]$version = "Need a version string" )

    $v = new-object Version $version
    foreach ( $crt in $script:crtList ) { 
        if ( $crt -eq $v ) {
            write-debug "Satisfied by CRT $crt"
            return $true
        }
    }

    foreach ( $r in $script:redirectList ) { 
        $can = $r.CanRedirect($v)
        if ( $can ) {
            write-debug ("Satisfied by Redirect {0} => {1}" -f $r.OldRedirect,$r.NewRedirect )
            return $true
        }
    }

    return $false
}

function script:Check-BinaryList() {
    write-host "Checking Binaries"
    foreach ( $bin in $script:binList ) { 
        write-host "`t$($bin.Name)"
        foreach ( $dep in ($bin.DependencyList | ?{$_.IsCrt} )) {
            write-debug "Checking $dep"
            if ( -not (Check-CrtDependency $dep.AssemblyVersion ) ) { 
                write-host -f red "CRT dependency not met (needs for $($dep.AssemblyVersion))"
            }
        }
    }
}

function script:Check-Publics() { 
    write-host "Checking CRT in public's" 
    $p = join-path $env:DepotRoot public\internal\vctools\crt\bin\i386
    $p = join-path $p "Microsoft.VC100.CRT.Manifest"
    $m = [xml](gc $p)
    $v = $m.assembly.assemblyIdentity.version
    write-host "`t$v"
    if ( -not (Check-CrtDependency $v) ) {
        write-host -f red "CRT version in publics is $v which is not compatible with installed version on machine"
        Resolve-Public
    }
}

function script:Resolve-Public() { 
    function script:Sync-Public() {
        pushd $env:depotroot 
        $d = Get-CrtVersionDate
        write-host "Syncinc to $d"
        & tf get public /r /v:D$d
        popd
    }
    # Redist is located here \\cpvsbuild\drops\dev10\vs_langs01\layouts\x86ret\10529.00\enu\vc\red\sfx\vcredist_x86.exe
    function script:Install-Crt() { 
        $version = @($script:crtList)[0]
        $format = "\\cpvsbuild\drops\dev10\{0}\layouts\x86ret\{1}.00\enu\vc\red\sfx\vcredist_x86.exe"
        $url = $format -f $env:BranchName,$version.Build

        write-host "Installing $url"
        if ( -not ( test-path $url ) ) {
            write-host -f red "Cannot find exe.  Build must be deleted"
            return $false
        }

        & $url
        return $true
    }
    
    write-host "Options for resolving bad CRT versions in public"
    write-host " 1) Sync publics to correct CRT.  Will require a rebuild and re-install of binaries"
    write-host " 2) Install the CRT which matches publics.  May not work if drop is deleted."
    write-host " 3) Ignore"

    $done = $false
    while ( -not $done ) {
        $done = $true
        switch (read-host "Choice? " ) {
            "1" { Sync-Public; break; }
            "2" { $done = Install-Crt; break; }
            "3" { break; }
            default { 
                write-host "Enter a valid choice"
                $done = false
            }
        }
    }
}

function script:Do-Work() {

    write-host -noNewLine "Searching for installed CRT ... "
    Load-InstalledCrtVersions
    write-host ("found {0}" -f $script:crtList.Length)
    foreach ( $ver in $crtList ) {
        write-host "`t$ver"
    }

    write-host -noNewLine "Searching for binding redirect ... "
    Load-CrtBindingRedirect
    write-host "found $($redirectList.Count)"
    foreach ( $r in $redirectList ) {
        write-host ("`t{0} => {1}" -f $r.OldRedirect,$r.NewRedirect)
    }

    write-host "Loading binary information"
    Load-BinaryList
    Check-BinaryList
    Check-Publics
}

if ( -not (test-path env:\RazzleToolPath ) ) {
    write-host "Please run this under a razzle window"
    return
}

Do-Work

$script:scriptPath = split-path $MyInvocation.MyCommand.Definition 

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

# Find the installed version of visual studio
function script:Find-VisualStudio() {
    $p = $env:ProgramFiles
    $p = join-path $p "Microsoft Visual Studio 10.0"
    $p = join-path $p "Common7\IDE\devenv.exe"
    return $p;
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

function script:Get-CrtVersionDependency() {
    param ( [string]$filePath = $(throw "Need a file") )

    $manifest = [xml](Get-Manifest $filePath)
    write-debug "Searching manifest for $filePath" 
    foreach ( $i in $manifest.assembly.dependency ) {
        write-debug $i.get_innerxml()
        $ident = $i.dependentAssembly.assemblyIdentity
        if ( $ident.name -eq "Microsoft.VC100.CRT") {
            return (new-object Version $ident.version)
        }
    }

    write-error "Could not find a CRT dependency for $filePath"
    return ""
}

# The version of visual studio much match the version of the CRT we are 
# using in public
function script:Get-PublicCrtVersion() {
    $p = join-path $env:depotroot public\internal\vctools\crt\bin\i386\
    $p = join-path $p "Microsoft.VC100.CRT.manifest"
    [xml]$m = gc $p

    return (new-object Version $m.assembly.assemblyIdentity.version)
}

# Look for installed versions of the CRT.  Report back all of the found 
# versions
function script:Get-InstalledCrtVersions() { 
    $list = get-wmiobject Win32_Product |
        ?{ $_.Name -like "*C++*" } |
        %{ new-object Version $_.Version }
    return $list
}

# Look for all of the binding re-direct information.  This is used to map around 
# various versions of the CRT.
function script:Find-CrtBindingRedirect() {
    $p = join-path env:WinDir "winsxs\manifests"
    if ( -not (test-path $p) ) {
        write-error "Could not find the SxS manifests directory: $p"
    }

     
}

function script:Do-Work() {
    $vsPath = Find-VisualStudio
    if ( -not (test-path $vsPath) ) { 
        write-error "Could not find Visual Studio at $vsPath.  Exiting"
        return
    }

    $neededCrt = Get-CrtVersionDependency $vsPath
    write-host "Visual Studio Crt Dependency: $neededCrt"

    $publicCrt = Get-PublicCrtVersion 
    write-host "Public Crt Version: $publicCrt"

    $crtList = Get-InstalledCrtVersions
    write-host "Installed Crt Count: $($crtList.Count)"
    foreach ( $ver in $crtList ) {
        write-host "`t$ver"
    }
}

if ( -not (test-path env:\RazzleToolPath ) ) {
    write-error "Please run this under a razzle window"
    return
}

Do-Work

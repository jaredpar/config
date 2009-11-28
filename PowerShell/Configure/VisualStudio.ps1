# Configure Visual Studio to use our stored settings files 

if ( $Jsh.IsTestMachine ) {
    return
}

$pathList = 
    "hkcu:\software\Microsoft\VisualStudio\8.0",
    "hkcu:\software\Microsoft\VisualStudio\9.0",
    "hkcu:\software\Microsoft\VisualStudio\10.0",
    "hkcu:\software\Microsoft\Rascal\8.0"

pushd $(join-path $Jsh.ConfigPath "data\VisualStudio")

foreach ( $path in $pathList ) {
    if ( -not (test-path $path)) {
        continue;
    }

    write-host "Updating settings list $path"
    foreach ( $file in (dir *.vssettings)) {
        $browsePath = join-path $path "Profile"
        if ( -not (test-path $browsePath)) {
            mkdir $browsePath
        }

        $browsePath = join-path $browsePath "BrowseFiles"
        if ( -not (test-path $browsePath)) {
            mkdir $browsePath
        }

        sp $browsePath $file.FullName ([int]1)
    }
}
popd

write-host "Updating Snippets"
pushd $(join-path $Jsh.ConfigPath "data\snippets\CSharp")
$versionList = 
    "Visual Studio 2005",
    "Visual Studio 2008",
    "Visual Studio Codename Orcas"
$snippetBasePath = [Environment]::GetFolderPath("Personal")
foreach ( $version in $versionList ) {
    $snippetPath = join-path $snippetBasePath $version
    $snippetPath = join-path $snippetPath "\Code Snippets\Visual C#\My code Snippets"
    if ( -not (test-path $snippetPath) ) {
        continue;
    }

    write-host "`tUpdating snippets for $version" 
    foreach ( $path in $(dir *.snippet) ) {
        $target = join-path $snippetPath $path.Name
        copy --force $path.FullName $target
    }
}

popd


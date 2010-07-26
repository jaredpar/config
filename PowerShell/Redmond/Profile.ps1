

$script:sPath = split-path -parent $MyInvocation.MyCommand.Definition 
$Jsh.ScriptMap["redmond"] = join-path $sPath "LibraryRedmond.ps1"
$Jsh.ScriptMap["sd"] = join-path $sPath "LibrarySourceDepot.ps1"
$Jsh.ScriptMap["midori"] = join-path $sPath "LibraryMidori.ps1"
$Jsh.ScriptMap["msharp"] = join-path $sPath "LibraryMSharp.ps1"

. script redmond


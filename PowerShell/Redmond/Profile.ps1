

$script:sPath = split-path -parent $MyInvocation.MyCommand.Definition 
$Jsh.ScriptMap["redmond"] = join-path $sPath "LibraryRedmond.ps1"
$Jsh.ScriptMap["sd"] = join-path $sPath "LibrarySourceDepot.ps1"

. script redmond


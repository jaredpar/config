#==============================================================================
#
# Script to pin applications to the Windows 7 taskbar.  This script is a modified
# version of the one blogged about by ragnar here
# 
# http://blog.crayon.no/blogs/ragnar/archive/2009/04/17/pin-applications-to-windows-7-taskbar.aspx
#
#==============================================================================
param ([string]$fileArg = $(throw "Need a file to pin") )

$fileFullName = resolve-path $fileArg
$fileName = split-path -leaf $fileFullName
$fileDir = split-path -parent $fileFullName
$shell = new-object -com "Shell.Application" 
$folder = $shell.Namespace($fileDir) 
$item = $folder.ParseName($fileName)
$PinVerb="Pin to Taskbar" 
foreach($v in $item.Verbs()) {
    if($v.Name.Replace("&","") -match $PinVerb){
        $v.DoIt() 
    }
}


$initPath = split-path -parent $MyInvocation.MyCommand.Definition 
$target = "\\vbqafiles\public\jaredpar\InitMachine"
if ( -not (test-path $target) ) {
    mkdir $target
}

copy -r -force -exclude ".svn","Deploy.ps1" * $target
copy -force $Jsh.ScriptMap["common"] $target

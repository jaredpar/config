$initPath = split-path -parent $MyInvocation.MyCommand.Definition 
$target = "\\vbqafiles\public\jaredpar\HyperV"
if ( -not (test-path $target) ) {
    mkdir $target
}

copy -r -force -exclude ".svn" * $target

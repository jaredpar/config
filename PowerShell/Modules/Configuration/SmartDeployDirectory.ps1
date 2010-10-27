#==============================================================================
#
# Script to deploy an application directory onto my machine.  Won't copy files
# which are identical
#
#==============================================================================
param ( [string]$source = $(throw "Need a source directory") ,
        [string]$dest = $(throw "Need a destination directory") )

if ( -not (test-path $dest ) ) { 
    mkdir $dest | out-null
}

foreach ( $sourceFile in gci $source ) {
    $sourceFile = join-path $source $sourceFile
    $destFile = join-path $dest (split-path -leaf $sourceFile);
    $needCopy = $true
    if ( test-path $destFile ) { 
        $sourceCheckSum = Get-Md5 $sourceFile
        $destCheckSum = Get-Md5 $destFile
        if ( $sourceCheckSum -eq $destCheckSum ) { 
            $needCopy = $false
        }
    }

    if ( $needCopy ) {
        copy -force $sourceFile $destFile 
    }
}


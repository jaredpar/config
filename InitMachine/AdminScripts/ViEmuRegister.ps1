
$script:targetDir = join-path (Get-ProgramFiles32) "ViEmu"
$script:targetFile = join-path $targetDir "RegKey.dat"
$script:sourceFile = join-path $jsh.ConfigPath "Data\Regkey.dat"

$check = $args[0]
if ( $check -eq "check" )
{
    if ( -not ( test-path $targetDir ) )
    {
        return $false;
    }

    return -not (test-path $targetFile);
}

copy -force $sourceFile $targetFile


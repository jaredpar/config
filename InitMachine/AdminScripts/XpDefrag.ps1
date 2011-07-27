$script:title = "Xp Regular Degrag"

$check = $args[0]
if ( $check -eq "check" ) {

    # Only needs to run on XP
    if ( 5 -ne [Environment]::OsVersion.Version.Major ) {
        return $false;
    }

    $found = schtasks /query | ?{ $_ -match "^\w*$title" } | test-any
    return (-not $found )
}

# Set up the defrag task
$task = "{0} {1}" -f (join-path $env:WinDir "System32\defrag.exe"),$env:SystemDrive
schtasks /create /ru system /tn $title /sc daily /st "01:00:00" /tr $task



$name = "\jaredpar\winconfig\pull"
echo "Creating the logon task to pull git"

# Delete the existing task
schtasks /query /tn $name | out-null
if ( $lastexitcode -eq 0 ) { 
    schtasks /delete /tn $name
}

$target = resolve-path "PullTask.cmd"
$cmd = "{0} /c {1}" -f $env:COMSPEC,$target
schtasks /create /sc DAILY /tn $name /TR $cmd


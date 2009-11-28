
# Copy over the RSA keys into the appropriate location for programs like GIT
# to pick them up
echo "Setting up SSH key"
$dataPath = join-path $Jsh.ConfigPath "Data"
$target = join-path $env:UserProfile ".ssh"
if ( -not (test-path $target)) {
    mkdir $target | out-null
}
copy -re -fo (join-path $dataPath "ssh\*") $target


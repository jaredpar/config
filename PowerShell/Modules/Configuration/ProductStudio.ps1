

# Set the search path of Product Studio to look at my query location
echo "Updating Product Studio search path"

$target = "hkcu:\software\microsoft\product studio\files"
if ( test-path $target )
{
    pushd $target
    sp . -Name SearchPath -Value "\\vb\public\jaredpar\Query"
    popd
}


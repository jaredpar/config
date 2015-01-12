
# Add the _vimrc file to the %HOME% path which just calls the real 
# one I have in data\vim
echo "Generating a _vimrc"
$dataDir = join-path (split-path -parent (split-path -parent $PSScriptRoot)) "Data"
$vimDir = join-path $dataDir "vim"
$realPath = resolve-path (join-path $vimDir "_vimrc")
$vimrcPath = join-path $env:UserProfile "_vimrc"
echo ":source $realPath" | out-file -encoding ASCII $vimrcPath

echo "Copying VimFiles" 
$source = join-path $vimDir "vimfiles"
copy -re -fo $source $env:UserProfile


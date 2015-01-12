
# Add the _vimrc file to the %HOME% path which just calls the real 
# one I have in data\vim
$dataDir = join-path (split-path -parent (split-path -parent $PSScriptRoot)) "Data"

# Generate _vimrc which calls the real one 
echo "Generating a _vimrc"
$realPath = resolve-path (join-path $dataDir "_vimrc")
$sourcePath = join-path $env:UserProfile "_vimrc"
echo ":source $realPath" | out-file -encoding ASCII $sourcePath

# Generate _vsvimrc which calls the real one 
echo "Generating a _vsvimrc"
$realPath = resolve-path (join-path $dataDir "_vsvimrc")
$sourcePath = join-path $env:UserProfile "_vsvimrc"
echo ":source $realPath" | out-file -encoding ASCII $sourcePath

echo "Copying VimFiles" 
$source = join-path $dataDir "vim\vimfiles"
copy -re -fo $source $env:UserProfile


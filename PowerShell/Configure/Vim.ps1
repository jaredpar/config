
# Add the _vimrc file to the %HOME% path which just calls the real 
# one I have in data\vim
echo "Generating a _vimrc"
$realPath = resolve-path (join-path $Jsh.ConfigPath "data\vim\_vimrc")
$vimrcPath = join-path $env:UserProfile "_vimrc"
echo ":source $realPath" | out-file -encoding ASCII $vimrcPath

echo "Copying VimFiles" 
$source = join-path $Jsh.ConfigPath "data\vim\vimfiles"
copy -re -fo $source $env:UserProfile

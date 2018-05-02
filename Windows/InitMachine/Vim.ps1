
# Add the _vimrc file to the %HOME% path which just calls the real 
# one I have in data\vim
$dataDir = Join-Path (Split-Path -parent (Split-Path -parent $PSScriptRoot)) "Data"

# Generate _vimrc which calls the real one 
Write-Host "Generating a _vimrc"
$realPath = resolve-path (Join-Path $dataDir "_vimrc")
$sourcePath = Join-Path $env:UserProfile "_vimrc"
Write-Output ":source $realPath" | Out-File -encoding ASCII $sourcePath

# Generate _vsvimrc which calls the real one 
Write-Host "Generating a _vsvimrc"
$realPath = resolve-path (Join-Path $dataDir "_vsvimrc")
$sourcePath = Join-Path $env:UserProfile "_vsvimrc"
Write-Output ":source $realPath" | Out-File -encoding ASCII $sourcePath

Write-Host "Copying VimFiles" 
$source = Join-Path $dataDir "vim\vimfiles"
Copy-Item -re -fo $source $env:UserProfile


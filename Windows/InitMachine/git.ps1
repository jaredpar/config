

# Setup the standard user info.
Write-Host "Configuring Git"
$vimFilePath = "C:\Program Files (x86)\Vim\vim80\vim.exe"
$gitEditor = if (Test-Path $vimFilePath) { $vimFilePath } else { "notepad.exe" }
& git config --global core.editor "'$vimPath'"
& git config --global user.name "Jared Parsons"
& git config --global user.email "jaredpparsons@gmail.com"

# Setup signing policy.
$gpgFilePath = "C:\Program Files (x86)\GnuPG\bin\gpg.exe"
if (Test-Path $gpgFilePath) { 
    Write-Host "Configuring GPG"
    & git config --global gpg.program "$gpgFilePath"     
    & git config --global commit.gpgsign true
    & git config --global user.signkey 06EDAA3E3C0AF8841559
}
else { 
    Write-Host "Skipped configuring GPG as it's not found $gpgFilePath"
}


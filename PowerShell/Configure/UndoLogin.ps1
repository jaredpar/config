
# Previously I set my machine to auto-update when I logged in.  This can really kill 
# startup time as updating requires connecting to the internet.  On my laptop where 
# I frequently login this is a real pain.  
#
# In addition to not adding the login script I also need to delete the previous 
# occurances of the script.  That is the function of this configuration entry

pushd hkcu:\Software\Microsoft\Windows\CurrentVersion\Run
remove-itemproperty -path . -name LoginScript -errorAction SilentlyContinue
popd


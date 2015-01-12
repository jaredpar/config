
# Set the %HOME% environment variable so that Unix Tools will know
# where to look for their files

echo "Updating %HOME% for Unix Tools"

# Broadcasting environment variables can be expensive and slow down the 
# startup so check here to make sure it's not already properly set
$homePath = $env:UserProfile
$curVal = $env:HOME
if ( $curVal -ne $homePath )
{
    & .\envset.exe /u HOME=$homePath
    sc env:\HOME $homePath
}

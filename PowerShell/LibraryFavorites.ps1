$script:favoritesDataFile = join-path $Jsh.ConfigPath "Data\favorites.xml"

# Create a favorite based on the link information
function Create-Favorite($link)
{
    pushd $([Environment]::GetFolderPath("Favorites"))
    if ( $link.Path -ne "" )
    {
        if ( -not (test-path $link.Path) )
        {
            mkdir $link.Path
        }

        pushd $link.Path
    }
    
    $lines = $link.Content.Split(" ")
    sc $link.Name $lines

    if ( $link.Path -ne "" )
    {
        popd
    }
    popd
}

# Force the Favorites to be the contents of the xml file
function Load-Favorites()
{
    pushd $([Environment]::GetFolderPath("Favorites"))

    [xml]$data = gc $favoritesDataFile
    echo $data.favorites
    foreach ($link in $data.favorites.Link )
    {
        Create-Favorite $link
    }

    popd
}

# Store the current favorites in an xml file
function Save-Favorites()
{
    $favPath = [Environment]::GetFolderPath("Favorites")
    pushd $favPath 

    [xml]$doc = "<favorites><header/></favorites>"
    foreach ( $file in (dir -recurse -filter "*.url"))
    {
        [xml] $subDoc = 
@'
            <Link>
                <Path>null</Path>
                <Name>null</Name>
                <Content>null</Content>
            </Link>
'@ 
        if ( $file.Directoryname -eq $favPath )
        {
            $subDoc.Link.Path = ""
        }
        else
        {
            $subDoc.Link.Path = $file.DirectoryName.SubString($favPath.Length+1)
        }
        $subDoc.Link.Name = [IO.Path]::GetFileName($file.FullName)
        $subDoc.Link.Content = [string]$(gc $file.FullName)

        $node = $doc.ImportNode($subDoc.Link, $true)
        $doc.favorites.AppendChild($node)
    }

    popd

    $doc.Save($favoritesDataFile)
}


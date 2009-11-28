
function Registry.Search-SingleKey($key, [scriptblock] $sb)
{
    write-debug "Processing Key $($key.PSPath)"
    $rawProp = gp $key.PsPath 
    if ( $rawProp -eq $null )
    {
        return;
    }

    foreach ($prop in $rawProp.psobject.Properties)
    {
        if ( $prop.Name -like "PS*" )
        {
            continue;
        }

        write-debug "Processing Value $($prop.Name)=$($prop.Value)"
        $found = & $sb $prop
        if ( $found  )
        {
            write-debug "Found $($prop.Name)"
            $obj = new-object psobject
            add-member -in $obj -type NoteProperty -name "Name" -value ($prop.Name)
            add-member -in $obj -type NoteProperty -name "Value" -value ($prop.Value)
            add-member -in $obj -type NoteProperty -name "Property" -value $prop 
            add-member -in $obj -type NoteProperty -name "Key" -value $key
            $obj
        }
    }
}

function Registry.Search-ValueCore()
{
    param ( [string] $root=".",
            [scriptblock] $sb = $(throw "Need a script block"),
            [bool] $recurse ) 

    Registry.Search-SingleKey $(gi $root) $sb
    if ( $recurse )
    {
        foreach ( $child in (gci -recurse $root -ea SilentlyContinue))
        {
            Registry.Search-SingleKey $child $sb
        }
    }
}

function Registry.Search-KeyCore()
{
    param ( [string]$root, [bool] $recurse, [scriptblock] $sb );
    
    $key = gi $root
    if ( $key -eq $null )
    {
        return;
    }

    write-debug "Processing $($key.Name)"
    if ( (& $sb $key) )
    {
        $key
    }

    if ( $recurse )
    {
        foreach ( $child in (gci -recurse $root -ea SilentlyContinue))
        {
            write-debug "Processing $($child.Name)"
            if ( & $sb $child )
            {
                $child
            }
        }
    }
}


function Select-All()
{
    param ( [string] $target = $(throw "Please specify a target to -like against"), 
            [string] $root = ".", 
            [switch] $recurse )

    if ( $recurse )
    {
        Select-Key $target $root -recurse
        Select-Value $target $root -recurse
    }
    else
    {
        Select-Key $target $root 
        Select-Value $target $root
    }
}

function Match-All()
{
    param ( [string] $target = $(throw "Please specify a target to -match against"), 
            [string] $root = ".", 
            [switch] $recurse )

    if ( $recurse )
    {
        Match-Key $target $root -recurse
        Match-Value $target $root -recurse
    }
    else
    {
        Match-Key $target $root 
        Match-Value $target $root
    }
}


function Select-Value()
{
    param ( [string] $target = $(throw "Please specify a target to -like against"), 
            [string] $root = ".", 
            [switch] $recurse )

    $block = {
        param ($prop)
        write-debug "Target=$target Name=$($prop.name) Value=$($prop.Value)"
        if ( ($prop.Value -like $target) -or ($prop.Name -like $target) )
        {
            $prop
        }
    }
        
    Registry.Search-ValueCore $root $block $recurse    
}

function Match-Value()
{
    param ( [string] $target = $(throw "Please specify a target to -like against"), 
            [string] $root = ".", 
            [switch] $recurse )

    $block = {
        param ($prop)
        write-debug "Target=$target Name=$($prop.name) Value=$($prop.Value)"
        if ( ($prop.Value -match $target) -or ($prop.Name -match $target) )
        {
            $prop
        }
    }
        
    Registry.Search-ValueCore $root $block $recurse
}

function Select-Key()
{
    param ( [string] $target = $(throw "Please specify a target to -like against"), 
            [string] $root = ".", 
            [switch] $recurse )

    $block = {
        param ($key)
        write-debug "Key=$($key.Name)"
        return $key.Name -like $target }
    Registry.Search-KeyCore $root $recurse $block 
}

function Match-Key()
{
    param ( [string] $target = $(throw "Please specify a target to -match against"), 
            [string] $root = ".", 
            [switch] $recurse )

    $block = {
        param ($key)
        write-debug "Key=$($key.Name)"
        return $key.Name -match $target }
    Registry.Search-KeyCore $root $recurse $block 
}

function Test-ItemProperty() {
    param ( [string]$path = $(throw "Need a path"),
            [string]$name = $(throw "Need a name") )

    $temp = $null
    $temp = Get-ItemProperty -path $path -name $name -errorAction SilentlyContinue
    return $temp -ne $null
}


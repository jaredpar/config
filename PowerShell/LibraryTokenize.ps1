##==============================================================================
# Jared Parsons 
# Tokenize Library
#
# Handy set of functions for tokenizing files
#==============================================================================

function New-Token()
{
    param ( [string]$value = $(throw "Specify a value"),
            [string]$kind = $(throw "Specify a kind") )

    $token = new-object psobject
    $token | add-member NoteProperty "Value" $value
    $token | add-member NoteProperty "Kind" $kind
    return $token
}

# Tokenize the most basic items
function Tokenize-Basic()
{
    param ( [string]$text = $(throw "Please specify text to tokenize") )
    function PipeStringChar()
    {
        param ( [string]$toPipe )
        for ( $i = 0; $i -lt $toPipe.Length; $i++ )
        {
            write-output $toPipe[$i]
        }
    }

    PipeStringChar $text | ConvertTo-Basic
}

# Get the token stream for every line in a file
function Get-Token()
{
    param ( $fileName = $(throw "Please specify a file") )
    $path = resolve-path $fileName
    Tokenize-Basic ([IO.File]::ReadAllText($path))
}

# Converts a stream of characters into the most basic tokens
#   Character
#   Whitespace
#   NewLine
function ConvertTo-Basic()
{
    begin
    {
        $stateNone = 0
        $stateSpace = 1
        $stateCariageReturn = 2
        $state = $stateNone
        $saved = ""
    }

    process
    {
        [char]$cur = $_ 

        if ( $state -eq $stateSpace )
        {
            if ( [Char]::IsWhitespace($cur) )
            {
                $saved += $cur
                return
            }
            else
            {
                write-output (New-Token $saved "Whitespace")
                $state = $stateNone
            }
        }
        elseif ( $state -eq $stateCariageReturn )
        {
            if ( $cur -eq "`n" )
            {
                $saved += $cur
                write-output (New-Token $saved "Newline")
                $state = $stateNone
                return
            }
            else
            {
                write-output (New-Token $saved "Newline")
                $state = $stateNone
            }
        }

        if ( $stateNone -eq $state )
        {
            if ( $cur -eq "`r" )
            {
                $saved = $cur
                $state = $stateCariageReturn
            }
            elseif ( $cur -eq "`n" )
            {
                write-output (New-Token $cur "Newline")
            }
            elseif ( [Char]::IsWhitespace($cur) )
            {
                $saved = $cur
                $state = $stateSpace
            }
            else
            {
                write-output (New-Token $cur "Character")
            }
        }
    }

    end
    {
        if ( $state -eq $stateSpace )
        {
            write-output (New-Token $saved "Whitespace")
        }
        elseif ( $state -eq $stateCariageReturn )
        {
            write-output (New-Token $saved "Newline")
        }
        elseif ( $stateNone -ne $state )
        {
            throw "Invalid State: $state"
        }
    }
}

# Look for sequence of characters in the stream and convert them into words
function ConvertTo-Word()
{
    begin
    {
        $saved = ""
        $inWord = $false
    }

    process
    {
        $cur = $_
        $isLetter = ($cur.Kind -eq "Character") -and ([Char]::IsLetter([char]$cur.Value))
        if ( $isLetter )
        {
            $saved += $cur.Value
            $inWord = $true
        }
        elseif ( $inWord )
        {
            write-output (New-Token $saved "Word")
            write-output $cur
            $inWord = $false
            $saved = ""
        }
        else
        {
            write-output $cur
        }
    }

    end
    {
        if ( $inWord )
        {
            write-output (New-Token $saved "Word")
        }
    }
}

function ConvertTo-Number()
{
    begin
    {
        $saved = ""
        $inNumber = $false
    }

    process
    {
        $cur = $_
        $isDigit = ($cur.Kind -eq "Character") -and ([Char]::IsDigit([char]$cur.Value))
        if ( $isDigit )
        {
            $saved += $cur.Value
            $inNumber = $true
        }
        elseif ( $inNumber )
        {
            write-output (New-Token $saved "Number")
            write-output $cur
            $inNumber = $false
            $saved = ""
        }
        else
        {
            write-output $cur
        }
    }

    end
    {
        if ( $inNumber )
        {
            write-output (New-Token $saved "Number")
        }
    }
}

function Tokenize-Text()
{
    param ( [string]$text = $(throw "Please specify text to tokenize") )
    Tokenize-Basic $text | ConvertTo-Word  | ConvertTo-Number
}

# Process the token stream and convert to quoted strings where approriate
function ConvertTo-QuotedString()
{
    begin
    {
        [bool]$inSpace = $true
        [object[]]$saved = @()
    }

    process
    {
        if ( $inSpace )
        {
            if ( $_.Kind -eq "Character" -and $_.Value -eq '"' )
            {
               $saved = $_ 
               $inSpace = $false
            }
            else
            {
                write-output $_
            }
        }
        else
        {
            $saved = $saved + $_
            if ( $_.Kind -eq "Character" -and $_.Value -eq '"' )
            {
                $full = ""
                foreach ( $item in $saved )
                {
                    $full += $item.Value
                }
                write-output (New-Token $full "QuotedString")
                $saved = @()
                $inSpace = $true
            }
        }
    }

    end
    {
        foreach ( $item in $saved )
        {
            write-output $item
        }
    }
}

#==============================================================================
# Start: Cpp Tokens
#==============================================================================
function Tokenize-CppText()
{
    param ( [string]$text = $(throw "Please specify text to tokenize") )
    Tokenize-Basic $text | ConvertTo-Word | ConvertTo-Number | ConvertTo-QuotedString | ConvertTo-CppComments  
}

function ConvertTo-CppComments()
{
    begin
    {
        $cppStateNone = 0
        $cppStateComment = 1
        $cppStateBlockComment = 2
        $cppStateBlockCommentEnd = 3
        $cppStateLineComment = 4

        $state =  $cppStateNone;
        $saved = ""
    }

    process
    {
        $cur = $_
        $value = $cur.Value
        $kind = $cur.Kind

        if ( $state -eq $cppStateNone )
        {
            if ( ($kind -eq "character") -and ($value -eq "/") )
            {
                $saved = $value
                $state = $cppStateComment
            }
            else
            {
                write-output $cur
            }
        }
        elseif ( $state -eq $cppStateComment )
        {
            $saved += $value
            if ( $value -eq "*" )
            {
                $state = $cppStateBlockComment
            }
            elseif ( $value -eq "/" )
            {
                $state = $cppStateLineComment
            }
            else
            {
                throw "Invalid character for comment: $cur"
            }
        }
        elseif ( $state -eq $cppStateBlockComment )
        {
            $saved += $value
            if ( $value -eq "*" )
            {
                $state = $cppStateBlockCommentEnd
            }
        }
        elseif ( $state -eq $cppStateBlockCommentEnd )
        {
            $saved += $value
            if ( $value -eq "*" )
            {
                # Do Nothing.  Still in end state
            }
            elseif ( $value -ne "/" )
            {
                $state = $cppStateBlockComment
            }
            else
            {
                write-output (New-Token $saved "BlockComment")
                $state = $cppStateNone
            }
        }
        elseif ( $state -eq $cppStateLineComment )
        {
            $saved += $value
            if ( $kind -eq "Newline" )
            {
                write-output (New-Token $saved "LineComment")
                $state = $cppStateNone
            }
        }
        else
        {
            throw "Invalid CPP state: $state"
        }
    }

    end
    {
        if ( $state -eq $cppStateLineComment )
        {
            write-output (New-Token $saved "LineComment")
        }
        elseif ($state -ne $cppStateNone )
        {
            throw "Invalid CPP text"
        }
    }
}

function Get-CppToken()
{
    param ( $fileName = $(throw "Please specify a file") )
    $path = resolve-path $fileName
    Tokenize-CppText ([IO.File]::ReadAllText($path))
}

#==============================================================================
# End: Cpp Tokens
#==============================================================================


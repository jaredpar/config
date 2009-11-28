if ($args.Length -eq 0 ) {
    throw "Need an argument"
}

$script:source = $args[0]
$script:dest = [IO.Path]::ChangeExtension($args[0],".vb")
$script:moduleName = [IO.Path]::GetFileNameWithoutExtension($args[0])
$script:moduleName = [Char]::ToUpper($moduleName[0]) + $moduleName.SubString(1)

# Various regexes
$script:regexTypeName = "(?<typename>(const\s+)?(\w+)(\s*\*)?)"

write-debug "Source: $source"
write-debug "Destination: $dest"


#============================================================================
# Skip the specified number of items
#============================================================================
function Skip-Count() {
    param ( $count = $(throw "Need a count") )
    begin { 
        $i = 0
    }
    process {
        if ( $i -ge $count ) { 
            $_
        }
        $i += 1
    }
    end {}
}

#============================================================================
# Skip until the condition is met
#============================================================================
function Skip-Until() {
    param ( $pred = $(throw "Need a predicate") )
    begin {
        $met = $false
    }
    process {
        if ( -not $met ) {
            $met = & $pred $_
        }

        if ( $met ) { 
            $_
        }
    }
    end {}
}


#============================================================================
# Get the text from a comment line
#============================================================================
function Get-CommentText() {
    param ( $comment = $(throw "Need a comment"))
    switch -regex ($comment) {
        "^\s*\/\/\s+(.*)$" { $matches[1] }
        "^\s*'(.*)$" { $matches[1] }
        default { $comment }
    }
}

#============================================================================
# Remove the copyright at the top of the file.  We can add it back later
#============================================================================
function Strip-Copyright() {
    param ([string[]]$lines = $(throw "Need lines") )

    if ($lines[0] -match "\/\/-+" ) {
        $found = 0
        for ( $i = 3 ; $i -lt $lines.Length ; $i++ ) {
            if ( $lines[$i] -match "\/\/.*Copyright" ) {
                $found = $i
                break;
            }
        }

        return ($lines | Skip-Count $found | Skip-Until { -not ($args[0] -match "^\/\/") })
    }

    $lines
}

#============================================================================
# Strip out the #include's
#============================================================================
function Strip-PoundIncludes() {
    begin {}
    process {
        if ( -not ($_ -match "^#include")) {
            $_
        }
    }
    end {}
}

#============================================================================
# Convert all of the block comments which are blocked
# by the === pattern 
#============================================================================
function Convert-BlockCommentEquals() {
    begin {
        $in = $false
    }
    process {
        if ($in -and ($_ -match "^\/\/(=)+") ) {
            $in = $false
            "'''</summary>"
        } elseif ( $in ) {
            "''' {0}" -f (Get-CommentText $_ )
        } elseif ( $_ -match "^\/\/(=)+" ) {
            "'''<summary>"
            $in = $true
        } else { 
            $_
        }
    }
    end {
        if ( $in ) { 
            throw "Mismatched block comments equals"
        }
    }
}

function Convert-LineComments() {
    begin {} 
    process {
        if ( $_ -match "^(.*)\/\/(.*)$" ) {
            "{0}'{1}" -f $matches[1],$matches[2]
        } else {
            $_ 
        }
    }
    end {}
}

#============================================================================
# Strips all un-necessary semi-colons.  Run after comment conversion so we 
# need to look for a VB commentt
#============================================================================
function Strip-Semicolons() {
    begin {}
    process {
        if ( $_ -match "^(.*);\s*$") {
            $matches[1]
        } elseif ( $_ -match "^(.*);(\s*)'(.*)" ) {
            "{0}{1}'{2}" -f $matches[1],$matches[2],$matches[3]
        } else {
            $_ 
        }
    }
    end {}
}

#============================================================================
# Format the return type for a CPP signature.  Make sure it is on a separate 
# line prefixed with R#
#============================================================================
function Format-CppFunctionReturnType() {
    begin {
        $in = $false
        $typename  = ""
    }
    process {
        if ($in) {
            if ( $_ -match "^\s*(\w+)::(\w+)(.*)") {
                write-output "R#$typename"
                write-output $_
            } else {
                write-output $typename
                write-output $_
            }
            $in = $false
        } elseif ($_ -match "^$regexTypeName\s*$" ) {
            $in = $true
            $typename = $matches["typename"]
        } elseif ($_ -match ("^$regextypename\s+(?<rest>(\w+)::(\w+).*)") ) {
            $typename = $matches["typename"]
            $rest = $matches["rest"]
            write-output "R#$typename"
            write-output $rest
        } else {
            write-output $_
        }
    }
    end {}
}

#============================================================================
# Format the method name of a signature
#============================================================================
function Format-CppFunctionName() {
    begin {
        $in = $false
    }
    process {
        if ( $in ) { 
            if ( $_ -match "(\w+)::(\w+)(.*)") {
                write-output ("C#{0}" -f $matches[1])
                write-output ("M#{0}" -f $matches[2])
                write-output $matches[3]
            } else {
                throw "Expected a function body: $_"
            }
            $in = $false
        } elseif ( $_ -match "^R#.*" ) {
            $in = $true
            $_
        } else {
            $_
        }
    }
    end {}
}

#============================================================================
# Format the parens around a function signature
#============================================================================
function Format-CppFunctionParens() {
    begin { 
        $foundStart = $false
        $foundOpen = $false
    }
    process {
        if ( $foundStart ) {
            if ( -not $foundOpen ) {
                if ( $_ -match "^\(([^()]*)\)\s*$" ) { 
                    write-output "PS#"
                    write-output $matches[1]
                    write-output "PE#"
                    $foundStart = $false
                } elseif ( $_ -match "^\((.*)$") {
                    write-output "PS#"
                    write-output $matches[1]
                    $foundOpen = $true
                } elseif ( $_ -match "^\s*$" ) {
                    # Empty line, ignore
                } else {
                    throw "Bad line looking for open paren: $_"
                }
            } else {
                if ( $_ -match "^(.*)\)(.*)$" ) {
                    write-output $matches[1]
                    write-output "PE#"
                    write-output $matches[2]
                    $foundStart = $false
                    $foundOpen = $false
                } else {
                    write-output $_
                }
            }
        } elseif ($_ -match "^M#" ) {
            $_
            $foundStart = $true
        } else {
            $_
        }
    }
    end {
        if ( $foundStart ) { throw "Bad state" }
        if ( $foundOpen ) { throw " Bad state" }
    }
}

#============================================================================
# Move the comments from the parameters
#============================================================================
function Format-CppParamComments() {
    begin { 
        $in = $false
        $comments = @()
    }
    process {
        if ( $in ) { 
            if ( $_ -match "^PE#" ) {
                write-output $_
                if ( $comments.Length -gt 0 ) {
                    write-output $comments
                }
                $in = $false
                $comments = @()
            } elseif ( $_ -match "(.*)'(.*)" ) {
                write-output $matches[1]
                $comments += "' {0}:{1}" -f $matches[1].Trim(),$matches[2]
            }  else {
                $_
            }
        } elseif ( $_ -match "^PS#" ) {
            $_
            $in = $true
        } else {
            $_
        }
    }
    end {
        if ( $in) { throw "Bad state in CppParamComments" }
    }
}

#============================================================================
# Make sure parameters are all on a single line
#============================================================================
function Format-CppParamSingleLine() {
    begin {
        $in = $false
    }
    process {
        if ($in ) {
            if ( $_ -match "^PE#.*$" ) {
                $in = $false
                write-output $_
            } elseif ( $_.Contains(",")) {
                write-output $_.Split(",")
            } else {
                write-output $_
            }
        } elseif ( $_ -match "^PS#.*$" ) {
            $in = $true
            write-output $_
        } else {
            write-output $_
        }
    }
    end {
        if ( $in ) { throw "Bad state CppParamSingleLine" }
    }
}

#============================================================================
# Remove blank lines in the parameter list
#============================================================================
function Format-CppParamBlankLines() {
    begin { 
        $in = $false
    }
    process {
        if ( $in) {
            if ( $_ -match "^\s*$" ) {
                # do nothing
            } elseif ( $_ -match "^PE#" ) {
                $in = $false
                $_
            } else {
                $_
            }
        } elseif ( $_ -match "^PS#" ) {
            $in = $true
            $_
        } else {
            $_
        }
    }
    end { if ( $in ) { throw "Bad state" } }
}

$allLines = gc $source
$output = Strip-Copyright $allLines 
$output | 
    Strip-PoundIncludes | 
    Convert-BlockCommentEquals | 
    Convert-LineComments | 
    Strip-Semicolons |
    Format-CppFunctionReturnType |
    Format-CppFunctionName |
    Format-CppFunctionParens |
    Format-CppParamComments | 
    Format-CppParamSingleLine |
    Format-CppParamBlankLines |
    out-file $dest

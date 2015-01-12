
function TabExpansion()
{
    param ($line, $lastWord)

    function script:Ensure-WildCard
    {
        param ([string]$child)
        
        if ( -not $child.EndsWith(" ") )
        {
            return $child + "*"
        }
        $child
    }

    function script:Get-JshMapMembers
    {
        param ($child,$map)

        write-debug "Get-JshMapMembers $child"
        $child = Ensure-WildCard $child
        $map.Keys | ? { $_ -like $child }
    }

    function script:Get-ExpressionMembers
    {
        param ($exprText, $child)

        write-debug ('Get-ExpressionMembers "{0}" {1}' -f $exprText,$child)
        $child = Ensure-Wildcard $child
        $expr = $null
        Invoke-Expression ('$expr = ' + $exprText)
        if ( $expr -eq $null )
        {
            write-debug "Not a valid expression"
            return $null
        }
        
        write-debug "expr=$expr"
        $expr | gm | ?{ $_.Name -like $child } | %{ "{0}.{1}" -f $exprText,$_.Name} 
    }

    function script:Tab-ScopeChild
    {
        param ($scope, $child)

        write-debug "Tab-ScopeChild $scope $child"

        $drive = get-psdrive $scope -ea SilentlyContinue
        if ( $drive -ne $null )
        {
            $pattern = "{0}*" -f $child
            gci ("{0}:\{1}" -f $scope,$pattern) | %{ '${0}:{1}' -f $scope,$_.Name }
            return
        }
    }

    function script:Do-Expand()
    {
        param ($line, $lastWord)

        [string]$beforeLastWord = $line.SubString(0,$line.Length - $lastWord.Length)
        [string]$prevWord = ""
        if ( $beforeLastWord.Length -gt 0 )
        {
            $all = $beforeLastWord.Split(' ', [StringSplitOptions]"RemoveEmptyEntries")
            $prevWord = $all[$all.Length-1]
        }

        # Diagnostics
        if ( $DebugPreference -ne "SilentlyContinue" )
        {
            write-host ""
        }
        write-debug "line=$line"
        write-debug "lastWord=$lastWord"
        write-debug "beforeLastWord=$beforeLastWord"
        write-debug "prevWord=$prevWord"
 
        # First look at the last word
        switch -regex ( $lastWord )
        {
            '^\$(\w+):(\w+)' { Tab-ScopeChild $matches[1] $matches[2]; break }
            '(\$\w+)\.(\w*)' { Get-ExpressionMembers $matches[1] $matches[2]; break }
            default {

                switch -regex ( $prevWord )
                {
                    "^go(p?)$" { Get-JshMapMembers $lastWord $global:Jsh.GoMap; break; }
                    "^script$" { Get-JshMapMembers $lastWord $global:Jsh.ScriptMap; break; }
                }
            }
        }

        # Now the previous word
    }
    
    & { Do-Expand $line $lastWord }
}


#            # This is the default function to use for tab expansion. It handles
# simple
#            # member expansion on variables, variable name expansion and parame
#ter completion
#            # on commands. It doesn't understand strings so strings containing 
#; | ( or { may
#            # cause expansion to fail.
#
#            param($line, $lastWord)
#
#            & {
#                switch -regex ($lastWord)
#                {
#                    # Handle property and method expansion...
#                    '(^.*)(\$(\w|\.)+)\.(\w*)$' {
#                        $method = [Management.Automation.PSMemberTypes] `
#                            'Method,CodeMethod,ScriptMethod,ParameterizedProper
#ty'
#                        $base = $matches[1]
#                        $expression = $matches[2]
#                        Invoke-Expression ('$val=' + $expression)
#                        $pat = $matches[4] + '*'
#                        Get-Member -inputobject $val $pat | sort membertype,nam
#e |
#                            where { $_.name -notmatch '^[gs]et_'} |
#                            foreach {
#                                if ($_.MemberType -band $method)
#                                {
#                                    # Return a method...
#                                    $base + $expression + '.' + $_.name + '('
#                                }
#                                else {
#                                    # Return a property...
#                                    $base + $expression + '.' + $_.name
#                                }
#                            }
#                        break;
#                    }
#
#
#                    # Handle variable name expansion...
#                    '(^.*\$)(\w+)$' {
#                        $prefix = $matches[1]
#                        $varName = $matches[2]
#                        foreach ($v in Get-Childitem ('variable:' + $varName + 
#'*'))
#                        {
#                            $prefix + $v.name
#                        }
#                        break;
#                    }
#
#                    # Do completion on parameters...
#                    '^-([\w0-9]*)' {
#                        $pat = $matches[1] + '*'
#
#                        # extract the command name from the string
#                        # first split the string into statements and pipeline e
#lements
#                        # This doesn't handle strings however.
#                        $cmdlet = [regex]::Split($line, '[|;]')[-1]
#
#                        #  Extract the trailing unclosed block e.g. ls | foreac
#h { cp
#                        if ($cmdlet -match '\{([^\{\}]*)$')
#                        {
#                            $cmdlet = $matches[1]
#                        }
#
#                        # Extract the longest unclosed parenthetical expression
#...
#                        if ($cmdlet -match '\(([^()]*)$')
#                        {
#                            $cmdlet = $matches[1]
#                        }
#
#                        # take the first space separated token of the remaining
# string
#                        # as the command to look up. Trim any leading or traili
#ng spaces
#                        # so you don't get leading empty elements.
#                        $cmdlet = $cmdlet.Trim().Split()[0]
#
#                        # now get the info object for it...
#                        $cmdlet = @(Get-Command -type 'cmdlet,alias' $cmdlet)[0
#]
#
#                        # loop resolving aliases...
#                        while ($cmdlet.CommandType -eq 'alias') {
#                            $cmdlet = @(Get-Command -type 'cmdlet,alias' $cmdle
#t.Definition)[0]
#                        }
#
#                        # expand the parameter sets and emit the matching eleme
#nts
#                        foreach ($n in $cmdlet.ParameterSets | Select-Object -e
#xpand parameters)
#                        {
#                            $n = $n.name
#                            if ($n -like $pat) { '-' + $n }
#                        }
#                        break;
#                    }
#                }
#            }
#        

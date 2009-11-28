
# Retrieves the svn merge history for location.  Will return an array
# containing the information back
function SvnMergeLog([string]$path=".", [bool]$stopOnCopy=$true)
{
    $list = @()
    $opts = ""
    
    # Update the options if they specified to stop on copies
    if ( $stopOnCopy )
    {
        $opts = "--stop-on-copy"
    }

    $output = [xml](& svn log --xml $opts $path)
    foreach ( $entry in $output.log.logentry)
    {
        if ( $entry.msg -imatch "^\s*(RI|FI)\s+(.+)\s*->\s*([\w\\/\.\d]+)\s*(.*)\s*")
        {
            $item = new-object PSObject
            $item | add-member NoteProperty "Type" $matches[1]
            $item | add-member NoteProperty "Source" $matches[2]
            $item | add-member NoteProperty "Destination" $matches[3]
            $item | add-member NoteProperty "StartRevision" -1
            $item | add-member NoteProperty "EndRevision" -1


            if ( ($item.Type -eq "FI") -or ($item.Type -eq "RI" ))
            {
                # Parse out the version numbers
                $last = $matches[4]
                if ( [String]::IsNullOrEmpty($last) -or $last -match "^\d+$" )
                {
                    # Initial branch copy
                    $item.StartRevision = $entry.Revision
                    $item.EndRevision = $entry.Revision
                }
                elseif ($last -match "\s*(\d+):(\d+).*" )
                {
                    $item.StartRevision = $matches[1]
                    $item.EndRevision = $matches[2]
                }
                else
                {
                    write-host "Could not parse revision numbers: $last"
                    continue
                }
            }
            else
            {
                continue
            }

            # Some branches accidentally used the \ instead of the / in 
            # the comment.  Switch it up to be consistent here
            $fixupbranch = 
            {
                $temp = $args[0]
                if ( $temp -match 'branches\\(.*)' )
                {
                    return "branches/{0}" -f $matches[1]
                }
                else
                {
                    return $args[0]
                }
            }
            $item.Source = &$fixupbranch $item.Source
            $item.Destination = &$fixupbranch $item.Destination

            $list += $item
        }
    }

    return $list
}

# Gets information about the Subversion path.  Determines if it's
# a branch structure or just a normal subversion directory
function SvnPathInfo([string]$path=".")
{
    $info = new-object PSObject
    $rawOutput = &svn info --xml $path
    if ( -not $? )
    {
        return $null
    }

    $output = [xml]$rawOutput
    $entry = $output.info.entry

    # Get the basic information
    $info | add-member NoteProperty "Uri" (new-object Uri $entry.Url)
    $info | add-member NoteProperty "UriRoot" (new-object Uri $entry.repository.Root)
    $info | add-member NoteProperty "RootRevision" $([int]($entry.Revision))
    $info | add-member NoteProperty "CurrentRevision" $([int]($entry.Commit.Revision))

    # Add the relative Uri information
    $rootUriStr = $info.UriRoot.ToString()
    $uriStr = $info.Uri.ToString()
    $uriStr = $uriStr.SubString($rootUriStr.Length)
    if ( $uriStr[0] -eq '/' )
    {
        $uriStr = $uriStr.SubString(1)
    }
    $info | add-member NoteProperty "RelativeUri" $uriStr

    # Add the information for trunk's
    $info | add-member NoteProperty "IsTrunk" ($info.RelativeUri -match ".*/trunk")

    # Add the branch information
    $info | add-member NoteProperty "ShortName" "trunk"
    $info | add-member NoteProperty "IsBranch" $false
    $info | add-member NoteProperty "BranchName" ""
    $info | add-member NoteProperty "TrunkUri" $info.Uri
    $info | add-member NoteProperty "ProjectUri" $info.Uri 
    if ( $info.RelativeUri -match "(.*)/branches/(.*)" )
    {
        $info.IsBranch = $true
        $info.BranchName = "branches/" + $matches[2]
        $info.ShortName = $matches[2]

        $info.ProjectUri = new-object Uri ("{0}/{1}"  -f $info.UriRoot, $matches[1])
        $trunkUriStr = "{0}/{1}/trunk" -f $($info.UriRoot, $matches[1])
        $info.TrunkUri = (new-object Uri $trunkUriStr)
    }
    elseif ( $info.RelativeUri -match "(.*)/trunk" )
    {
        $projectUriStr = "{0}/{1}" -f $info.UriRoot,$matches[1]
        $info.ProjectUri = new-object Uri $projectUriStr
    }
    else
    {
        write-host "Couldn't match URL"
        throw 
    }

    return $info
}

# Performs an reverse integration.  That is branch -> trunk.  Don't call
# this directly.  Instead call svnmerge and let it choose to call this
function _svnmergeri($branchInfo, $trunkInfo, $trunkPath)
{
    write-host $( "Performing RI {0}->trunk" -f $branchInfo.BranchName)

    # Get the merge log
    $mergeLog = svnmergelog $trunkInfo.Uri | 
        ? { $_.Source -ieq $branchInfo.BranchName } |
        sort EndRevision -descending

    # Get the ranges we are merging
    $revStart = -1
    $revEnd = $branchInfo.CurrentRevision

    if ( ($mergeLog -eq $null) -or ($mergeLog.Count -eq 0) ) 
    {
        # This is an initial merge from a child branch.  Find out when 
        # the branch was created
        $branchMergeLog = @( svnmergelog $branchInfo.Uri | ? { $_.Type -eq "FI" } | sort StartRevision )

        # Make sure there was an initial FI that we found
        if ( ($branchMergeLog -eq $null) -or ($branchMergeLog.Count -eq 0) )
        {
            write-host "Could not find the initial FI"
            return
        }

        $initialFi = $branchMergeLog[0]
        $revStart = $initialFi.StartRevision
    }
    else
    {
        $mergeItem = $mergeLog[0]
        $revStart = [int]($mergeItem.EndRevision) + 1
    }

    write-host $("Merging {0}:{1}" -f $($revStart,$revEnd))
    & svn.exe merge -r $("{0}:{1}" -f ($revStart, $revEnd)) $branchInfo.Uri $trunkPath

    # Generate the commit command
    $commitFile = "svn_commit_merge_{0}_{1}.ps1" -f $($revStart, $revEnd)
    write-host "Generating commit file: $commitFile" 
    $cmd = 'svn commit -m "RI {0}->trunk {1}:{2}"' -f $($branchInfo.BranchName,$revStart,$revEnd)
    echo $cmd > $commitFile
}

# Performs a merge forward integration (trunk -> branch).  Don't call this
# directly.
#   $trunkInfo :    Information on the trunk
#   $branchInfo:    Information on the branch
#   $branchPath:    Path to the branch
function _svnmergefi($trunkInfo, $branchInfo, $branchPath)
{
    write-host $( "Performing FI trunk->{0}" -f $branchInfo.BranchName)

    # Get the merge log for the branch.  Look for the last RI into the
    # trunk
    $mergeLog = svnmergelog $branchInfo.Uri |
        ? { $_.Source -eq "trunk" } | 
        ? { $_.Type -eq "FI" } | 
        sort EndRevision -descending

    if ( $mergeLog -eq $null )
    {
        write-host "Could not find any FI's into this branch"
        return
    }

    $targetMerge = $mergeLog[0]

    # Make sure they're not up to date
    if ( $targetMerge.EndRevision -gt $trunkInfo.CurrentRevision )
    {
        write-host "Branch already up to date"
        return
    }

    $revStart = 1 + [int]($targetMerge.EndRevision) 
    $revEnd = $trunkInfo.CurrentRevision
   
    write-host $("Merging {0}:{1}" -f $($revStart, $revEnd))
    & svn.exe merge -r $("{0}:{1}" -f ($revStart, $revEnd)) $trunkInfo.Uri $branchPath

    # Generate the commit command
    $commitFile = "svn_commit_merge_{0}_{1}.ps1" -f $($revStart, $revEnd)
    write-host "Generating commit file: $commitFile" 
    $cmd = 'svn commit -m "FI trunk->{0} {1}:{2}"' -f $($branchInfo.BranchName,$revStart,$revEnd)
    echo $cmd > $commitFile
}

# Do a smart merge operation.  This will look through the integration history
# and perform a merge of only the latest changes
#
#   fromPath: The path to merge from
function SvnMerge([string]$fromPath="", [string]$toPath=".")
{
    if ( $fromPath -eq "" )
    {
        write-host "Must specify a from path"
        return
    }

    $fromInfo = svnpathinfo $fromPath
    $toInfo = svnpathinfo $toPath
    $mergeType = $null

    # First determine the type of merge
    $sourceName = $null
    if ($fromInfo.IsBranch -and $toInfo.IsTrunk )
    {
        # It's an RI
        _svnmergeri $fromInfo $toInfo $toPath
    }
    elseif ($fromInfo.IsTrunk -and $toInfo.IsBranch )
    {
        # It's an FI
        _svnmergefi $fromInfo $toInfo $toPath
    }
    else
    {
        write-host "Error: Unknown integration type!!!"
        return
    }
}

# Branch the trunk 
function SvnBranch([string]$branchName)
{
    if ( [String]::IsNullOrEmpty($branchName))
    {
        write-host "Must provide a branch name"
        return
    }

    $info = SvnPathInfo . 
    if ( -not $info.IsTrunk )
    {
        write-host "Current path is not the trunk"
        return
    }

    $path = "{0}/branches/{1}" -f $info.ProjectUri,$branchName
    & svn copy $($info.TrunkUri) $path -m ("FI trunk->branches/{0}" -f $branchName)
}

# Used to do a "svn delete" on all missing files
function SvnRemoveMissing()
{
    $data = & svn status
    foreach ( $entry in $data )
    {
        if ( $entry -match "^!\s+(.*)$" )
        {
            & svn delete $($matches[1])
        }
    }
}

function _test_svnmergelog()
{
    # Should be able to find the initial FI for branches/0.3
    $log = svnmergelog https://wush.net/svn/jaredp110680/longterm/Library/branches/0.3
    assert (-not ($log -eq $null)) "Didn't get a log back"
    assert ($log.Count -gt 0) "Didn't get a log back"

    # Make sure it picked up the initial FI
    $log1 = $log | sort EndRevision 
    $entry = $log1[0]
    assert_eq 361 $entry.StartRevision "Wrong Initial FI"
    assert_eq $entry.StartRevision $entry.EndRevision "Start and End don't match"

    # Check the trunk
    $log = svnmergelog https://wush.net/svn/jaredp110680/longterm/Library/trunk
    assert (-not ($log -eq $null)) "Didn't get a log back for trunk"
    assert ($log.Count -gt 0) "Didn't get a log back for trunk"
    
    # Make sure we have an RI
    $log1 = $log | ? { $_.Type -eq "RI" } | sort -descending
    assert 317 $log1.EndRevision "Wrong RI info"
    assert 286 $log1.StartRevision "Wrong RI info"
}

if ( $args[0] -eq $true )
{
    # If we're testing then first load in all of the assert functions
    $parent = split-path -parent $MyInvocation.MyCommand.Definition 
    . (join-path $parent "UnitTest.ps1")

    _test_svnmergelog
}
else
{
    # if we're not testing then don't add the test functions 
    del function:\_test_svnmergelog
}


# Copy over the RSA keys into the appropriate location for GIT to pick them up
echo "Setting up SSH key"
$dataPath = join-path $Jsh.ConfigPath "Data"
$target = join-path $env:UserProfile ".ssh"
if ( -not (test-path $target)) {
    mkdir $target | out-null
}
copy -re -fo (join-path $dataPath "ssh\*") $target

# Update the subversion configuration to use our stored one.  Subversion
# still uses %appdata%
#echo "Updating Subversion configuration"
#
#function vimiffound()
#{
#    $vim = get-command "gvim"
#    if ( $vim -ne $null )
#    {
#        return "editor-cmd = " + ($vim.Definition)
#    }
#    else
#    {
#        return ""
#    }
#}
#
## CMD file wrapper to run the windiff program
#$diffWrapperText = 
#    "",
#    "$(join-path $($Jsh.UtilsRawPath) windiff.exe) %6 %7",
#    ""
#$diffWrapperPath = join-path $env:UserProfile WindiffWrapper.cmd
#sc $diffWrapperPath $diffWrapperText
#
## Base configuration
#$configText = 
#    "",
#    "# See http://svnbook.red-bean.com/en/1.1/svn-book.html#svn-ch-7-sect-1 for format",
#    "# !!!Warning!!!: This is a generated file.  ",
#    "[helpers]",
#    "$(vimiffound)", 
#    "diff-cmd = $diffWrapperPath",
#    "",
#    "[miscellany]",
#    "global-ignores=bin *.exe *.dbg *.pcb *.ncb obj TestResults *.swp *.snk *.pdb debug *tags *.user *.suo *.db windows.xml *.msi Debug Release",
#    ""
#
## Install into $env:appdata and $env:localappdata.  XP uses one and
## Vista uses the other
#foreach ( $p in ($env:appdata,$env:localappdata))
#{
#    if ( [String]::IsNullOrEmpty($p)) 
#    {
#        continue;
#    }
#
#    echo "Updating $p"
#    pushd $p
#    if (-not (test-path Subversion))
#    {
#        mkdir Subversion
#    }
#
#    cd Subversion
#    if ( test-path config ) { del config }
#    sc config $configText 
#
#    popd
#}
#
#

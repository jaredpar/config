
$script:libCommonCert = $null
$global:libCommonCertPath = $null

#==============================================================================
# Functions 
#==============================================================================

#==============================================================================
# Start 32/64 Bit functions
#==============================================================================

# Get the path where powershell resides.  If the caller passes -use32 then 
# make sure we are returning back a 32 bit version of powershell regardless
# of the current machine architecture
function Get-PowerShellPath() {
    param ( [switch]$use32=$false,
            [string]$version="1.0" )

    if ( $use32 -and (test-win64machine) ) {
        return (join-path $env:windir "syswow64\WindowsPowerShell\v$version\powershell.exe")
    }

    return (join-path $env:windir "System32\WindowsPowerShell\v$version\powershell.exe")
}


# Is this a Win64 machine regardless of whether or not we are currently 
# running in a 64 bit mode 
function Test-Win64Machine() {
    return test-path (join-path $env:WinDir "SysWow64") 
}

# Is this a Wow64 powershell host
function Test-Wow64() {
    return (Test-Win32) -and (test-path env:\PROCESSOR_ARCHITEW6432)
}

# Is this a 64 bit process
function Test-Win64() {
    return [IntPtr]::size -eq 8
}

# Is this a 32 bit process
function Test-Win32() {
    return [IntPtr]::size -eq 4
}

function Get-ProgramFiles32() {
    if (Test-Win64Machine ) {
        return ${env:ProgramFiles(x86)}
    }
    
    return $env:ProgramFiles
}

#==============================================================================
# End 32/64 Bit functions
#==============================================================================

#==============================================================================
# LINQ like functions
#==============================================================================

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
# Take count elements fro the pipeline 
#============================================================================
function Take-Count() {
    param ( [int]$count = $(throw "Need a count") )
    begin { 
        $total = 0;
    }
    process { 
        if ( $total -lt $count ) {
            $_
        }
        $total += 1
    }
}

#============================================================================
# Take elements from the pipeline while the predicate is true
#============================================================================
function Take-While() {
    param ( [scriptblock]$pred = $(throw "Need a predicate") )
    begin {
        $take = $true
    }
    process {
        if ( $take ) {
            $take = & $pred $_
            if ( $take ) {
                $_
            }
        }
    }
}

#==============================================================================
# End LINQ like functions
#==============================================================================


function Invoke-Admin() {
    param ( [string]$program = $(throw "Please specify a program" ),
            [string]$argumentString = "",
            [switch]$waitForExit )

    $psi = new-object "Diagnostics.ProcessStartInfo"
    $psi.FileName = $program 
    $psi.Arguments = $argumentString
    $psi.Verb = "runas"
    $proc = [Diagnostics.Process]::Start($psi)
    if ( $waitForExit ) {
        $proc.WaitForExit();
    }
}

# Run the specified script as an administrator
function Invoke-ScriptAdmin() {
    param ( [string]$scriptPath = $(throw "Please specify a script"),
            [string]$psArgs = "",
            [switch]$waitForExit,
            [switch]$use32=$false )

    $argString = ""
    for ( $i = 0; $i -lt $args.Length; $i++ ) {
        $argString += $args[$i]
        if ( ($i + 1) -lt $args.Length ) {
            $argString += " "
        }
    }
    
    $p = $psArgs
    $p += " -Command & "
    $p += resolve-path($scriptPath)
    $p += " $argString" 

    $psPath = Get-PowershellPath -use32:$use32
    write-debug ("Running: $psPath $p")
    Invoke-Admin $psPath $p -waitForExit:$waitForExit
}

# Run the specified powershell command 
function Invoke-CommandAdmin() {
    param ( [string]$command = $(throw "Please specify a command to execute") ,
            [switch]$dotSource,
            [switch]$waitForExit,
            [switch]$exitAfter,
            [switch]$use32=$false)

    $p = ""
    if (-not $exitAfter) {
        $p += "-NoExit "
    }

    $prefix = Get-Ternary $dotSource "." "&"
    $p += ('-Command "{0} {1}"' -f $prefix,$command)
    $psPath = Get-PowershellPath -use32:$use32
    write-debug ("Running: $psPath $p")
    Invoke-Admin $psPath $p -waitForExit:$waitForExit
}

# Determine if I am running as an Admin
function Test-Admin() {
	$ident = [Security.Principal.WindowsIdentity]::GetCurrent()
	
	foreach ( $groupIdent in $ident.Groups ) {
		if ( $groupIdent.IsValidTargetType([Security.Principal.SecurityIdentifier]) ) {
			$groupSid = $groupIdent.Translate([Security.Principal.SecurityIdentifier])
			if ( $groupSid.IsWellKnown("AccountAdministratorSid") -or $groupSid.IsWellKnown("BuiltinAdministratorsSid")) {
				return $true;
			}
		}
	}
	
	return $false;
}

# A lot of times you are processing a pipeline and you just need to be able to 
# quickly determine whether or not there is anything left in the pipeline.  
# This filter can be added at the end like so
# 
# $any = Some-Command | ?{ Some-Condition } | test-any
#
function Test-Any() {
    begin {
        $any = $false
    }
    process {
        $any = $true
    }
    end {
        $any
    }
}


#==============================================================================
# Count the number of objects in a pipeline
#==============================================================================
function Count-Object() {
    begin {
        $count = 0
    }
    process {
        $count += 1
    }
    end {
        $count
    }
}

#==============================================================================
# Is this an extension for a binary file type? 
#==============================================================================
function Is-BinaryExtension() {
    param ( [string]$extension = $(throw "Need an extension" ) ) 

    $binRegex= "^(\.)?(lib|exe|obj|bin|tlb|pdb|doc|ncb|pch|dll|baml|resources)$"
    return $extension -match $binRegex
}

function Is-BinaryFileName() { 
    param ( [string]$fileName = $(throw "Need a file Name") )
    return (Is-BinaryExtension [IO.Path]::GetExtension($fileName))
}

function Select-StringRecurse() {
    param ( [string]$text = $(throw "Need text to search for"),
            [string[]]$include = "*",
            [switch]$all= $false,
            [switch]$caseSensitive=$false)

    gci -re -in $include | 
        ? { -not $_.PSIsContainer } | 
        ? { ($all) -or (-not (Is-BinaryExtension $_.Extension)) } |
        % { write-debug "Considering: $($_.FullName)"; ss -CaseSensitive:$caseSensitive $text $_.FullName }
}   

function Get-ChildItemDirectory() { 
    param ( $path = ".",
            [switch]$recurse )
    gci $path -recurse:$recurse | ? { $_.PsIsContainer } 
}

# Used to sign scripts
function Sign-Script([string]$scriptName) {
    if ( $script:libCommonCert -eq $null ) {
        $script:libCommonCert = get-pfxcertificate $libCommonCertPath 
    }

    # Remove the old signature if it's there
    $sig = get-authenticodesignature $scriptName
    if ( $sig -eq $null ) {
        Unsign-Script $scriptName
    }

    if ( $script:cert ) {
        set-authenticodesignature $scriptName $script:libCommonCert
    }
}

function Unsign-Script([string]$scriptName) {
    $sig = get-authenticodesignature $scriptName
    if ( $sig -eq $null ) {
        write-host "Script does not have a signature"
        return
    }

    $old = gc $scriptName
    $new = @()
    foreach ( $line in $old ) {
        if ( $line -eq "# SIG # Begin signature block" ) {
            break;
        }

        $new += $line
    }

    sc $scriptName $new
}


# For deeply nested push statements, pop our way out of the block
function Pop-All() {
    $count = (get-location -stack).Count
    for ( $i = 0; $i -lt $count; ++$i) {
        popd
    }
}  

# Author: Marcel
# Calculate the MD5 hash of a file and return it as a string
function Get-MD5() {
    param ( $filePath = $(throw "Path to file"))
    $file = gci (resolve-path $filePath)
	$stream = $null;
	$cryptoServiceProvider = [Security.Cryptography.MD5CryptoServiceProvider];
	$hashAlgorithm = new-object $cryptoServiceProvider
	$stream = $file.OpenRead();
	$hashByteArray = $hashAlgorithm.ComputeHash($stream);

	$stream.Close();

	# We have to be sure that we close the file stream if any exceptions are 
	# thrown.
	trap {
        if ($stream -ne $null) {
            $stream.Close();
        }
	break;
	}
	return [string]$hashByteArray;
}


# Download a web page and print it to the screen
function Get-WebItem([string]$uri, [string]$outFilePath=".") {
	if ( -not ($uri -match "http(s?)://.*") ) {
		$uri = "http://" + $uri
	}

    if ( $outFilePath -eq "." ) {
        [int]$index = $uri.LastIndexOf("/")
        if ( $index -lt 0 ) {
            $outFilePath = "file.out"
        } else {
            $outFilePath = $uri.SubString($index + 1)
        }
    }
	
    write-host "Downloading $uri -> $outFilePath"
    $client = new-object System.Net.WebClient
    $client.DownloadFile($uri, $outFilePath)
}

function New-GenericObject() {
    param ( [string]$typename = $(throw "Specify a type name"),
            [string[]]$typeParams = $(throw "Specify the type parameters"),
            [object[]]$argParams )

    $genericName = $typeName + '`' + $typeParams.Length
    $genericType = [type] $genericName
    if ( -not $genericType ) { throw "Could not find $genericName" }

    [type[]]$boundTypeParams = $typeParams
    $boundType = $genericType.MakeGenericType($boundTypeParams)
    if ( -not $boundType ) { throw "Could not make closed type $genericType" }
    , [Activator]::CreateInstance($boundType, $argParams)
}

function Remove-ItemTest() {
    param ( [string]$path = $(throw "Please specify a path"),
            [switch]$force )
    if ( test-path $path ) {
        rm -force:$force $path
    }
}

function New-Tuple() {
    param ( [object[]]$list= $(throw "Please specify the list of names and values") )

    $tuple = new-object psobject
    for ( $i= 0 ; $i -lt $list.Length; $i = $i+2) {
        $name = [string]($list[$i])
        $value = $list[$i+1]
        $tuple | add-member NoteProperty $name $value
    }

    return $tuple
}

function Get-Ternary() {
    param ( [bool]$condition = $(throw "Need a conditional"),
            $valueTrue = $(thràow "Need a value for the true condition"),
            $valueFalse = $(throw "Need a value for the false condition") )
    if ( $condition ) {
        return $valueTrue
    } else {
        return $valueFalse
    }
}

# Return all of the local drives on this computer
function Get-LocalDrive() {
    get-wmiobject Win32_LogicalDisk |
        ?{ $_.DriveType -eq 3 } |
        %{ $_.DeviceId }
}

# This method will execute a batch file and then put the resulting 
# environment into the current context 
function Import-Environment() {
    param ( $file = $(throw "Need a CMD/BAT file to execute"),
            $args = "") 

    $tempFile = [IO.Path]::GetTempFileName()

    # Store the output of cmd.exe.  We also ask cmd.exe to output
    # the environment table after the batch file completes

    cmd /c " `"$file`" $args && set > `"$tempFile`" "

    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    remove-item -path env:*
    Get-Content $tempFile | Foreach-Object {
        if($_ -match "^(.*?)=(.*)$") {
            $n = $matches[1]
            if ($n -eq "prompt") {
                # Ignore: Setting the prompt environment variable has no
                #         connection to the PowerShell prompt
            } elseif ($n -eq "title") {
                $host.ui.rawui.windowtitle = $matches[2];
                set-item -path "env:$n" -value $matches[2];
            } else {
                set-item -path "env:$n" -value $matches[2];
            }
        }
    }
    Remove-Item $tempFile
}

function Set-DevEnvironment() { 
    $target = join-path (Get-ProgramFiles32) "Microsoft Visual Studio 10.0\VC\vcvarsall.bat"
    . Import-Environment $target
}


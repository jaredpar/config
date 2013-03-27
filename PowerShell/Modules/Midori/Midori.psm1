
#==============================================================================
#
# Handy function for changing common environment settings
#
#==============================================================================
function Set-Env() {
    param ( [switch]$chk=$false )
    
    $setenv = Join-Path ${env:MidRoot} "setenv.ps1"
    if ($chk) { 
        . $setenv /msharpCheck
    } else { 
        . $setenv /nomsharpCheck
        write-host "Nothing"
    }
}

#==============================================================================
#
# Function for packing away changes.  Takes care of the naming for me so I 
# can jus think about a feature and let it do the versioning
#
#==============================================================================
function New-Pack {
    param ( [string]$packName = $(throw "Need a pack name"),
            [string]$cl = "default") 

    $sharePath = "\\midweb\scratch\jaredpar\packs\" 
    
    $suffix = [DateTime]::Now.ToString("yyyy-mm-dd-ss");
    $name = "{0}-{1}.jjp" -f $packName, $suffix
    $target = Join-Path $sharePath $name
    jjpack pack $target -c $cl
    Write-Host $target

    $name = "{0}-latest.jjp" -f $packName
    $latest = Join-Path $sharePath $name
    copy $target $latest
}

#==============================================================================
# Specialized M# prompt 
#==============================================================================
function prompt() 
{
    write-host -NoNewLine -ForegroundColor Red "Midori "
    if (${env:MIDORI_MSHARP_CHECK} -eq "true") {
        write-host -NoNewLine -ForegroundColor Red "M# Check "
    }

	write-host -NoNewLine -ForegroundColor Green $(get-location)

	foreach ($entry in (get-location -stack)) {
		write-host -NoNewLine -ForegroundColor Red '+';
	}
	write-host -NoNewLine -ForegroundColor Green '>'
	' '
}

function Set-MSharpLocation() { cd (Join-Path $env:MSHARPROOT "csharp") }
function Set-LangLocation() { cd (Join-Path $env:MSHARPROOT "csharp\LanguageAnalysis") }
function Set-CompilerLocation() { cd (Join-Path $env:MSHARPROOT "csharp\LanguageAnalysis\Compiler") }
function Set-SuitesLocation() { cd (Join-Path $env:MSHARPROOT "ddsuites\src\vs\safec\compiler\midori") }
function Set-DepotLocation() { cd $env:MSHARPROOT }
function Set-MidoriLocation { cd $env:MIDROOT }
function Set-FoundationLocation { cd (Join-Path $env:MIDROOT "System\Core\Libraries\Platform-Foundation") }
function Set-LibLocation { cd (Join-Path $env:MIDROOT "System\Core\Libraries") }
function Set-PromisesLocation { cd (Join-Path $env:MIDROOT "System\Core\Libraries\Platform-Promises") }
function Set-CorlibLocation { cd (Join-Path $env:MIDROOT "System\Runtime\Corlib") }

Set-Alias dd Set-DepotLocation -scope Global
Set-Alias msharp Set-MSharpLocation -scope Global
Set-Alias csharp Set-MSharpLocation -scope Global
Set-Alias lang Set-LangLocation -scope Global
Set-Alias compiler Set-CompilerLocation -scope Global
Set-Alias suites Set-SuitesLocation -scope Global
Set-Alias midori Set-MidoriLocation -scope Global
Set-Alias foundation Set-FoundationLocation -scope Global
Set-Alias lib Set-LibLocation -scope Global
Set-Alias promises Set-PromisesLocation -scope Global
Set-Alias corlib Set-CorlibLocation -scope Global
Set-Alias pack New-Pack -Scope Global

# Setup gvim as the sd editor for clients, change lists and merge conflicts
${env:SDEDITOR} = (Join-Path (Get-ProgramFiles32) "Vim\vim72\gvim.exe") + " --nofork"



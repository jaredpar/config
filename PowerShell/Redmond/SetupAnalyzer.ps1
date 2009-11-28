

# Analyzes the setup logs looking for a failure code
$script:msiMap = @{}
$script:processedMap = @{}

# Regexs
$script:productRegex = "(?<product>[\d\w\s.()]+)"
$script:codeRegex = "(?<code>[a-fx\d]+)"
$script:dateRegex = "\[(?<date>[\d/,:]+)\]" 

# Arguments
[bool]$script:showOld = $false
[bool]$script:showError = $false
[bool]$script:debug = $false
[bool]$script:returnErrors = $false
[string]$script:logPath = $null 
$script:errorList = @()

for ( $i = 0; $i -lt $args.Length; $i++)
{
    switch ( $args[$i] )
    {
        "-debug" { $script:debug = $true; break }
        "-showError" { $script:showError = $true; break }
        "-showOld" { $script:showOld= $true; break }
        "-return" { $script:returnErrors = $true; break }
        default { $script:logPath = $args[$i]; break }
    }
}

if ( $script:logPath -eq $null )
{
    write-host "Please specify the log directory"
    exit
}

if ( -not (test-path $script:logPath) )
{
    write-host "Cannot access or path does not exist: $logPath"
    exit
}

function GetShortName($product)
{
    switch -regex ($product)
    {
        ".*Framework.*2\.0SP1.*" { return "2.0SP1" }
        ".*Framework.*2\.0.*" { return "2.0" }
        ".*Framework.*3\.0SP1.*" { return "3.0SP1" }
        ".*Framework.*3\.0.*" { return "3.0" }
        ".*Framework.*3\.5.*" { return "3.5" }
        "Microsoft .Net Framework ([\d.\w]+)" { return $matches[1]; }
        "Microsoft Visual Studio 2008 .*" { return "VS2008" }
        default { return $product }
    }
}

function DevDiv127528($line)
{
    write-host "Looks like DevDiv 127528"
    write-host "`tNo known work arounds are available"
    write-host $line
}

function CheckFramework35_1618([string]$file)
{
    write-host "Looks like another install is running and prevented this install from occurring"
}

function CheckFramework30_22([string]$file)
{
    write-host "Examining Framework 3.0 22 failure"
    write-host "If this is a Vista machine try rebooting"
}

function CheckFrameworkAny_3010([string]$product, [string]$msi)
{
    write-host "Examining Framework $product failure: 3010"
    write-host "A system reboot is required"
}

function ProcessItem($product, [int]$code, [datetime]$date)
{
    write-debug "Processing $product -> $code -> $date"
    if ( 0 -eq $code )
    {
        return;
    }

    $diff = [DateTime]::Now - [datetime]$date
    if ( ($diff.Days -ge 2) -and (-not $script:showOld) )
    {
        write-debug "Found failure over 2 days old"
        continue;
    }

    $msiFile = $script:msiMap[$product]
    if ( $msiFile -eq $null )
    {
        write-debug "Found NULL MSI file"
        continue;
    }

    $msiFile = join-path $logPath $msiFile
    if ( -not ((test-path $msiFile) -or ($msiFile -like "*CBS")) )
    {
        write-host "$product-> $code : Could not find $msiFile"
        continue;
    }

    # The parser can find the same error several times so don't report the same
    # failure over and over again
    $hash = "$product->$code->$msiFile"
    if ( $script:processedMap[$hash] -ne $null )
    {
        return;
    }
    $script:processedMap[$hash] = $true
    $shortProduct = GetShortName $product

    switch -regex ($shortProduct + " " + $code )
    {
        ".* 1603" { CheckMsiLog $product 1603 $msiFile; break }
        ".* 3010" { CheckFrameworkAny_3010 $product $msiFile; break }
        "3\.0 22" { CheckFramework30_22 $msiFile; break }
        "3\.5 1618" { CheckFramework35_1618 $msiFile; break }
        default { write-host "Unknown Failure $product -> $code" }
    }
}

function CheckMsiLog([string]$product, [int]$code, [string]$msiLogPath)
{
    write-host "Examining MSI Log for: $product -> $code"
    foreach ( $line in (gc $msiLogPath) )
    {
        if ( $line -match "^Error (\d+)\..*" )
        {
            $code = $matches[1]

            $obj = new-object psobject
            add-member -in $obj -memberType NoteProperty -Name "Product" -Value $product
            add-member -in $obj -memberType NoteProperty -Name "Code" -Value $code
            add-member -in $obj -memberType NoteProperty -Name "Line" -Value $line
            $script:errorList += $obj 

            switch ($code) {
                "1935" { DevDiv127528 $line }
                "1937" { 
                    write-host "Signature Verification failed.  Did you install StrongNameHijack?"
                    write-host "\\ddrelqa\StrongNameHijack\StrongNameHijack.msi"
                    if ( $script:showError )
                    {
                        write-host $line
                    }
                }
                default { write-host $line }
            }
        }
    }
}

function CheckCoreLog([string]$title, [string]$logPath, [string]$fileName)
{
    write-host "Checking $title"

    $file = join-path $logPath $fileName 
    if ( -not (test-path $file) )
    {
        write-host "Error: Could not find the $fileName"
        return;
    }

    $curProduct = "<none>"
    foreach ( $line in (gc $file) )
    {
        if ( $line -match "$dateRegex\s+$productRegex\:.*Enabling MSI.*:(?<msi>.*)$" )
        {
            $product = $matches["product"]
            $msi = split-path $matches["msi"] -leaf
            write-debug "Found MSI Map $product -> $msi"
            $script:msiMap[$product] = $msi
            $curProduct = $product
        }
        elseif ( $line -match "$dateRegex\s+$productRegex\:.*MSI returned error code $codeRegex" )
        {
            ProcessItem $matches["product"] $matches["code"] $matches["date"]
        }
        elseif ( $line -match "$dateRegex.*InstallReturnValue.*,\s*$codeRegex$")
        {
            $code = [int]$matches["code"]
            write-debug "Product Install Result: $curProduct -> $code"
            if ( $code -ne 0 )
            {
                ProcessItem $curProduct $code $matches["date"]
            }
        }
        elseif ( $line -match "$dateRegex\s+$productRegex\:.*\(CBS\).*WUSA\.exe.*" )
        {
            $product = $matches["product"]
            write-debug "Found CBS Map $product"
            $script:msiMap[$product] = "CBS"
        }
    }
}

function CheckFramework35_Install([string]$logPath)
{
    CheckCoreLog "3.5 Framework Install" $logPath "dd_dotnetfx35install.txt"
}

function CheckVstsCore_Install([string]$logPath)
{
    CheckCoreLog "Vsts Core 9.0" $logPath "dd_install_vs_vstscore_90.txt"
}

if ( $script:debug )
{
    $DebugPreference = "Continue"
}

CheckFramework35_Install $script:logPath
CheckVstsCore_Install $script:logPath

if ( $script:debug )
{
    $DebugPreference = "SilentlyContinue"
}

if ( $script:returnErrors )
{
    echo $script:errorList
}

# CheckFramework35_Failure $logPath

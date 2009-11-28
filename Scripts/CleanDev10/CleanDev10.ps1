# To get a list of products run the following
# \\ddrelqa\tools\Misc\msiinv.exe  > e:\temp\output.txt

$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition 
$productList = "{8FB53850-246A-3507-8ADE-0060093FFEA6}",
    "{B05A5A43-46AB-4722-970E-F6E5775FBDF2}",
    "{425956B6-11B4-41DA-B7D5-44D14322F991}",
    "{0F2D4DB7-99E9-4B43-BBB7-FD3CCC99B7A8}",
    "{05EC21B8-4593-3037-A781-A6B5AFFCB19D}",
    "{AA467959-A1D6-4F45-90CD-11DC57733F32}",
    "{F8921FCE-485D-4CBA-A691-5543CE6B2678}",
    "{55042A50-9A2B-306E-AB1A-649A3FD8057D}",
    "{241F2BF7-69EB-42A4-9156-96B2426C7504}",
    "{291B3A3B-F808-45B8-8113-DF232FCB6C82}",
    "{2E5C075E-11AB-4BDD-918C-7B9A68953FF8}",
    "{BCC899FE-2DAA-460C-A5FB-60291E73D9C3}",
    "{F9B3DD02-B0B3-42E9-8650-030DFF0D133D}",
    "{2AFFFDD7-ED85-4A90-8C52-5DA9EBDC9B8F}",
    "{E9F44C98-B8B6-480F-AF7B-E42A0A46F4E3}",
    "{2750B389-A2D2-4953-99CA-27C1F2A8E6FD}",
    "{FF29527A-44CD-3422-945E-981A13584000}",
    "{6753B40C-0FBD-3BED-8A9D-0ACAC2DCD85D}",
    "{9A33B83D-FFC4-44CF-BEEF-632DECEF2FCD}",
    "{53F5C3EE-05ED-4830-994B-50B2F0D50FCE}",
    "{F81D9FF2-7F33-3C29-9DE5-8D3590B8AB15}",
    "{CDA2821D-06F1-3CEF-AD2F-93A828ABCCBF}",
    "{8B916626-D225-496A-83ED-EDBE9E907432}",
    "{3FF8FB72-38A6-42B9-B6D2-6929967D4BA7}",
    "{9D843790-2D86-4257-AF21-2A929B787545}",
    "{6C9F6D23-E9AD-43C9-B43A-011562AAF876}",
    "{9656F3AC-6BA9-43F0-ABED-F214B5DAB27B}",
    "{95D65791-87FB-3206-8878-5026FC0BD83B}",
    "{F5E87B12-3C27-452F-8E78-21D42164FD83}",
    "{58344E43-2236-488E-BBF0-4137B7903A1C}",
    "{96DDE566-43D9-4AFC-AADD-80798DE80946}",
    "{CC9DFCC7-AF91-33AA-BEEF-18C7576C4442}",
    "{342D4AD7-EC4C-4EC8-AEA6-E70F5905A490}",
    "{17F46019-69DA-4A37-BADE-BDE9CB411D10}",
    "{1861DDD9-1216-31A0-8DA0-416F001B7E27}",
    "{08F85B0D-F868-49B0-A2B8-DE8EABA17C81}",
    "{C688457E-03FD-4941-923B-A27F4D42A7DD}",
    "{B5153233-9AEE-4CD4-9D2C-4FAAC870DBE2}",
    "{58721EC3-8D4E-4B79-BC51-1054E2DDCD10}",
    "{0826F9E4-787E-481D-83E0-BC6A57B056D5}",
    "{4A6F34E2-09E5-4616-B227-4A26A488A6F9}",
    "{196E77C5-F524-4B50-BD1A-2C21EEE9B8F7}",
    "{9D6D76A6-4328-49E8-97A7-531A74841DA5}",
    "{F3494AB6-6900-41C6-AF57-823626827ED8}",
    "{F1DC7648-8623-442F-92B7-E118DF61872E}",
    "{4815BD99-96A4-49FE-A885-DCF06E9E4E78}",
    "{C79A7EAB-9D6F-4072-8A6D-F8F54957CD93}",
    "{C965F01C-76EA-4BD7-973E-46236AE312D7}",
    "{6CDEAD7E-F8D8-37F7-AB6F-1E22716E30F3}",
    "{4F5C6F70-C323-4803-B60A-AC749F1D74CA}"


function Remove-PathMatch() {
    param ($path = $(throw "Need a path"),
           $pattern = $(throw "Need a pattern") )

    $files = gci $path | ?{ $_.Name -like $pattern } | %{ Remove-Path $_.FullName }

}

function Remove-Path() {
    param ($path = $(throw "Need a path"))
    if ( test-path $path) {
        write-host "Deleting: $path"
        rm -re -fo $path
    }
}

function Invoke-Command() {
    param ( [string]$program = $(throw "Please specify a program" ),
            [string]$argumentString = "" )

    $psi = new-object "Diagnostics.ProcessStartInfo"
    $psi.FileName = $program 
    $psi.Arguments = $argumentString
    $psi.UseShellExecute = $false
    $proc = [Diagnostics.Process]::Start($psi)
    $proc.WaitForExit();
}

# Delete all of the Dev10 Directories
$progPath = Get-ProgramFiles32
Remove-Path (join-path $progPath "Microsoft Visual Studio 10.0")
Remove-Path (join-path $progPath "Microsoft F#")
Remove-Path (join-path $progPath "Reference Assemblies\Microsoft\Framework\.NetFramework\4.0")
if ( Test-Win64 ) {
    Remove-Path (join-path $env:ProgramFiles "Reference Assemblies\Microsoft\Framework\.NetFramework\4.0")
}
    
Remove-PathMatch $progPath "Visual Studio 2010*"

foreach ( $cur in ("Framework","Framework64")) {
    $path = join-path $env:windir "Microsoft.Net"
    $path = join-path $path $cur
    Remove-PathMatch $path "v4.0*"
}

# Delete the service registry keys
Remove-Path "hklm:\SYSTEM\CurrentControlSet\services\.NET CLR Networking 4.0.0.0"
Remove-PathMatch "hklm:\SYSTEM\CurrentControlSet\services" "ASP.NET_4.0.*"
Remove-PathMatch "hklm:\SYSTEM\CurrentControlSet\services" "clr_optimization_v4.0.*"
Remove-PathMatch "hklm:\SYSTEM\CurrentControlSet\services" "Windows"

foreach ( $product in $productList ) {
    write-host "Removing $product"
    Invoke-Command "msiexec.exe" "/passive /x $product"
    Invoke-Command (join-path $scriptPath "smartmsizap.exe") "/q /p $product"
}


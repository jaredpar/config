
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', '', Scope='Function', Target='*')]
param()

Set-StrictMode -version 2.0
$ErrorActionPreference="Stop"

function script:Exec-CommandCore([string]$command, [string]$commandArgs, [switch]$useConsole = $true, [switch]$useAdmin = $false) {
  $startInfo = New-Object System.Diagnostics.ProcessStartInfo
  $startInfo.FileName = $command
  $startInfo.Arguments = $commandArgs

  if ($useAdmin) {
      $startInfo.Verb = "runas"
      $startInfo.UseShellExecute = $true
  }
  else {
      $startInfo.UseShellExecute = $false
  }

  $startInfo.WorkingDirectory = Get-Location

  if (-not $useConsole) {
     $startInfo.RedirectStandardOutput = $true
     $startInfo.CreateNoWindow = $true
  }

  $process = New-Object System.Diagnostics.Process
  $process.StartInfo = $startInfo
  $process.Start() | Out-Null

  $finished = $false
  $output = ""
  try {
    if (-not $useConsole) { 
      # The OutputDataReceived event doesn't fire as events are sent by the 
      # process in powershell.  Possibly due to subtlties of how Powershell
      # manages the thread pool that I'm not aware of.  Using blocking
      # reading here as an alternative which is fine since this blocks 
      # on completion already.
      $out = $process.StandardOutput
      $builder = New-Object System.Text.StringBuilder
      while (-not $out.EndOfStream) {
        $builder.AppendLine($out.ReadLine()) | Out-Null
      }

      $output = $builder.ToString()
    }

    while (-not $process.WaitForExit(100)) { 
      # Non-blocking loop done to allow ctr-c interrupts
    }

    $finished = $true
    return @{
      ExitCode = $process.ExitCode
      Output = $output
    }
  }
  finally {
    # If we didn't finish then an error ocurred or the user hit ctrl-c.  Either
    # way kill the process
    if (-not $finished) {
      $process.Kill()
    }
  }
}

<#
  .SYNOPSIS
    Handy function for executing a windows command which needs to go through 
    windows command line parsing.

  .OUTPUTS
    Returns a tuple of the process exit code and output of the command executed.

  .NOTES
    This function will not throw on failure
#>
function Exec-CommandRaw([string]$command, [string]$commandArgs, [switch]$useAdmin = $false) {
  Exec-CommandCore -command $command -commandArgs $commandargs -useConsole:$false -useAdmin:$useAdmin
}

<#
  .SYNOPSIS
    Handy function for executing a windows command which needs to go through 
    windows command line parsing.

  .OUTPUTS
    Returns the output of the command executed.

  .NOTES
    This function will throw on failure
#>
function Exec-Command([string]$command, [string]$commandArgs, [switch]$useAdmin = $false) {
  $t = Exec-CommandCore -command $command -commandArgs $commandargs -useConsole:$false -useAdmin:$useAdmin
  if ($t.ExitCode -ne 0) {
    $msg = "Command failed to execute $($t.ExitCode): $command $commandArgs" 
    throw $msg
  }

  return $t.Output
}

<#
  .SYNOPSIS
    Functions exactly like Exec-Command but lets the process re-use the current
    console. This means items like colored output will function correctly.

  .OUTPUTS
    There are no outputs

  .NOTES
    This function will throw on failure
#>
function Exec-Console([string]$command, [string]$commandArgs, [switch]$useAdmin = $false) {
  $t = Exec-CommandCore -command $command -commandArgs $commandargs -useConsole:$true -useAdmin:$useAdmin
  if ($t.ExitCode -ne 0) {
    $msg = "Command failed to execute $($t.ExitCode): $command $commandArgs" 
    throw $msg
  }
}

<#
  .SYNOPSIS
    Functions exactly like Exec-Console but returns the exit code of the command executed.

  .OUTPUTS
    Exit code of the command executed.

  .NOTES
    This function will not throw on failure
#>
function Exec-ConsoleRaw([string]$command, [string]$commandArgs, [switch]$useAdmin = $false) {
  $t = Exec-CommandCore -command $command -commandArgs $commandargs -useConsole:$true -useAdmin:$useAdmin
  return $t.ExitCode
}

function Create-Directory([string]$dir) {
  New-Item $dir -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
}

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

function Check-LastExitCode() {
  if ($LASTEXITCODE -ne 0) {
    throw "Last command failed with exit code $LASTEXITCODE"
  }
}

function Select-StringRecurse(
  [string]$text = $(throw "Need text to search for"),
  [string[]]$include = "*",
  [switch]$all= $false,
  [switch]$caseSensitive=$false) {

  function Test-BinaryExtension() {
    param ( [string]$extension = $(throw "Need an extension" ) ) 

    $binRegex= "^(\.)?(lib|exe|obj|bin|tlb|pdb|doc|ncb|pch|dll|baml|resources|sdf|idb|ipch)$"
    return $extension -match $binRegex
  }

  Get-ChildItem -re -in $include | 
    Where-Object { -not $_.PSIsContainer } | 
    Where-Object { ($all) -or (-not (Test-BinaryExtension $_.Extension)) } |
    ForEach-Object { Select-String -CaseSensitive:$caseSensitive $text $_.FullName }
}   

# Author: Marcel
# Calculate the MD5 hash of a file and return it as a string
function Get-MD5($filePath = $(throw "Path to file")) {
  $file = Get-ChildItem (Resolve-Path $filePath)
  $stream = $null;
  $cryptoServiceProvider = [Security.Cryptography.MD5CryptoServiceProvider];
  $hashAlgorithm = New-Object $cryptoServiceProvider
  $stream = $file.OpenRead();
  $hashByteArray = $hashAlgorithm.ComputeHash($stream);

  $stream.Close();

  # We have to be sure that we close the file stream if any exceptions are 
  # thrown.
  try {
    if ($null -ne $stream) {
        $stream.Close();
    }
  }
  catch {

  }
  return [string]$hashByteArray;
}

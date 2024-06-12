
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Scope='Function', Target='*')]
[System.Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidDefaultValueSwitchParameter', '', Scope='Function', Target='*')]
param()

Set-StrictMode -version 2.0
$ErrorActionPreference="Stop"

function Exec-CommandCore([string]$command, [string]$commandArgs, [switch]$useConsole = $true, [switch]$useAdmin = $false, [switch]$softFail = $false) {
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
  try {
    if (-not $useConsole) { 
      # The OutputDataReceived event doesn't fire as events are sent by the 
      # process in powershell.  Possibly due to subtlties of how Powershell
      # manages the thread pool that I'm not aware of.  Using blocking
      # reading here as an alternative which is fine since this blocks 
      # on completion already.
      $out = $process.StandardOutput
      while (-not $out.EndOfStream) {
        $line = $out.ReadLine()
        Write-Output $line
      }
    }

    while (-not $process.WaitForExit(100)) { 
      # Non-blocking loop done to allow ctr-c interrupts
    }

    $finished = $true
    if ($process.ExitCode -ne 0) {
      $msg = "Command failed to execute $($process.ExitCode): $command $commandArgs" 
      if ($softFail) {
        Write-Output $msg
      } else {
        throw $msg
      }
    }
  }
  finally {
    # If we didn't finish then an error occured or the user hit ctrl-c.  Either
    # way kill the process
    if (-not $finished) {
      $process.Kill()
    }
  }
}

# Handy function for executing a windows command which needs to go through 
# windows command line parsing.  
#
# Use this when the command arguments are stored in a variable.  Particularly 
# when the variable needs reparsing by the windows command line. Example:
#
#   $args = "/p:ManualBuild=true Test.proj"
#   Exec-Command $msbuild $args
# 
function Exec-Command([string]$command, [string]$commandArgs, [switch]$softFail = $false) {
  Exec-CommandCore -command $command -commandArgs $commandargs -useConsole:$false -softFail:$softFail
}

# Functions exactly like Exec-Command but lets the process re-use the current 
# console. This means items like colored output will function correctly.
#
# In general this command should be used in place of
#   Exec-Command $msbuild $args | Out-Host
#
function Exec-Console([string]$command, [string]$commandArgs, [switch]$useAdmin = $false, [switch]$softFail = $false) {
  Exec-CommandCore -command $command -commandArgs $commandargs -useConsole:$true -useAdmin:$useAdmin -softFail:$softFail
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

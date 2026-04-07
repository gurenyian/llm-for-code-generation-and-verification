param(
  [Parameter(Mandatory=$true)][string]$WindowsHost,
  [Parameter(Mandatory=$true)][string]$WindowsUser,
  [Parameter(Mandatory=$true)][string]$WindowsTempDir,
  [Parameter(Mandatory=$true)][string]$LocalCasesBin,
  [Parameter(Mandatory=$true)][string]$LocalOracleOut,
  [string]$SshExe = "ssh",
  [string]$ScpExe = "scp",
  [string]$GccPath = "gcc"
)

$ErrorActionPreference = "Stop"

function Quote([string]$s) {
  return '"' + ($s -replace '"','\"') + '"'
}

if (-not (Test-Path $LocalCasesBin)) {
  throw "LocalCasesBin not found: $LocalCasesBin"
}

$remoteUserHost = "$WindowsUser@$WindowsHost"

# We copy 3 files: test_runner.c, wine_test.h, test_cases.bin
$runnerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$localRunnerC = Join-Path $runnerDir "test_runner.c"
$localWineTestH = Join-Path $runnerDir "wine_test.h"

if (-not (Test-Path $localRunnerC)) { throw "Missing: $localRunnerC" }
if (-not (Test-Path $localWineTestH)) { throw "Missing: $localWineTestH" }

$remoteCases = (Join-Path $WindowsTempDir "test_cases.bin") -replace "\\","/"
$remoteRunnerC = (Join-Path $WindowsTempDir "test_runner.c") -replace "\\","/"
$remoteWineTestH = (Join-Path $WindowsTempDir "wine_test.h") -replace "\\","/"
$remoteExe = (Join-Path $WindowsTempDir "test_runner_win.exe") -replace "\\","/"
$remoteOracle = (Join-Path $WindowsTempDir "oracle.bin") -replace "\\","/"

Write-Host "[INFO] Uploading to Windows..."
  & $ScpExe $localRunnerC "${remoteUserHost}:$remoteRunnerC" | Out-Host
  & $ScpExe $localWineTestH "${remoteUserHost}:$remoteWineTestH" | Out-Host
  & $ScpExe $LocalCasesBin "${remoteUserHost}:$remoteCases" | Out-Host

Write-Host "[INFO] Compiling on Windows (MinGW gcc assumed)..."
# Use cmd.exe to avoid PowerShell quoting issues over ssh.
$compileCmd = "cd /d $WindowsTempDir && $GccPath test_runner.c -o test_runner_win.exe -lshlwapi"
& $SshExe $remoteUserHost ("cmd.exe /c " + (Quote $compileCmd)) | Out-Host

Write-Host "[INFO] Recording oracle on Windows..."
$recordCmd = "cd /d $WindowsTempDir && test_runner_win.exe --record test_cases.bin oracle.bin"
& $SshExe $remoteUserHost ("cmd.exe /c " + (Quote $recordCmd)) | Out-Host

Write-Host "[INFO] Downloading oracle..."
$outDir = Split-Path -Parent $LocalOracleOut
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

  & $ScpExe "${remoteUserHost}:$remoteOracle" $LocalOracleOut | Out-Host

Write-Host "[OK] oracle downloaded to $LocalOracleOut"

param(
  [Parameter(Mandatory=$true)][string]$ConfigPath,
  [Parameter(Mandatory=$true)][string]$ApiName,
  [string]$LocalOutRoot = "./_remote_out"
)

$ErrorActionPreference = "Stop"

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$sshHost = $config.ssh.host
$sshPort = $config.ssh.port
$sshUser = $config.ssh.user
$key  = $config.ssh.private_key_path
$remoteRoot = $config.workspace.remote_root
$kleeOutDir = $config.klee.output_dir

$apiLower = $ApiName.ToLower()
$localApiDir = Join-Path $LocalOutRoot $apiLower
$localKleeDir = Join-Path $localApiDir $kleeOutDir

Write-Host "[INFO] Remote host: $sshHost"
Write-Host "[INFO] Remote user: $sshUser"
Write-Host "[INFO] Remote root (configured): $remoteRoot"
Write-Host "[INFO] Local output: $localApiDir"

New-Item -ItemType Directory -Force -Path $localApiDir | Out-Null

# Build ssh/scp args
$sshArgs = @()
$scpArgs = @()
if ($key -and (Test-Path $key)) {
  $sshArgs += @('-i', $key)
  $scpArgs += @('-i', $key)
}
$sshArgs += @('-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', '-p', "$sshPort")
$scpArgs += @('-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', '-P', "$sshPort")

$remoteSpec = "{0}@{1}" -f $sshUser, $sshHost

function Resolve-RemoteRoot([string]$configuredRoot) {
  $scriptTemplate = @'
set -e
remote_root="__CONF_ROOT__"
if [ ! -d "$remote_root" ]; then
  for cand in "__CONF_ROOT__" "$HOME/oda_demo" "$HOME/oda_work/oda_demo" "/home/$USER/oda_demo" "/home/$USER/oda_work/oda_demo"; do
    if [ -d "$cand" ]; then
      remote_root="$cand"
      break
    fi
  done
fi
if [ -d "$remote_root" ]; then
  echo "$remote_root"
  exit 0
fi
exit 1
'@

  $script = $scriptTemplate.Replace("__CONF_ROOT__", $configuredRoot) -replace "`r`n", "`n"
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($script))
  $cmd = "bash -lc 'echo $b64 | base64 -d | bash'"
  $out = & ssh @sshArgs $remoteSpec $cmd
  $resolved = ($out | Out-String).Trim()
  if (-not $resolved) { throw "Unable to resolve remote root (received empty result)" }
  return $resolved
}

$resolvedRoot = Resolve-RemoteRoot -configuredRoot $remoteRoot
Write-Host "[INFO] Resolved remote root: $resolvedRoot"

function Copy-Remote([
  Parameter(Mandatory=$true)][string]$RemotePath,
  [Parameter(Mandatory=$true)][string]$LocalPath,
  [switch]$Recursive
) {
  $destDir = Split-Path -Parent $LocalPath
  if (-not $destDir) { $destDir = "." }
  New-Item -ItemType Directory -Force -Path $destDir | Out-Null

  $args = @()
  $args += $scpArgs
  if ($Recursive) { $args += "-r" }

  $remoteFull = "{0}:{1}" -f $remoteSpec, $RemotePath
  Write-Host "[INFO] scp $($args -join ' ') $remoteFull $LocalPath"
  & scp @args $remoteFull $LocalPath | Out-Host
}

# Paths to fetch
$remoteKleeDir = "$resolvedRoot/klee/$kleeOutDir"
$remoteHarness = "$resolvedRoot/klee/harness_${apiLower}.c"
$remoteStub = "$resolvedRoot/klee/oda_stubs.c"
$remoteSpecPath = "$resolvedRoot/specs/$apiLower.json"

Copy-Remote -RemotePath $remoteKleeDir -LocalPath $localKleeDir -Recursive
Copy-Remote -RemotePath $remoteHarness -LocalPath (Join-Path $localApiDir "harness_${apiLower}.c")
Copy-Remote -RemotePath $remoteStub -LocalPath (Join-Path $localApiDir "oda_stubs.c")
Copy-Remote -RemotePath $remoteSpecPath -LocalPath (Join-Path $localApiDir "spec.json")

Write-Host "[INFO] Download complete. Local files under: $localApiDir"

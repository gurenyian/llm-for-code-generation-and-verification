param(
  [Parameter(Mandatory=$true)][string]$ConfigPath,
  [Parameter(Mandatory=$true)][string]$ApiName
)

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$sshHost = $config.ssh.host
$sshPort = $config.ssh.port
$sshUser = $config.ssh.user
$key  = $config.ssh.private_key_path
$remoteRoot = $config.workspace.remote_root
$kleeTimeout = $config.klee.timeout_sec
$kleeMemory = $config.klee.max_memory_mb
$kleeOutDir = $config.klee.output_dir
$proxyPort = $config.network.proxy_port
$proxyType = $config.network.proxy_type

Write-Host "[INFO] Remote host: $sshHost"
Write-Host "[INFO] Remote user: $sshUser"
Write-Host "[INFO] Remote root: $remoteRoot"
Write-Host "[INFO] Proxy: ${proxyType}:$proxyPort"

$apiLower = $ApiName.ToLower()

$remoteScriptTemplate = @'
set -e

remote_root="__REMOTE_ROOT__"

echo "[DEBUG] initial remote_root: $remote_root"

# Auto-detect oda_demo if the configured path is missing
if [ -z "$remote_root" ] || [ ! -d "$remote_root" ]; then
  for cand in "__REMOTE_ROOT__" "$HOME/oda_demo" "$HOME/oda_work/oda_demo" "/home/$USER/oda_demo" "/home/$USER/oda_work/oda_demo"; do
    if [ -d "$cand" ]; then
      remote_root="$cand"
      break
    fi
  done
fi

echo "[DEBUG] resolved remote_root: $remote_root"

if [ -z "$remote_root" ] || [ ! -d "$remote_root" ]; then
  echo "[ERROR] remote root not found: __REMOTE_ROOT__"
  exit 1
fi

cd "$remote_root"
pwd
ls -la

python3 specs/gen_oda_stub.py "specs/__API_LOWER__.json" -o klee/oda_stubs.c
if [ ! -f "klee/harness___API_LOWER__.c" ] && [ -f "klee/harness___API_LOWER___template.c" ]; then
  cp "klee/harness___API_LOWER___template.c" "klee/harness___API_LOWER__.c"
fi

cd klee

# Locate klee.h
KLEE_INCLUDE=""
for path in /usr/include /usr/local/include /usr/include/klee /usr/local/include/klee; do
  if [ -f "$path/klee/klee.h" ]; then
    KLEE_INCLUDE="$path"
    break
  fi
done

if [ -z "$KLEE_INCLUDE" ]; then
  echo "[ERROR] unable to locate klee/klee.h"
  exit 1
fi

echo "[INFO] Using klee.h at $KLEE_INCLUDE"

clang -I"$KLEE_INCLUDE" -emit-llvm -c -g -O0 -Xclang -disable-O0-optnone "harness___API_LOWER__.c" -o harness.bc

rm -rf "__KLEE_OUT__"
klee --optimize --max-time=__KLEE_TIMEOUT__s --max-memory=__KLEE_MEM__ --output-dir=__KLEE_OUT__ --write-test-info harness.bc

echo "[INFO] KLEE output dir: __KLEE_OUT__"
ls -la "__KLEE_OUT__" || true
'@

$remoteScript = $remoteScriptTemplate.Replace("__REMOTE_ROOT__", $remoteRoot)
$remoteScript = $remoteScript.Replace("__API_LOWER__", $apiLower)
$remoteScript = $remoteScript.Replace("__KLEE_OUT__", $kleeOutDir)
$remoteScript = $remoteScript.Replace("__KLEE_TIMEOUT__", $kleeTimeout)
$remoteScript = $remoteScript.Replace("__KLEE_MEM__", $kleeMemory)

# Normalize to LF before base64 to avoid bash parsing CRLF
$remoteScriptLf = $remoteScript -replace "`r`n", "`n"

Write-Host "[DEBUG] remote script rendered:" 
Write-Host $remoteScriptLf

$remoteCmdB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($remoteScriptLf))
# Use single quotes around bash -lc payload to avoid PowerShell parsing/escaping issues
$remoteCmd = "bash -lc 'echo $remoteCmdB64 | base64 -d | bash'"

$sshArgs = @("-i", $key, "-p", "$sshPort", "$sshUser@$sshHost")

if ($proxyPort -and $proxyPort -ne 0) {
  Write-Host "[INFO] Proxy specified in config, please ensure your local SSH client is configured to use it if needed."
}

ssh @sshArgs "$remoteCmd"

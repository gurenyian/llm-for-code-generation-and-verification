<#
Windows 侧：通过 SSH 触发 Ubuntu VM 上的 KLEE/Wine pipeline，并拉回产物。

你给的配置里同时包含 Windows SSH (给 Windows oracle 用) 和 Ubuntu Wine 路径；
本脚本聚焦“跑 Ubuntu pipeline”，Windows oracle 录制仍使用 `win_record.ps1`。

前置：
- 本机 PowerShell 可用 ssh/scp（Windows 10+ 内置 OpenSSH 客户端通常自带）
- Ubuntu VM 已启用 sshd，且已配置免密 key 或可交互输入密码

示例：
  .\ubuntu_run_pipeline.ps1 -UbuntuUser guren -UbuntuHost 192.168.154.128 -UbuntuKey $env:USERPROFILE\.ssh\id_rsa -ApiName PathIsRelativeW
  .\ubuntu_run_pipeline.ps1 -UbuntuUser guren -UbuntuHost 192.168.154.128 -UbuntuKey $env:USERPROFILE\.ssh\id_rsa -ApiName lstrcmpW -RecordOracleLocal -WineCheck
#>

[CmdletBinding()]
param(
  [string]$UbuntuUser = "guren",
  [string]$UbuntuHost = "192.168.154.129",
  [string]$UbuntuKey = "$env:USERPROFILE\.ssh\id_rsa",
  [int]$UbuntuPort = 22,

  # Ubuntu 侧 Wine/KLEE 环境
  [string]$WineSrcRoot = "/home/guren/wine",
  [string]$WineBuildRoot = "/home/guren/wine/build64",  # 暂不强依赖，先预留

  # Ubuntu 侧工作目录
  [string]$UbuntuWorkDir = "/home/guren/oda_work",

  # 目标 API
  [string]$ApiName = "PathIsRelativeW",

  # stub 生成模式：spec（默认使用 specs/<api>.json），llm（调用真实 LLM 生成 spec+stub），none（空 stub）
  [ValidateSet("spec", "llm", "none")]
  [string]$StubMode = "spec",

  # 当 StubMode=llm 时，需要指明目标函数所在 dll/file（用于依赖/ψ 抽取）。例如：shlwapi/path.c
  [string]$TargetDll = "",
  [string]$TargetFile = "",

  # 默认不拉回 wineprefix（里面有大量符号链接/冒号路径，在 Windows 上会导致 scp mkdir 失败）。
  # 需要排查 Wine 环境时再显式开启。
  [switch]$DownloadWinePrefix,

  # 真实 LLM 配置（推荐用环境变量注入；这里提供参数方便 PowerShell 传递）
  # 注意：脚本不会打印/回显 $LlmApiKey。
  [string]$LlmApiKey = "",
  [string]$LlmModel = "",
  [string]$LlmBaseUrl = "",
  [string]$LlmTemperature = "",
  [string]$LlmMaxTokens = "",

  # 可选：在开始前做一次 TCP 端口探测（会产生较多输出；默认关闭以保持日志干净）
  [switch]$PreflightTcpCheck,

  # 可选：自动串联最后两步
  #  1) 在本机 Windows 上用 test_runner.exe 录制 oracle.bin
  #  2) 上传到 Ubuntu，在 Wine 下 --check，并拉回报告
  [switch]$RecordOracleLocal,
  [switch]$WineCheck,

  # 可选：dump `ktest-tool <file.ktest>` 的输出，便于排查解析失败
  [switch]$DumpKtestTool,
  [string]$DumpKtestToolDir = "",

  # 本地（Windows）拉回产物目录
  [string]$LocalOutDir = ""
)

# 在部分宿主环境/以 -File 调用时，$PSScriptRoot 可能为空；这里做一次兜底，保证默认输出目录可用。
if (-not $LocalOutDir -or $LocalOutDir.Trim() -eq "") {
  $scriptDir = $PSScriptRoot
  if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
  if (-not $scriptDir) { throw "Cannot resolve script directory for default -LocalOutDir" }
  $LocalOutDir = Join-Path $scriptDir "_ubuntu_out"
}

$ErrorActionPreference = "Stop"

function Exec([string]$cmd) {
  Write-Host "[ubuntu_run_pipeline.ps1] $cmd"
  iex $cmd
}

function Exec-RemoteBash(
  [string]$RemoteSpec,
  [string[]]$SshArgs,
  [string]$Script
) {
  # 通过 Base64 传递脚本，避免 PowerShell 对 > < | 的重定向/管道符进行本地解析。
  $b64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($Script))
  $remote = "bash -lc 'echo $b64 | base64 -d | bash'"
  Write-Host "[ubuntu_run_pipeline.ps1] ssh $($SshArgs -join ' ') $RemoteSpec <remote-bash>"
  & ssh @SshArgs $RemoteSpec $remote | Out-Host
}

function Get-RemoteFileSha1(
  [string]$RemoteSpec,
  [string[]]$SshArgs,
  [string]$RemotePath
) {
  try {
    # 用纯 bash 取第一个字段，避免 awk/引号层级导致的兼容性问题。
    $out = & ssh @SshArgs $RemoteSpec "bash -lc 'sha1sum "$RemotePath" 2>/dev/null | { read -r a b; echo $a; }'"
    if (-not $out) { return $null }
    $s = ($out | Out-String).Trim()
    if (-not $s) { return $null }
    return $s
  } catch {
    return $null
  }
}

function Resolve-SshIdentityArgs([string]$keyPath) {
  # 如果用户指定的 key 不存在，则尝试常见默认 key；如果仍没有，则返回空（让 ssh/scp 自己走 agent/交互）。
  $candidates = @()
  if ($keyPath) { $candidates += $keyPath }

  $sshDir = Join-Path $env:USERPROFILE ".ssh"
  $candidates += @(
    (Join-Path $sshDir "id_ed25519"),
    (Join-Path $sshDir "id_rsa"),
    (Join-Path $sshDir "id_ecdsa"),
    (Join-Path $sshDir "id_dsa")
  )

  foreach ($c in $candidates) {
    if ($c -and (Test-Path $c)) {
      Write-Host "[ubuntu_run_pipeline.ps1] Using SSH identity: $c"
      return $c
    }
  }

  Write-Warning "SSH identity file not found (tried: $($candidates -join ', ')). Will try without -i (ssh-agent / interactive password)."
  return $null
}

function Find-TargetLocationInIndex(
  [string]$ApiName,
  [string]$IndexPath,
  [string]$RemoteSpec,
  [string[]]$SshArgs
) {
  # 在远端 Ubuntu 上解析 rag/index.json，查找包含该函数名的 (dll,file)。
  # 返回：@{ Dll = "..."; File = "..." }；找不到/多于 1 个则 throw。
  $py = @'
import json, sys

api = sys.argv[2]
idx_path = sys.argv[3]

with open(idx_path, 'r', encoding='utf-8') as f:
    idx = json.load(f)

hits = []
for dll_name, dll in idx.get('dlls', {}).items():
    for file_name, file_info in dll.get('files', {}).items():
        funcs = file_info.get('functions', [])
        if isinstance(funcs, list):
            for fi in funcs:
                if isinstance(fi, dict) and fi.get('name') == api:
                    hits.append((dll_name, file_name))
                    break
        elif isinstance(funcs, dict):
            if api in funcs:
                hits.append((dll_name, file_name))

if len(hits) == 0:
    print('NOT_FOUND')
    sys.exit(0)
if len(hits) > 1:
    print('MULTIPLE')
    for dll_name, file_name in hits:
        print(f'{dll_name}\t{file_name}')
    sys.exit(0)

dll_name, file_name = hits[0]
print(f'ONE\n{dll_name}\t{file_name}')
'@

  $RemoteIndexPath = $IndexPath
  # 注意：PowerShell 字符串里出现 `<<`/`<` 会被当作重定向/保留运算符解析，导致脚本本地就 ParseError。
  # 为了稳定/可移植：把 Python 程序做 Base64，通过 `python3 -c` 执行，参数用 argv 传递。
  $pyB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($py))
  # 这里直接在远端执行 python3（不再额外套 bash -lc），避免出现意外的嵌套 bash -lc。
  # 注意 decode() 里必须有引号：decode("utf-8")，否则 bash 会把 (utf-8) 当成语法。
  $cmd = 'python3 -c ''import base64,sys;code=base64.b64decode(sys.argv[1]).decode();exec(code)'' ' +
    "'$pyB64' '$ApiName' '$RemoteIndexPath'"
  $out = & ssh @SshArgs $RemoteSpec $cmd
  if (-not $out) { throw "Auto-lookup failed: empty output" }

  $lines = ($out | Out-String).Trim() -split "`r?`n"
  if ($lines[0] -eq 'NOT_FOUND') {
    throw "Auto-lookup: function '$ApiName' not found in index: $RemoteIndexPath"
  }
  if ($lines[0] -eq 'MULTIPLE') {
    $cands = $lines[1..($lines.Length-1)] -join ', '
    throw "Auto-lookup: multiple candidates for '$ApiName' in index: $cands. Please pass -TargetDll/-TargetFile explicitly."
  }
  if ($lines[0] -ne 'ONE' -or $lines.Length -lt 2) {
    throw "Auto-lookup failed: unexpected output: $($lines -join '; ')"
  }
  $parts = $lines[1] -split "\t"
  if ($parts.Length -lt 2) { throw "Auto-lookup failed: bad line: $($lines[1])" }
  return @{ Dll = $parts[0]; File = $parts[1] }
}

# 计算本地 oda_demo 根目录
$OdaDemoRoot = (Resolve-Path (Join-Path $PSScriptRoot ".." )).Path  # oda_demo/

# 远程路径
$RemoteOdaDir = "$UbuntuWorkDir/oda_demo"

# out/<api> 现在可能包含 run_<timestamp>/ 子目录（LLM 模式默认写入），用 last_run.txt 指向最新一次。
$RemoteOutDirBase = "$RemoteOdaDir/out/" + $ApiName.ToLower()

# 注意：$RemoteSpec/$SshArgs 在后面才构造，所以这里先占位，稍后再根据 last_run.txt 决定最终 RemoteOutDir。
$RemoteOutDir = $RemoteOutDirBase

function Get-RemoteLastRunOutDir(
  [string]$RemoteSpec,
  [string[]]$SshArgs,
  [string]$RemoteOutDirBase
) {
  $lastRunPath = "$RemoteOutDirBase/last_run.txt"
  try {
  # Avoid all quoting pitfalls by not invoking python/bash at all: just cat the file if it exists.
  $cmd = "test -f '$lastRunPath' && cat '$lastRunPath' || true"
  $out = & ssh @SshArgs $RemoteSpec $cmd
    if (-not $out) { return $null }
    $p = ($out | Out-String).Trim()
    if (-not $p) { return $null }
    return $p
  } catch {
    return $null
  }
}

$RemoteCasesPath = "$RemoteOutDir/test_cases.bin"
$RemoteOraclePath = "$RemoteOutDir/oracle.bin"
$RemoteReportPath = "$RemoteOutDir/wine_check_report.txt"

# WineCheck-only 模式优化：如果本地已经有 test_cases.bin 且不需要重新录制 oracle，
# 就不必再次跑远端 KLEE/pipeline，也避免 scp 下载时清理目录误删本地 oracle。
$SkipRemotePipelineAndDownload = $false
if ($WineCheck -and (-not $RecordOracleLocal)) {
  $existingLocalApiOut = Join-Path $LocalOutDir $ApiName.ToLower()
  $existingLocalCases = Join-Path $existingLocalApiOut "test_cases.bin"
  if (Test-Path $existingLocalCases) {
    $SkipRemotePipelineAndDownload = $true
    Write-Host "[ubuntu_run_pipeline.ps1] WineCheck-only: local test_cases.bin exists, skip remote pipeline/download: $existingLocalCases"
  }
}

# scp/ssh 选项（关闭 hostkey 交互，便于自动化）
$IdentityArg = Resolve-SshIdentityArgs $UbuntuKey

$SshArgs = @()
$ScpArgs = @()
if ($IdentityArg) {
  $SshArgs += @('-i', $IdentityArg)
  $ScpArgs += @('-i', $IdentityArg)
}

# 注意：ssh 的端口参数是 -p；scp 的端口参数是 -P（大小写不同）
$SshArgs += @('-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', '-p', "$UbuntuPort")
$ScpArgs += @('-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null', '-P', "$UbuntuPort")

# 0) 端口可达性检查（可选；默认关闭以避免 Test-NetConnection 的交互输出污染 scp 日志）
if ($PreflightTcpCheck) {
  try {
    $tnc = Test-NetConnection -ComputerName $UbuntuHost -Port $UbuntuPort -WarningAction SilentlyContinue
    if (-not $tnc.TcpTestSucceeded) {
      throw "TCP connect to ${UbuntuHost}:${UbuntuPort} failed (Connection refused/timeout). Ensure Ubuntu sshd is running and VM networking/port-forwarding allows access."
    }
  } catch {
    throw $_
  }
}

# PowerShell 里 `xxx:$path` 可能被解析成“驱动器语法”，因此 remote spec 用拼接字符串构造。
$RemoteSpec = ("{0}@{1}" -f $UbuntuUser, $UbuntuHost)

# 记录本地/远端关键脚本的 sha1，确认 scp 后远端确实更新到最新版本。
$LocalPipelinePath = Join-Path $OdaDemoRoot "scripts/ubuntu_run_pipeline.sh"
$LocalPipelineSha1 = $null
if (Test-Path $LocalPipelinePath) {
  try {
    $LocalPipelineSha1 = (Get-FileHash -Algorithm SHA1 $LocalPipelinePath).Hash.ToLower()
    Write-Host "[ubuntu_run_pipeline.ps1] Local ubuntu_run_pipeline.sh sha1: $LocalPipelineSha1"
  } catch {
    # ignore
  }
}

# 现在 ssh 参数和 RemoteSpec 都准备好了。
# 注意：llm 模式的 run_<timestamp> 输出目录是在远端 pipeline *运行之后* 才创建/更新 last_run.txt，
# 所以这里先不要读 last_run.txt；下载阶段会在远端跑完后再读取并切换到最新目录。

# 0.5) 验证公钥认证是否可用（避免后续命令卡在交互式密码提示）
try {
  Write-Host "[ubuntu_run_pipeline.ps1] ssh $($SshArgs -join ' ') -o BatchMode=yes $RemoteSpec \"true\""
  & ssh @SshArgs -o BatchMode=yes $RemoteSpec "true" | Out-Host
} catch {
  Write-Warning "Public-key auth check failed. If you expect key auth, verify Ubuntu ~/.ssh/authorized_keys and permissions (700 ~/.ssh, 600 authorized_keys). The script may fall back to interactive password if allowed."
}

if (-not $SkipRemotePipelineAndDownload) {
  # 1) 创建远程 workdir
  Write-Host "[ubuntu_run_pipeline.ps1] ssh $($SshArgs -join ' ') $RemoteSpec \"mkdir -p $UbuntuWorkDir\""
  & ssh @SshArgs $RemoteSpec "mkdir -p $UbuntuWorkDir" | Out-Host

  # 2) 同步 oda_demo（保守策略：整目录上传；后续可以优化成只传必要子集）
  # Windows scp 在目录拷贝时需要 -r
  $RemoteUpload = $RemoteSpec + ":" + "$UbuntuWorkDir/"
  Write-Host "[ubuntu_run_pipeline.ps1] scp $($ScpArgs -join ' ') -r \"$OdaDemoRoot\" \"$RemoteUpload\""
  & scp @ScpArgs -r "$OdaDemoRoot" "$RemoteUpload" | Out-Host

  # scp 完后校验远端脚本 sha1，确保 VM 上运行的是最新版本。
  if ($LocalPipelineSha1) {
    $remoteSha1 = Get-RemoteFileSha1 -RemoteSpec $RemoteSpec -SshArgs $SshArgs -RemotePath "$RemoteOdaDir/scripts/ubuntu_run_pipeline.sh"
    Write-Host "[ubuntu_run_pipeline.ps1] Remote ubuntu_run_pipeline.sh sha1: $remoteSha1"
    if ($remoteSha1 -and ($remoteSha1.ToLower() -ne $LocalPipelineSha1)) {
      Write-Warning "Remote ubuntu_run_pipeline.sh sha1 mismatch (local=$LocalPipelineSha1 remote=$remoteSha1). VM may still be running an older script copy."
    }
  }

  # 3) 确保脚本可执行并运行 Ubuntu driver
  # 组装 LLM 环境变量（仅在 StubMode=llm 时注入）
  # 为避免 PowerShell/ssh/bash 多层引号坑，以及 key 中特殊字符，统一使用 base64 注入：
  #   echo <b64> | base64 -d | while read -r v; do export VAR="$v"; done
  # 注意：不要在这里生成包含 bash 的 $() 命令替换的字符串；PowerShell 会在本地解析 `$(`，
  # 导致把 `base64` 当成 PowerShell 命令执行并报错。
  $RemoteEnvPrefix = ""
  if ($StubMode -eq "llm") {
    if (-not $TargetDll -or -not $TargetFile) {
      # 自动反查：从远端 rag/index.json 找到该 API 所在 dll/file
      $remoteIndex = "$RemoteOdaDir/rag/index.json"
      Write-Host "[ubuntu_run_pipeline.ps1] StubMode=llm: -TargetDll/-TargetFile missing, auto-looking up in index: $remoteIndex"
      $hit = Find-TargetLocationInIndex -ApiName $ApiName -IndexPath $remoteIndex -RemoteSpec $RemoteSpec -SshArgs $SshArgs
      $TargetDll = $hit.Dll
      $TargetFile = $hit.File
      Write-Host "[ubuntu_run_pipeline.ps1] Auto-lookup result: TargetDll=$TargetDll TargetFile=$TargetFile"
    }

    # api key 优先用参数；否则尝试读取本机同名环境变量（便于不把 key 写进命令行历史）
    $key = $LlmApiKey
    if (-not $key) { $key = $env:ODA_LLM_API_KEY }
    if (-not $key) { $key = $env:OPENAI_API_KEY }
    if (-not $key) { throw "Missing LLM api key. Provide -LlmApiKey or set env ODA_LLM_API_KEY/OPENAI_API_KEY" }

    $model = $LlmModel
    if (-not $model) { $model = $env:ODA_LLM_MODEL }
    if (-not $model) { throw "Missing LLM model. Provide -LlmModel or set env ODA_LLM_MODEL" }

    $b64 = {
      param([string]$s)
      [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($s))
    }

    $keyB64 = (& $b64 $key)
    $modelB64 = (& $b64 $model)
    $RemoteEnvAssignments = @(
      "ODA_LLM_API_KEY_B64=$keyB64",
      "ODA_LLM_MODEL_B64=$modelB64"
    )

    # 强制每次 llm 都创建新的 run 目录，避免 last_run.txt/工件复用旧目录。
    $RemoteEnvAssignments += "ODA_FORCE_NEW_RUN=1"
    if ($LlmBaseUrl) {
      $RemoteEnvAssignments += "ODA_LLM_BASE_URL_B64=$(& $b64 $LlmBaseUrl)"
    }
    if ($LlmTemperature) {
      $RemoteEnvAssignments += "ODA_LLM_TEMPERATURE_B64=$(& $b64 $LlmTemperature)"
    }
    if ($LlmMaxTokens) {
      $RemoteEnvAssignments += "ODA_LLM_MAX_TOKENS_B64=$(& $b64 $LlmMaxTokens)"
    }

    # 代理透传（用于 Ubuntu 侧走 Clash）
    $proxyHttp = $env:HTTP_PROXY
    $proxyHttps = $env:HTTPS_PROXY
    $proxyAll = $env:ALL_PROXY
    $proxyNo = $env:NO_PROXY
  if ($proxyHttp) { $RemoteEnvAssignments += "HTTP_PROXY_B64=$(& $b64 $proxyHttp)" }
  if ($proxyHttps) { $RemoteEnvAssignments += "HTTPS_PROXY_B64=$(& $b64 $proxyHttps)" }
  if ($proxyAll) { $RemoteEnvAssignments += "ALL_PROXY_B64=$(& $b64 $proxyAll)" }
  if ($proxyNo) { $RemoteEnvAssignments += "NO_PROXY_B64=$(& $b64 $proxyNo)" }

    # 在远端 bash 内解码并 export。
    # 关键点：这里拼出来的远端命令字符串中不能出现 `$(`，否则 PowerShell 在本地解析子表达式。
  $RemoteEnvPrefix = ('export ' + ($RemoteEnvAssignments -join ' ')) + '; ' +
      'echo "$ODA_LLM_API_KEY_B64" | base64 -d > .oda_llm_key.tmp; ' +
      'echo "$ODA_LLM_MODEL_B64"  | base64 -d > .oda_llm_model.tmp; ' +
    'read -r ODA_LLM_API_KEY_VAL < .oda_llm_key.tmp; ' +
    'read -r ODA_LLM_MODEL_VAL < .oda_llm_model.tmp; ' +
      'export ODA_LLM_API_KEY="$ODA_LLM_API_KEY_VAL"; ' +
      'export ODA_LLM_MODEL="$ODA_LLM_MODEL_VAL"; ' +
      'rm -f .oda_llm_key.tmp .oda_llm_model.tmp; ' +
    'if [ -n "$ODA_LLM_BASE_URL_B64" ]; then echo "$ODA_LLM_BASE_URL_B64" | base64 -d > .oda_llm_base.tmp; read -r ODA_LLM_BASE_URL_VAL < .oda_llm_base.tmp; export ODA_LLM_BASE_URL="$ODA_LLM_BASE_URL_VAL"; rm -f .oda_llm_base.tmp; fi; ' +
    'if [ -n "$ODA_LLM_TEMPERATURE_B64" ]; then echo "$ODA_LLM_TEMPERATURE_B64" | base64 -d > .oda_llm_temp.tmp; read -r ODA_LLM_TEMPERATURE_VAL < .oda_llm_temp.tmp; export ODA_LLM_TEMPERATURE="$ODA_LLM_TEMPERATURE_VAL"; rm -f .oda_llm_temp.tmp; fi; ' +
    'if [ -n "$ODA_LLM_MAX_TOKENS_B64" ]; then echo "$ODA_LLM_MAX_TOKENS_B64" | base64 -d > .oda_llm_max.tmp; read -r ODA_LLM_MAX_TOKENS_VAL < .oda_llm_max.tmp; export ODA_LLM_MAX_TOKENS="$ODA_LLM_MAX_TOKENS_VAL"; rm -f .oda_llm_max.tmp; fi; ' +
    'if [ -n "$HTTP_PROXY_B64" ]; then echo "$HTTP_PROXY_B64" | base64 -d > .oda_proxy_http.tmp; read -r HTTP_PROXY_VAL < .oda_proxy_http.tmp; export HTTP_PROXY="$HTTP_PROXY_VAL"; export http_proxy="$HTTP_PROXY_VAL"; rm -f .oda_proxy_http.tmp; fi; ' +
    'if [ -n "$HTTPS_PROXY_B64" ]; then echo "$HTTPS_PROXY_B64" | base64 -d > .oda_proxy_https.tmp; read -r HTTPS_PROXY_VAL < .oda_proxy_https.tmp; export HTTPS_PROXY="$HTTPS_PROXY_VAL"; export https_proxy="$HTTPS_PROXY_VAL"; rm -f .oda_proxy_https.tmp; fi; ' +
    'if [ -n "$ALL_PROXY_B64" ]; then echo "$ALL_PROXY_B64" | base64 -d > .oda_proxy_all.tmp; read -r ALL_PROXY_VAL < .oda_proxy_all.tmp; export ALL_PROXY="$ALL_PROXY_VAL"; export all_proxy="$ALL_PROXY_VAL"; rm -f .oda_proxy_all.tmp; fi; ' +
    'if [ -n "$NO_PROXY_B64" ]; then echo "$NO_PROXY_B64" | base64 -d > .oda_proxy_no.tmp; read -r NO_PROXY_VAL < .oda_proxy_no.tmp; export NO_PROXY="$NO_PROXY_VAL"; export no_proxy="$NO_PROXY_VAL"; rm -f .oda_proxy_no.tmp; fi;'
  }

  # 注意：远端命令统一通过 `bash -lc` 执行，这样我们可以安全地在远端做 export/base64 -d，
  # 避免 PowerShell 本地把 `$(...)`/`base64` 误当作自己要执行的命令。
  $RemoteCmdInner = @(
    "set -e",
    "cd $RemoteOdaDir",
    "chmod +x scripts/ubuntu_run_pipeline.sh",
    $(
      if ($DumpKtestTool -or ($DumpKtestToolDir -and $DumpKtestToolDir.Trim() -ne "")) {
        # 优先用明确目录；否则用脚本内置的 env shortcut 让它 dump 到 outdir 下。
        if ($DumpKtestToolDir -and $DumpKtestToolDir.Trim() -ne "") {
          $(
            $argsLine = "./scripts/ubuntu_run_pipeline.sh --api $ApiName --wine-root $WineSrcRoot --dump-ktest-tool $DumpKtestToolDir --stub-mode $StubMode"
            if ($StubMode -eq "llm") { $argsLine += " --target-dll $TargetDll --target-file $TargetFile" }
            if ($RemoteEnvPrefix) { "$RemoteEnvPrefix $argsLine" } else { $argsLine }
          )
        } else {
          $(
            $argsLine = "ODA_DUMP_KTEST_TOOL=1 ./scripts/ubuntu_run_pipeline.sh --api $ApiName --wine-root $WineSrcRoot --stub-mode $StubMode"
            if ($StubMode -eq "llm") { $argsLine += " --target-dll $TargetDll --target-file $TargetFile" }
            if ($RemoteEnvPrefix) { "$RemoteEnvPrefix $argsLine" } else { $argsLine }
          )
        }
      } else {
        $(
          $argsLine = "./scripts/ubuntu_run_pipeline.sh --api $ApiName --wine-root $WineSrcRoot --stub-mode $StubMode"
          if ($StubMode -eq "llm") { $argsLine += " --target-dll $TargetDll --target-file $TargetFile" }
          if ($RemoteEnvPrefix) { "$RemoteEnvPrefix $argsLine" } else { $argsLine }
        )
      }
    )
  ) -join "; "

  # 用 bash -lc 包裹，避免本地 PowerShell 解释其中的 $() / base64
  $RemoteCmd = "bash -lc '$RemoteCmdInner'"

  Write-Host "[ubuntu_run_pipeline.ps1] ssh $($SshArgs -join ' ') $RemoteSpec \"$RemoteCmd\""
  & ssh @SshArgs $RemoteSpec $RemoteCmd | Out-Host

  # 4.5) llm 模式：远端已经生成新的 run_* 目录并写入 last_run.txt；现在读取并切换下载源目录。
  if ($StubMode -eq "llm") {
    # 额外诊断：打印 last_run.txt 和最近的 run_* 目录，确认 run 刷新是否真的发生。
  Exec-RemoteBash -RemoteSpec $RemoteSpec -SshArgs $SshArgs -Script @"
echo [post-run] last_run:
cat "$RemoteOutDirBase/last_run.txt" 2>/dev/null || true
echo [post-run] latest runs:
ls -1dt "$RemoteOutDirBase"/run_* 2>/dev/null | head -n 5 || true
echo [post-run] pipeline script sha1:
sha1sum /home/guren/oda_work/oda_demo/scripts/ubuntu_run_pipeline.sh 2>/dev/null || true
echo [post-run] pipeline llm snippet:
python3 -c "from pathlib import Path; txt=Path('/home/guren/oda_work/oda_demo/scripts/ubuntu_run_pipeline.sh').read_text(encoding='utf-8', errors='ignore').splitlines(); needle=('FORCE_NEW_RUN','ODA_FORCE_NEW_RUN','RUN_ID=','RANDOM'); [print(str(i+1)+': '+line) for i,line in enumerate(txt) if any(n in line for n in needle)]"
"@

    $last = Get-RemoteLastRunOutDir -RemoteSpec $RemoteSpec -SshArgs $SshArgs -RemoteOutDirBase $RemoteOutDirBase
    if ($last) {
      Write-Host "[ubuntu_run_pipeline.ps1] Using remote last_run.txt outdir (post-run): $last"
      $RemoteOutDir = $last
    } else {
      Write-Host "[ubuntu_run_pipeline.ps1] last_run.txt not found after run; fallback to base outdir: $RemoteOutDirBase"
      $RemoteOutDir = $RemoteOutDirBase
    }
  }
  # 4) 拉回产物
  New-Item -ItemType Directory -Force -Path $LocalOutDir | Out-Null

  # 清理旧目录前，先备份本地 oracle（避免 WineCheck-only 场景误删）
  $LocalApiOut = Join-Path $LocalOutDir $ApiName.ToLower()
  $oracleBackup = $null
  $existingOracle = Join-Path $LocalApiOut "oracle.bin"
  if (Test-Path $existingOracle) {
    $oracleBackup = Join-Path $LocalOutDir ("oracle.bin.backup.{0}" -f $ApiName.ToLower())
    Copy-Item -Force $existingOracle $oracleBackup
  }

  if (Test-Path $LocalApiOut) { Remove-Item -Recurse -Force $LocalApiOut }

  if ($DownloadWinePrefix) {
    # 全量拉回（包含 wineprefix_win64）
    $RemoteDownload = $RemoteSpec + ":" + "$RemoteOutDir"
    Write-Host "[ubuntu_run_pipeline.ps1] scp $($ScpArgs -join ' ') -r \"$RemoteDownload\" \"$LocalOutDir/\""
    & scp @ScpArgs -r "$RemoteDownload" "$LocalOutDir/" | Out-Host
  } else {
    # 最小集合拉回：避开 wineprefix_win64（Windows scp 对 dosdevices/c:: 等符号链接会报错）
    $LocalApiOut = Join-Path $LocalOutDir $ApiName.ToLower()
    New-Item -ItemType Directory -Force -Path $LocalApiOut | Out-Null

    $remoteFiles = @(
      "oda_stubs.c",
      "test_cases.bin",
      "oracle.bin",
      "wine_check_raw.txt",
      "wine_check_report.txt",
      "wine_test_runner.exe",
      "wine_compile_log.txt",
      # LLM 可观测性产物（只有 llm 模式才会产生；存在才下载）
      "llm_prompt.txt",
      "llm_response.txt",
      "llm_spec.json",
      "llm_error.txt",
      # LLM 诊断/检索/谓词/校验工件（新版 generate_oda_with_llm.py 输出；存在才下载）
      "llm_diag.json",
    "env_proxy.json",
      "retrieval_report.json",
      "predicate_ir.json",
      "stub_validation_report.json",
      "run.stats",
      "run.istats",
      "warnings.txt",
      "messages.txt",
      "info",
      "assembly.ll",
      "paths.ts",
      "symPaths.ts"
    )

    foreach ($f in $remoteFiles) {
      $remotePath = "$RemoteOutDir/$f"
      # 远端探测：文件存在才下载。
      # 这里不要给 $remotePath 再额外套一层 "..."，否则会变成 bash -lc 'test -e "..."'
      # 在 bash 中会触发 unmatched quote（" 会被当作普通字符，反而破坏外层引号配对）。
      try {
        & ssh @SshArgs $RemoteSpec "bash -lc 'test -e $remotePath'" | Out-Null
      } catch {
        continue
      }

      $r = $RemoteSpec + ":" + $remotePath
      Write-Host "[ubuntu_run_pipeline.ps1] scp $($ScpArgs -join ' ') \"$r\" \"$LocalApiOut/\""
      & scp @ScpArgs "$r" "$LocalApiOut/" | Out-Host
    }

    # ktest 体积通常不大，但数量多；这里尽量拉回整个 klee-out-0 目录
    $rklee = $RemoteSpec + ":" + "$RemoteOutDir/klee-out-0"
    Write-Host "[ubuntu_run_pipeline.ps1] scp $($ScpArgs -join ' ') -r \"$rklee\" \"$LocalApiOut/\""
    & scp @ScpArgs -r "$rklee" "$LocalApiOut/" | Out-Host
  }

  if ($oracleBackup -and (Test-Path $oracleBackup)) {
    $restoredOracle = Join-Path $LocalApiOut "oracle.bin"
    Copy-Item -Force $oracleBackup $restoredOracle
    Remove-Item -Force $oracleBackup
  }
} else {
  $LocalApiOut = Join-Path $LocalOutDir $ApiName.ToLower()
}

Write-Host "[ubuntu_run_pipeline.ps1] DONE"
Write-Host "[ubuntu_run_pipeline.ps1] Local artifacts: $LocalApiOut"
Write-Host "  - oda_stubs.c"
Write-Host "  - test_cases.bin"
Write-Host "  - oracle.bin (if -RecordOracleLocal)"
Write-Host "  - wine_check_report.txt (if -WineCheck)"
Write-Host "  - klee-out-0/*.ktest"

function Ensure-Local-TestRunnerExe([string]$exePath) {
  if (Test-Path $exePath) { return }

  $runnerDir = $PSScriptRoot
  $src = Join-Path $runnerDir "test_runner.c"
  $hdr = Join-Path $runnerDir "wine_test.h"

  if (-not (Test-Path $src)) { throw "Missing: $src" }
  if (-not (Test-Path $hdr)) { throw "Missing: $hdr" }

  # 尽量用 cl.exe；如果没有则退回 gcc（MinGW）。
  $cl = Get-Command cl.exe -ErrorAction SilentlyContinue
  if ($cl) {
    Write-Host "[ubuntu_run_pipeline.ps1] Building test_runner.exe with MSVC cl.exe"
    $winSdk = $env:WindowsSdkDir
    Push-Location $runnerDir
    try {
      & cl.exe /nologo /O2 /W3 /DWIN32_LEAN_AND_MEAN test_runner.c /link Shlwapi.lib /out:$exePath | Out-Host
    } finally {
      Pop-Location
    }
    if (-not (Test-Path $exePath)) { throw "Build failed (MSVC), missing: $exePath" }
    return
  }

  $gcc = Get-Command gcc.exe -ErrorAction SilentlyContinue
  if ($gcc) {
    Write-Host "[ubuntu_run_pipeline.ps1] Building test_runner.exe with gcc (MinGW)"
    Push-Location $runnerDir
    try {
      & gcc.exe test_runner.c -o $exePath -lshlwapi | Out-Host
    } finally {
      Pop-Location
    }
    if (-not (Test-Path $exePath)) { throw "Build failed (gcc), missing: $exePath" }
    return
  }

  throw "No compiler found. Install MSVC Build Tools (cl.exe) or MinGW (gcc.exe), or disable -RecordOracleLocal."
}

if ($RecordOracleLocal -or $WineCheck) {
  # 5) 本机 Windows 录制 oracle.bin
  $localCases = Join-Path $LocalApiOut "test_cases.bin"
  if (-not (Test-Path $localCases)) {
    throw "Missing local test_cases.bin: $localCases"
  }

  $localRunnerExe = Join-Path $PSScriptRoot "test_runner.exe"
  Ensure-Local-TestRunnerExe $localRunnerExe

  if ($RecordOracleLocal) {
    $localOracle = Join-Path $LocalApiOut "oracle.bin"
    Write-Host "[ubuntu_run_pipeline.ps1] Recording oracle locally: $localOracle"
    & $localRunnerExe --record $localCases $localOracle --target $ApiName | Out-Host
    if (-not (Test-Path $localOracle)) { throw "oracle.bin not created: $localOracle" }
  }

  if ($WineCheck) {
    $localOracle = Join-Path $LocalApiOut "oracle.bin"
    if (-not (Test-Path $localOracle)) {
      throw "oracle.bin missing: $localOracle (enable -RecordOracleLocal first or provide oracle manually)"
    }

    # 6) 上传 oracle.bin，并在 Ubuntu/Wine 下对比
    $remoteUploadOracle = $RemoteSpec + ":" + $RemoteOraclePath
  Write-Host "[ubuntu_run_pipeline.ps1] scp $($ScpArgs -join ' ') \"$localOracle\" \"$remoteUploadOracle\""
  & scp @ScpArgs "$localOracle" "$remoteUploadOracle" | Out-Host

    $remoteWineCmd = @(
      "set -e",
      "cd $RemoteOdaDir",
      "chmod +x scripts/ubuntu_wine_check.sh",
      "./scripts/ubuntu_wine_check.sh --api $ApiName --cases $RemoteCasesPath --oracle $RemoteOraclePath --outdir $RemoteOutDir --arch win64 --wineprefix $RemoteOutDir/wineprefix_win64"
    ) -join "; "

  Write-Host "[ubuntu_run_pipeline.ps1] ssh $($SshArgs -join ' ') $RemoteSpec \"$remoteWineCmd\""
  & ssh @SshArgs $RemoteSpec $remoteWineCmd | Out-Host

    # 7) 拉回报告
    $localReport = Join-Path $LocalApiOut "wine_check_report.txt"
    $remoteDownloadReport = $RemoteSpec + ":" + $RemoteReportPath
    Write-Host "[ubuntu_run_pipeline.ps1] scp $($ScpArgs -join ' ') \"$remoteDownloadReport\" \"$localReport\""
    & scp @ScpArgs "$remoteDownloadReport" "$localReport" | Out-Host
    Write-Host "[ubuntu_run_pipeline.ps1] Wine check report downloaded: $localReport"
  }
}

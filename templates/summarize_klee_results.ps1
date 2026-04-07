param(
  [Parameter(Mandatory=$true)][string]$KleeOutDir
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $KleeOutDir)) {
  throw "KLEE output dir not found: $KleeOutDir"
}

$resolved = (Resolve-Path $KleeOutDir).Path
Write-Host "[INFO] Analyzing KLEE output: $resolved"

function Parse-RunStats([string]$path) {
  if (-not (Test-Path $path)) { return $null }
  $lines = Get-Content $path | Where-Object { $_ -and (-not $_.StartsWith('#')) }
  if ($lines.Count -lt 2) { return $null }
  $header = ($lines[0] -split '\s+') | Where-Object { $_ }
  $data = ($lines[1] -split '\s+') | Where-Object { $_ }
  $stats = @{}
  for ($i = 0; $i -lt [Math]::Min($header.Count, $data.Count); $i++) {
    $stats[$header[$i]] = $data[$i]
  }
  return $stats
}

function Parse-Messages([string]$path) {
  if (-not (Test-Path $path)) { return @{ doneLine = $null; warnings = @() } }
  $lines = Get-Content $path
  $doneLine = $lines | Where-Object { $_ -match 'KLEE: done:' } | Select-Object -Last 1
  $warnings = $lines | Where-Object { $_ -match 'KLEE: WARNING' }
  return @{ doneLine = $doneLine; warnings = $warnings }
}

$ktestFiles = Get-ChildItem -Path $resolved -Filter '*.ktest' -File -Recurse
$ktestCount = $ktestFiles.Count

$runStatsPath = Join-Path $resolved 'run.stats'
$runIstatsPath = Join-Path $resolved 'run.istats'
$messagesPath = Join-Path $resolved 'messages.txt'

$stats = Parse-RunStats -path $runStatsPath
$msgs = Parse-Messages -path $messagesPath

Write-Host "[SUMMARY] Test cases (*.ktest): $ktestCount"
if ($stats) {
  $keys = @('CompletedPaths', 'States', 'Branches', 'Forks', 'Icov', 'Icount', 'MaxMem')
  foreach ($k in $keys) {
    if ($stats.ContainsKey($k)) {
      Write-Host ("[SUMMARY] {0}: {1}" -f $k, $stats[$k])
    }
  }
  # If common fields missing, dump all for debugging
  $missing = $keys | Where-Object { -not $stats.ContainsKey($_) }
  if ($missing.Count -eq $keys.Count) {
    Write-Host "[DETAIL] run.stats header: $($stats.Keys -join ', ')"
  }
} else {
  Write-Host "[WARN] run.stats not found or unparsable"
}

if ($msgs.doneLine) {
  Write-Host "[SUMMARY] $($msgs.doneLine.Trim())"
}
if ($msgs.warnings.Count -gt 0) {
  Write-Host "[WARN] KLEE warnings:" 
  $msgs.warnings | ForEach-Object { Write-Host "  $_" }
}

if (Test-Path $runIstatsPath) {
  Write-Host "[INFO] run.istats present (use klee-stats for detailed coverage if installed)."
} else {
  Write-Host "[INFO] run.istats not found."
}

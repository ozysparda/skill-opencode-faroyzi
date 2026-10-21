<#
.SYNOPSIS
  Ambil & tampilkan hasil run (report.json) dari GitHub Actions.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\verify-run.ps1
  powershell -ExecutionPolicy Bypass -File .\verify-run.ps1 -RunId 39554508122
  powershell -ExecutionPolicy Bypass -File .\verify-run.ps1 -Workflow free-likes-hosted.yml -Limit 5
#>
[CmdletBinding()]
param(
  [string]$RunId = '',
  [string]$Workflow = '',
  [int]$Limit = 3,
  [string]$Repo = 'ozysparda/gh-free-likes'
)

$ErrorActionPreference = 'Stop'
function Write-Step($m) { Write-Host "`n>> $m" -ForegroundColor Cyan }

if (-not $RunId) {
  Write-Step "Run terakhir ($Workflow)"
  $args2 = @('run', 'list', '--repo', $Repo, '--limit', "$Limit")
  if ($Workflow) { $args2 += @('--workflow', $Workflow) }
  $rows = & gh @args2 2>&1
  $rows | ForEach-Object { Write-Host "   $_" }
  $line = $rows | Where-Object { $_ -match '\t' } | Select-Object -First 1
  if (-not $line) { Write-Host "Tidak ada run."; exit 0 }
  $cols = $line -split "`t"
  $RunId = ($cols | Where-Object { $_ -match '^\d{10,}$' } | Select-Object -First 1)
  if (-not $RunId) { Write-Host "ID run tidak ketemu dari output."; exit 0 }
}

Write-Step "Unduh report run $RunId"
$tmp = Join-Path $env:TEMP ("ighist_" + $RunId)
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $tmp | Out-Null
& gh run download $RunId --repo $Repo --dir $tmp 2>&1 | Out-Null

$json = Get-ChildItem $tmp -Recurse -Filter *.json -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $json) {
  Write-Host "   [!] Tidak ada report.json (run mungkin tidak menghasilkan report)."
  Write-Host "   Lihat log: gh run view $RunId --repo $Repo --log"
  exit 0
}

$j = Get-Content $json.FullName -Raw | ConvertFrom-Json
Write-Host ""
Write-Host ("   Ringkasan: ok={0} gagal={1} likes_diklaim={2}" -f $j.summary.ok, $j.summary.fail, $j.summary.likes_claimed)
Write-Host ("   mulai={0} selesai={1}" -f $j.started, $j.finished)
Write-Host ""
Write-Host ("   {0,-20} {1,-6} {2,5}  {3}" -f 'SERVICE','HASIL','LIKES','CATATAN') -ForegroundColor Cyan
foreach ($r in $j.results) {
  $mark = if ($r.ok) { 'OK' } else { '--' }
  Write-Host ("   {0,-20} {1,-6} {2,5}  {3}" -f $r.service, $mark, $r.likes, $r.note)
}

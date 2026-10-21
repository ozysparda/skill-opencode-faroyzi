<#
.SYNOPSIS
  Promote deployment preview BBNEWS ke production, lalu tunggu sampai READY.

.DESCRIPTION
  Push ke branch `vercel` hanya menghasilkan deployment preview. Production
  branch di Vercel adalah `main`, jadi publication harus lewat promote.

  Token dibaca dari environment variable VERCEL_TOKEN (lihat README repo ini).

.PARAMETER DeploymentId
  Id deployment yang mau dipromote (contoh: dpl_xxx). Kalau kosong, skrip
  memilih deployment preview READY terbaru pada branch yang diberikan.

.PARAMETER CommitSha
  Optional. Prefix sha commit yang HARUS cocok (mis. 7 karakter pertama).
  Pakai ini supaya tidak salah promote preview lama saat build baru masih jalan.

.PARAMETER DryRun
  Hanya mencari & menampilkan kandidat deployment, tanpa promote.

.EXAMPLE
  $env:VERCEL_TOKEN = 'vcp_...'
  powershell -ExecutionPolicy Bypass -File .\promote-latest.ps1 -Branch vercel

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\promote-latest.ps1 -DryRun
#>
[CmdletBinding()]
param(
  [string]$DeploymentId = '',
  [string]$Branch = 'vercel',
  [string]$TeamId = $(if ($env:VERCEL_TEAM_ID) { $env:VERCEL_TEAM_ID } else { 'ozyyyy310304s-projects' }),
  [string]$Token = $env:VERCEL_TOKEN,
  [string]$ProjectId = $(if ($env:VERCEL_PROJECT_ID) { $env:VERCEL_PROJECT_ID } else { 'prj_rHyWehSu30eyddSdCtMrT7OAQm9J' }),
  [string]$ProjectName = 'bbnews',
  [string]$CommitSha = '',
  [int]$TimeoutSeconds = 600,
  [int]$PollSeconds = 5,
  [switch]$DryRun
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Token)) {
  throw "VERCEL_TOKEN belum diset. Isi dari file token, contoh:`n`$env:VERCEL_TOKEN = ((Get-Content `"$env:TEMP\opencode\vercel-token.txt`") | Select-String 'vcp_').ToString().Trim()"
}

$headers = @{ Authorization = "Bearer $Token" }
$teamQ = "?teamId=$TeamId"

function Get-Deployment([string]$Id) {
  $uri = "https://api.vercel.com/v13/deployments/$Id$teamQ"
  return Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
}

if ([string]::IsNullOrWhiteSpace($DeploymentId)) {
  Write-Host "Mencari deployment preview READY terbaru pada branch '$Branch'..."
  $listUri = "https://api.vercel.com/v6/deployments?projectId=$ProjectId&teamId=$TeamId&limit=15"
  $list = Invoke-RestMethod -Uri $listUri -Headers $headers -Method Get

  $candidate = $list.deployments |
    Where-Object {
      $_.state -eq 'READY' -and
      -not $_.target -and
      ($_.meta.githubCommitRef -eq $Branch) -and
      ($CommitSha -eq '' -or $_.meta.githubCommitSha -like "$CommitSha*")
    } |
    Sort-Object created -Descending |
    Select-Object -First 1

  if (-not $candidate) {
    if ($CommitSha -ne '') {
      throw "Tidak ada preview READY untuk commit '$CommitSha' di branch '$Branch'. Tunggu build selesai lalu ulangi."
    }
    throw "Tidak ada deployment preview READY untuk branch '$Branch'. Cek state di Vercel Dashboard."
  }

  $DeploymentId = $candidate.uid
  $sha = if ($candidate.meta.githubCommitSha) { $candidate.meta.githubCommitSha.Substring(0, 7) } else { '?' }
  Write-Host "Dipilih: $DeploymentId  (commit $sha, branch $Branch)"
}

if ($DryRun) {
  Write-Host ""
  Write-Host "DRY RUN - tidak ada promote yang dilakukan." -ForegroundColor Yellow
  exit 0
}

Write-Host "Promote $DeploymentId ke production..."
$body = @{
  name         = $ProjectName
  deploymentId = $DeploymentId
  target       = 'production'
} | ConvertTo-Json

$promoted = Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments$teamQ" `
  -Headers $headers -Method Post -ContentType 'application/json' -Body $body

$newId = $promoted.id
Write-Host "Deployment production baru: $newId (state $($promoted.readyState))"

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
$dep = $null
while ((Get-Date) -lt $deadline) {
  Start-Sleep -Seconds $PollSeconds
  $dep = Get-Deployment $newId
  Write-Host ("  state = {0}" -f $dep.readyState)
  if ($dep.readyState -in @('READY', 'ERROR', 'CANCELED')) { break }
}

if (-not $dep -or $dep.readyState -ne 'READY') {
  throw "Deploy tidak READY. Status: $($dep.readyState). Lihat log build di Vercel."
}

Write-Host ""
Write-Host "PRODUCTION READY"
Write-Host ("  url   : " + $dep.url)
Write-Host ("  alias : " + (($dep.alias | ForEach-Object { "https://$_" }) -join ', '))
exit 0

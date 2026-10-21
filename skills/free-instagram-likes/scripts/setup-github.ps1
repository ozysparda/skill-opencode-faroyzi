<#
.SYNOPSIS
  Siapkan automation free Instagram likes di PC baru (repo + secrets + run).

.DESCRIPTION
  Langkah:
    1. Clone repo kode `ozysparda/gh-free-likes` (kalau belum ada).
    2. Pasang dependency (playwright + chromium).
    3. Set GitHub Secrets yang dibutuhkan (dari file kredensial lokal bila ada).
    4. Verifikasi: repo public, workflow terdaftar, 1 run manual dipicu.

  Token/password TIDAK pernah ditulis ke dalam repo; hanya ke GitHub Secrets
  atau file lokal di luar repo.

.PARAMETER RepoPath
  Lokasi clone repo kode. Default: <folder skill>/../../../gh-free-likes atau
  folder di bawah direktori kerja skill.

.PARAMETER SecretFile
  File lokal berisi baris `NAMA=VALUE` untuk secret (opsional).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\setup-github.ps1
  powershell -ExecutionPolicy Bypass -File .\setup-github.ps1 -RepoPath C:\work\gh-free-likes
#>
[CmdletBinding()]
param(
  [string]$RepoPath = '',
  [string]$SecretFile = '',
  [string]$Repo = 'ozysparda/gh-free-likes',
  [switch]$SkipDeps,
  [switch]$SkipTrigger
)

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Write-Step($m) { Write-Host "`n>> $m" -ForegroundColor Cyan }
function Write-Ok($m)   { Write-Host "   [OK] $m" -ForegroundColor Green }
function Write-Warn($m) { Write-Host "   [!] $m" -ForegroundColor Yellow }
function Write-Err($m)  { Write-Host "   [X] $m" -ForegroundColor Red }

Write-Host "==============================================" -ForegroundColor DarkCyan
Write-Host " Setup Free Instagram Likes Automation" -ForegroundColor DarkCyan
Write-Host "=============================================="

# ------------------------------------------------------------------ 1. Repo ---
Write-Step "Clone repo kode"
if (-not $RepoPath) {
  $RepoPath = Join-Path (Split-Path -Parent $skillRoot) 'gh-free-likes'
}
if (Test-Path (Join-Path $RepoPath '.git')) {
  Write-Ok "Sudah ada: $RepoPath"
  git -C $RepoPath pull --ff-only 2>&1 | Out-Null
} else {
  git clone "https://github.com/$Repo.git" $RepoPath 2>&1 | Out-Null
  if (Test-Path (Join-Path $RepoPath '.git')) { Write-Ok "Clone: $RepoPath" }
  else { Write-Err "Clone gagal." }
}

# ------------------------------------------------------------------ 2. Deps ---
if (-not $SkipDeps) {
  Write-Step "Install dependency"
  Push-Location $RepoPath
  python -m pip install --upgrade pip 2>&1 | Out-Null
  python -m pip install -r requirements.txt 2>&1 | Out-Null
  python -m playwright install chromium 2>&1 | Out-Null
  Pop-Location
  Write-Ok "Playwright + chromium siap."
}

# --------------------------------------------------------------- 3. Secrets ---
Write-Step "Set GitHub Secrets"
$need = @('CAPTCHA_NO_KEY','SOLVERCF_KEY','MAILTM_ADDR','MAILTM_PASSWORD','IG_EMAIL','IG_LINK')
if ($SecretFile -and (Test-Path $SecretFile)) {
  Get-Content $SecretFile | Where-Object { $_ -match '=' } | ForEach-Object {
    $k, $v = $_ -split '=', 2
    $k = $k.Trim(); $v = $v.Trim()
    if ($v) {
      $v | gh secret set $k --repo $Repo 2>&1 | Out-Null
      Write-Ok "$k diset."
    }
  }
} else {
  Write-Warn "SecretFile tidak dipakai. Set manual:"
  foreach ($s in $need) {
    Write-Host "     gh secret set $s --repo $Repo"
  }
  Write-Host "   (opsional: GMAIL_APP_PASSWORD, PROXY_URL)"
}

# ------------------------------------------------------------------ 4. Cek ---
Write-Step "Verifikasi"
try {
  $vis = gh repo view $Repo --json visibility -q .visibility 2>$null
  if ($vis -eq 'public') { Write-Ok "Repo PUBLIC (minutes unlimited)." }
  else { Write-Warn "Repo $vis. Jadikan PUBLIC agar minutes unlimited." }
} catch { Write-Warn "Tidak bisa cek visibility (token?)." }

gh workflow list --repo $Repo 2>&1 | Out-String | Write-Host

if (-not $SkipTrigger) {
  Write-Step "Trigger 1 run manual (tes)"
  gh workflow run free-likes-hosted.yml --repo $Repo -f max_orders=4 -f pace=30 2>&1 | Out-Null
  Write-Ok "Run dipicu. Cek: gh run list --repo $Repo --limit 3"
}

Write-Host "`nSelesai. Detail: docs/memory/07-ig-likes-automation.md" -ForegroundColor Green

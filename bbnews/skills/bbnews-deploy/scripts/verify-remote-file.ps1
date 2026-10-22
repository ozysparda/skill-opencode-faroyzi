<#
.SYNOPSIS
  Bandingkan isi berkas lokal dengan isi yang benar-benar ada di GitHub.

.DESCRIPTION
  Dipakai setelah commit/push untuk memastikan remote berisi berkas yang
  dimaksud - bukan hanya "commit-nya sukses".

 _exit code 0 = cocok, 1 = berbeda._

  Catatan penting (Windows): git mengonversi LF -> CRLF saat checkout bila
  `core.autocrlf=true`, jadi berkas lokal bisa 1 baris lebih panjang per baris
  dari versi di GitHub. Perbandingan karena itu dilakukan pada bentuk teks
  dengan line ending dinormalisasi, dan perbedaan jumlah byte dilaporkan
  terpisah sebagai informasi.

.SOURCE
  Sumber pembanding:
    1. `git show <ref>:<path>` (isi persis yang tersimpan di Git) - dipakai bila
       ref tersedia di clone lokal.
    2. `https://raw.githubusercontent.com/<owner>/<repo>/<ref>/<path>` - cadangan
       kalau ref tidak ada di lokal.

.PARAMETER Path
  Path relatif di dalam repo, contoh:
  artifacts/balebeleq-web/src/pages/admin/article-form.tsx

.PARAMETER Ref
  Ref GitHub yang dibandingkan. Default: branch `vercel`. Boleh juga sha commit.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\verify-remote-file.ps1 `
    -Path 'artifacts/balebeleq-web/src/pages/admin/article-form.tsx'
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)][string]$Path,
  [string]$Ref = 'vercel',
  [string]$Owner = 'ozysparda',
  [string]$Repo = 'BBNEWS',
  [string]$RepoRoot = 'C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git',
  [string]$GitExe = ''
)

$ErrorActionPreference = 'Stop'

# PENTING: output native command (git) harus dibaca sebagai UTF-8. Tanpa ini
# PowerShell memakai codepage console (CP437/CP850) dan karakter non-ASCII
# (mis. "±") jadi rusak -> file yang sebenarnya sama dilaporkan "BERBEDA".
try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$OutputEncoding = [Text.Encoding]::UTF8

function Normalize([string]$text) {
  if ($null -eq $text) { return '' }
  $t = $text -replace "`r`n", "`n"
  $t = $t -replace "`r", "`n"
  return $t.TrimEnd("`n")
}

$localPath = Join-Path $RepoRoot ($Path -replace '/', '\')
if (-not (Test-Path $localPath)) { throw "Berkas lokal tidak ada: $localPath" }

$localRaw = [IO.File]::ReadAllText($localPath)
$localNorm = Normalize $localRaw

# ------------------------------------------------------- ambil isi remote ---
$remoteNorm = $null
$source = ''

if (-not $GitExe) {
  $cmd = Get-Command git -ErrorAction SilentlyContinue
  if ($cmd) { $GitExe = $cmd.Source }
  elseif (Test-Path 'C:\Program Files\Git\cmd\git.exe') { $GitExe = 'C:\Program Files\Git\cmd\git.exe' }
}

if ($GitExe -and (Test-Path (Join-Path $RepoRoot '.git'))) {
  $lines = & $GitExe -C $RepoRoot show "${Ref}:$Path" 2>$null
  if ($LASTEXITCODE -eq 0 -and $null -ne $lines) {
    $remoteNorm = Normalize (($lines -join "`n"))
    $source = "git show ${Ref}:$Path"
  }
}

if ($null -eq $remoteNorm) {
  $url = "https://raw.githubusercontent.com/$Owner/$Repo/$Ref/$Path"
  $tmp = Join-Path ([IO.Path]::GetTempPath()) ("gh-verify-" + [Guid]::NewGuid().ToString('N') + ".txt")
  try {
    Invoke-WebRequest -UseBasicParsing -Uri $url -OutFile $tmp
    $remoteNorm = Normalize ([IO.File]::ReadAllText($tmp))
    $source = $url
  } catch {
    throw "Gagal mengambil isi remote: $($_.Exception.Message)"
  } finally {
    if (Test-Path $tmp) { Remove-Item $tmp -Force }
  }
}

# ------------------------------------------------------------------ laporkan ---
$localBytes  = [IO.File]::ReadAllBytes($localPath)
$remoteBytes = [Text.Encoding]::UTF8.GetBytes($remoteNorm)

Write-Host "sumber   : $source"
Write-Host ("lokal    : {0} byte ({1} baris)" -f $localBytes.Length, ($localNorm -split "`n").Count)
Write-Host ("remote   : {0} byte ({1} baris)" -f $remoteBytes.Length, ($remoteNorm -split "`n").Count)

if ($localBytes.Length -ne $remoteBytes.Length) {
  Write-Host "catatan  : selisih ukuran FILE karena konversi line ending git (CRLF vs LF) di Windows." -ForegroundColor DarkGray
}

if ($localNorm -ceq $remoteNorm) {
  Write-Host "IDENTIK - isi remote sama persis dengan repo lokal." -ForegroundColor Green
  exit 0
}

Write-Host "BERBEDA - remote tidak sama dengan lokal." -ForegroundColor Yellow
Write-Host "Lihat diff:" -ForegroundColor Yellow
Write-Host ("  & '{0}' -C '{1}' diff {2} -- '{3}'" -f $GitExe, $RepoRoot, $Ref, $Path) -ForegroundColor DarkGray
exit 1

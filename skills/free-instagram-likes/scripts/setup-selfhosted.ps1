# Setup self-hosted runner (Windows) - 1 perintah
#
# Dipakai untuk workflow "Free IG Likes (self-hosted / IP rumah)":
# service yang butuh IP residential (SMM8, Grum, Skweezer, Famesathi,
# FastSocial, SMMNut, GetLikes, NiceSMM, buyfans).
# IP GitHub-hosted (datacenter) diblokir service2 ini.
#
# CARA PAKAI:
#   1) GitHub -> Settings -> Actions -> Runners -> New self-hosted runner
#      - Operating system: Windows
#      - Architecture: x64
#      - Labels: (biarkan default, runner akan pakai label "self-hosted,linux"
#        -> ubah runs-on di workflow ke [self-hosted, windows] kalau Windows)
#   2) Salin command download yang ditampilkan GitHub, jalankan
#   3) Jalankan file ini (atau ikut command dari GitHub)
#
$ErrorActionPreference = "Stop"
$dir = "$env:USERPROFILE\actions-runner"
$repo = "ozysparda/gh-free-likes"

if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
Set-Location $dir

if (-not (Test-Path "config.cmd")) {
    Write-Host "[1/3] Download runner..." -ForegroundColor Cyan
    $url = "https://github.com/actions/runner/releases/latest/download/actions-runner-win-x64.zip"
    Invoke-WebRequest -Uri $url -OutFile "runner.zip"
    Expand-Archive -Path "runner.zip" -DestinationPath "." -Force
    Remove-Item "runner.zip" -Force
}

Write-Host "[2/3] Konfigurasi runner ke $repo ..." -ForegroundColor Cyan
$token = Read-Host "Masukkan token runner (dari GitHub > Settings > Actions > Runners > New runner)"
.\config.cmd --unattended --url "https://github.com/$repo" --token $token --labels "self-hosted,linux" --name "laptop-faroyzii" --work "_work" --replace

Write-Host "[3/3] Menjalankan runner (Ctrl+C untuk stop)" -ForegroundColor Green
Write-Host "Biarkan jendela ini terbuka agar runner online 24/7." -ForegroundColor Yellow
.\run.cmd

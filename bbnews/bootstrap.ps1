<#
.SYNOPSIS
  Siapkan satu PC baru agar bisa menjalankan pekerjaan OpenCode persis seperti
  di PC utama: skill terinstall, memory terpasang, repo ter-clone, kredensial
  git siap.

.DESCRIPTION
  Jalankan skrip ini di dalam clone repo skill (repo ini):

      git clone https://github.com/ozysparda/skill-opencode-faroyzi.git
      cd skill-opencode-faroyzi
      powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1

  Yang dilakukan:
    1. Memastikan Git terpasang (opsional pasang lewat winget).
    2. Menginstal semua skill ke ~/.config/opencode/skills.
    3. Memasang memory global di ~/.config/opencode/AGENTS.md.
    4. Clone/update repo kerja BBNEWS (branch vercel).
    5. Menyiapkan kredensial git bila file token GitHub tersedia.

  Token TIDAK pernah disimpan di dalam repo skill.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
  powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -SkipGitInstall -SkipClone
#>
[CmdletBinding()]
param(
  [string]$RepoPath = '',
  [string]$SkillsTarget = '',
  [string]$TokenFile = '',
  [switch]$SkipGitInstall,
  [switch]$SkipClone,
  [switch]$SkipMemory
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

function Write-Step($msg) { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "   [OK] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "   [!] $msg" -ForegroundColor Yellow }
function Write-Err($msg)  { Write-Host "   [X] $msg" -ForegroundColor Red }

Write-Host "==============================================" -ForegroundColor DarkCyan
Write-Host " Bootstrap skill-opencode-faroyzi" -ForegroundColor DarkCyan
Write-Host "==============================================" -ForegroundColor DarkCyan

# ---------------------------------------------------------------- 1. Git ---
Write-Step "Memeriksa Git"
$git = $null
$gitCmd = Get-Command git -ErrorAction SilentlyContinue
if ($gitCmd) {
  $git = $gitCmd.Source
} elseif (Test-Path 'C:\Program Files\Git\cmd\git.exe') {
  $git = 'C:\Program Files\Git\cmd\git.exe'
}

if ($git) {
  Write-Ok "Git: $git ($((& $git --version)))"
} else {
  Write-Warn "Git belum ditemukan."
  if ($SkipGitInstall) {
    Write-Err "Lewati pemasangan karena -SkipGitInstall. Pasang manual dari https://git-scm.com/download/win"
  } else {
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
      Write-Host "   Memasang Git lewat winget (bisa memakan waktu 1-3 menit)..."
      & winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements | Out-Host
      if (Test-Path 'C:\Program Files\Git\cmd\git.exe') {
        $git = 'C:\Program Files\Git\cmd\git.exe'
        $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($cur -notlike '*Git\cmd*') {
          [Environment]::SetEnvironmentVariable('Path', $cur.TrimEnd(';') + ';C:\Program Files\Git\cmd', 'User')
          Write-Ok "Git dipasang & 'C:\Program Files\Git\cmd' ditambahkan ke PATH user."
        }
        Write-Ok "Git: $git ($((& $git --version)))"
      } else {
        Write-Err "Pemasangan Git via winget tidak menghasilkan path yang diharapkan."
      }
    } else {
      Write-Err "winget tidak tersedia. Pasang manual dari https://git-scm.com/download/win"
    }
  }
}

# ------------------------------------------------------------- 2. Skills ---
Write-Step "Menginstal skill"
& (Join-Path $repoRoot 'install.ps1') -Target $SkillsTarget
Write-Ok "Skill siap (buka sesi OpenCode baru agar terdeteksi)."

# ------------------------------------------------------------- 3. Memory ---
if (-not $SkipMemory) {
  Write-Step "Memasang memory global (~/.config/opencode/AGENTS.md)"
  $cfgDir = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $env:USERPROFILE '.config' }
  $ocDir  = Join-Path $cfgDir 'opencode'
  $agents = Join-Path $ocDir 'AGENTS.md'
  New-Item -ItemType Directory -Force -Path $ocDir | Out-Null

  $begin = '<!-- BEGIN: skill-opencode-faroyzi -->'
  $end   = '<!-- END: skill-opencode-faroyzi -->'
  # Catatan: pakai here-string tunggal supaya backtick (markdown code) tidak
  # diperlakukan sebagai escape karakter oleh PowerShell.
  # Marker dipakai agar blok ini bisa hidup berdampingan dengan blok bundle
  # lain di AGENTS.md (mis. bundle free-instagram-likes).
  $template = @'
__BEGIN__
## Memory: bundle BBNEWS (skill-opencode-faroyzi)

Bundle ini berada di subfolder `bbnews/` repo `ozysparda/skill-opencode-faroyzi`
(clone: `git clone https://github.com/ozysparda/skill-opencode-faroyzi.git`,
lalu jalankan `bbnews\bootstrap.ps1`).

- Memory indeks: `bbnews/MEMORY.md`
- Fakta proyek BBNEWS: `bbnews/docs/memory/01-proyek-bbnews.md`
- Insiden & solusi: `bbnews/docs/memory/02-insiden-dan-solusi.md`
- Alur kerja terminal: `bbnews/docs/memory/03-alur-kerja-terminal.md`
- Trik browser tools: `bbnews/docs/memory/04-trik-browser-tools.md`
- Token & kredensial: `bbnews/docs/memory/05-token-dan-kredensial.md`
- QA & baseline: `bbnews/docs/memory/06-qa-dan-baseline.md`
- Standar skill OpenCode + audit semua skill: `bbnews/docs/memory/07-skill-opencode-dan-audit.md`

Skill terpasang di `~/.config/opencode/skills/`: `bbnews-deploy`,
`github-commit-terminal`.

Aturan global: jangan pernah menaruh token/password di dalam repo; verifikasi
byte remote-vs-lokal setelah commit (ingat normalisasi CRLF/LF di Windows);
data artikel harus dijaga (baseline terbaru: 3 artikel = 3 terbit + 0 draft,
views naik mengikuti traffic).

Standar skill (detail di dokumen 07): skill hanya dibaca dari `SKILL.md`
(bukan `skill.json`); `skills` di config OpenCode harus array path;
presedensi project > global (salinan di `.opencode/skills/` mengalahkan versi
global); file `.ps1` untuk Windows PowerShell 5.1 disimpan dengan UTF-8 + BOM.
__END__
'@
  $block = $template.Replace('__BEGIN__', $begin).Replace('__END__', $end)

  if (Test-Path $agents) {
    $current = Get-Content $agents -Raw -Encoding UTF8
    # Blok lama dibuang lalu ditulis ulang, supaya isinya selalu sinkron.
    $pattern = [regex]::Escape($begin) + '[\s\S]*?' + [regex]::Escape($end)
    if ($current -match $pattern) {
      $current = [regex]::Replace($current, $pattern, '')
      $current = $current.TrimEnd() + "`n`n" + $block + "`n"
      Set-Content -Path $agents -Value $current -Encoding UTF8 -NoNewline
      Write-Ok "Blok memory diperbarui di AGENTS.md."
    } else {
      Add-Content -Path $agents -Value ("`n" + $block) -Encoding UTF8
      Write-Ok "Blok memory ditambahkan ke AGENTS.md."
    }
  } else {
    Set-Content -Path $agents -Value $block -Encoding UTF8 -NoNewline
    Write-Ok "AGENTS.md dibuat."
  }
}

# -------------------------------------------------------------- 4. Clone ---
if (-not $SkipClone) {
  Write-Step "Menyiapkan repo kerja BBNEWS"
  if (-not $git) {
    Write-Warn "Lewati clone karena git tidak tersedia."
  } else {
    if (-not $RepoPath) {
      # bbnews/ -> skill-opencode-faroyzi/ -> folder kerja (luar repo)
      $parent = Split-Path -Parent (Split-Path -Parent $repoRoot)
      $RepoPath = Join-Path $parent 'bbnews-git'
    }
    if (Test-Path (Join-Path $RepoPath '.git')) {
      Write-Host "   Update: $RepoPath"
      & $git -C $RepoPath pull --ff-only origin vercel | Out-Host
    } else {
      Write-Host "   Clone: $RepoPath"
      & $git clone --branch vercel --single-branch https://github.com/ozysparda/BBNEWS.git $RepoPath | Out-Host
    }
    if (Test-Path (Join-Path $RepoPath '.git')) {
      Write-Ok "Repo siap di $RepoPath"
    } else {
      Write-Err "Clone gagal."
    }
  }
}

# --------------------------------------------------------- 5. Kredensial ---
Write-Step "Menyiapkan kredensial git"
if (-not $TokenFile) {
  $candidate = Join-Path $env:TEMP 'opencode\github-token.txt'
  if (Test-Path $candidate) { $TokenFile = $candidate }
}

if ($git -and $TokenFile -and (Test-Path $TokenFile)) {
  $gh = ((Get-Content $TokenFile -Raw) | Select-String 'ghp_[A-Za-z0-9]+')
  if ($gh) {
    $token = $gh.Matches[0].Value
    $credPath = Join-Path $env:USERPROFILE '.git-credentials'
    Set-Content -Path $credPath -Value "https://ozysparda:$token@github.com" -NoNewline -Encoding ASCII
    & $git config --global credential.helper store
    Write-Ok "Credential store diperbarui ($credPath)."
    Write-Host "   Uji akses: & '$git' -C '$RepoPath' push --dry-run origin vercel"
  } else {
    Write-Warn "Isi file token tidak recognizable (butuh pola ghp_...)."
  }
} else {
  Write-Warn "File token GitHub tidak ditemukan. Isi manual:"
  Write-Host "   1. Buat PAT: https://github.com/settings/tokens/new (scope repo, No expiration)"
  Write-Host "   2. Simpan ke %TEMP%\opencode\github-token.txt"
  Write-Host "   3. Jalankan ulang: .\bootstrap.ps1 -TokenFile <path>"
}

# ------------------------------------------------------------ 6. Ringkasan ---
Write-Step "Ringkasan"
if ($git) { Write-Host "   git          : $git" }
if ($SkillsTarget) {
  Write-Host "   skills       : $SkillsTarget"
} else {
  $dest = if ($env:XDG_CONFIG_HOME) { Join-Path $env:XDG_CONFIG_HOME 'opencode\skills' } else { Join-Path $env:USERPROFILE '.config\opencode\skills' }
  Write-Host "   skills       : $dest"
}
Write-Host "   memory       : $(Join-Path $env:USERPROFILE '.config\opencode\AGENTS.md')"
if ($RepoPath) { Write-Host "   repo BBNEWS  : $RepoPath" }

Write-Host "`nSelesai. Buka sesi OpenCode baru untuk memakai skill & memory." -ForegroundColor Green
Write-Host "Contoh: minta 'deploy BerugakNews dengan skill bbnews-deploy'." -ForegroundColor Green

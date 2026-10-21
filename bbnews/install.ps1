<#
.SYNOPSIS
  Install skill dari repo ini ke folder skill global OpenCode.

.DESCRIPTION
  Menyalin setiap folder di `skills/` ke `~/.config/opencode/skills/`
  (atau $env:XDG_CONFIG_HOME\opencode\skills). Folder yang sudah ada ditimpa.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  powershell -ExecutionPolicy Bypass -File .\install.ps1 -Target 'D:\my-skills'
#>
[CmdletBinding()]
param(
  [string]$Target = '',
  [switch]$List
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $repoRoot 'skills'

if (-not (Test-Path $source)) { throw "Folder skills tidak ditemukan: $source" }

if ($Target) {
  $dest = $Target
} elseif ($env:XDG_CONFIG_HOME) {
  $dest = Join-Path $env:XDG_CONFIG_HOME 'opencode\skills'
} else {
  $dest = Join-Path $env:USERPROFILE '.config\opencode\skills'
}

if ($List) {
  Get-ChildItem -Path $source -Directory | ForEach-Object { $_.Name }
  exit 0
}

New-Item -ItemType Directory -Force -Path $dest | Out-Null
$count = 0

Get-ChildItem -Path $source -Directory | ForEach-Object {
  $skill = $_
  $target = Join-Path $dest $skill.Name
  if (Test-Path $target) { Remove-Item $target -Recurse -Force }
  Copy-Item -Path $skill.FullName -Destination $target -Recurse -Force
  Write-Host ("  + {0}" -f $skill.Name)
  $count++
}

Write-Host ""
Write-Host ("{0} skill terinstall ke {1}" -f $count, $dest)
Write-Host "Buka sesi OpenCode baru supaya skill terdeteksi."

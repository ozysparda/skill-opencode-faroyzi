# ============================================================
#  Auto-start + auto-restart runner GitHub Actions (Windows)
#  - jalan otomatis saat laptop nyala / user login
#  - restart sendiri tiap 3 jam ( cegah memory leak)
#  - tidak butuh admin
# ============================================================
$ErrorActionPreference = "Continue"
$dir = "$env:USERPROFILE\actions-runner"
$startup = [Environment]::GetFolderPath("Startup")

if (-not (Test-Path "$dir\run.cmd")) {
    Write-Host "runner belum ada di $dir" -ForegroundColor Red
    exit 1
}

# ---------- 1) shortcut di folder Startup ----------
$bat = Join-Path $startup "actions-runner-autostart.cmd"
@"
@echo off
title GitHub Actions Runner
cd /d "%USERPROFILE%\actions-runner"
echo [%%date%% %%time%%] Menjalankan runner...
run.cmd --nohup >> "%USERPROFILE%\actions-runner\runner.log" 2>&1
"@ | Set-Content -Path $bat -Encoding ascii
Write-Host "[1/3] Startup shortcut dibuat: $bat" -ForegroundColor Green

# ---------- 2) registry Run (fallback, tanpa admin) ----------
$rk = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
if (-not (Test-Path $rk)) { New-Item -Path $rk -Force | Out-Null }
Set-ItemProperty -Path $rk -Name "ActionsRunner" -Value "cmd /c `"$bat`"" -Force
Write-Host "[2/3] Registry Run entry dipasang" -ForegroundColor Green

# ---------- 3) scheduled task: restart tiap 3 jam ----------
$taskName = "ActionsRunner-Keeper"
$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c `"$bat`""
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
$trigger2 = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(3)
$trigger2.Repetition = @{ Interval = "PT3H"; Duration = "P1D" }
$trigger2.Enabled = $true
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -ExecutionTimeLimit (New-TimeSpan -Hours 23)
try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName $taskName -Action $action -Trigger @($trigger, $trigger2) `
        -Principal $principal -Settings $settings -Description "Keep GitHub Actions runner alive" -Force | Out-Null
    Write-Host "[3/3] Scheduled task '$taskName' dibuat (re-run tiap 3 jam)" -ForegroundColor Green
} catch {
    Write-Host "[3/3] Gagal buat scheduled task: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "        (shortcut Startup + registry Run tetap aktif)" -ForegroundColor Yellow
}

# ---------- status ----------
Write-Host ""
Write-Host "=== STATUS ===" -ForegroundColor Cyan
$w = Get-Process -Name "Runner.Worker" -ErrorAction SilentlyContinue
if ($w) { Write-Host "Runner: AKTIF (PID $($w.Id -join ','))" -ForegroundColor Green }
else { Write-Host "Runner: MATI -> start manual: cd $dir; .\run.cmd" -ForegroundColor Yellow }

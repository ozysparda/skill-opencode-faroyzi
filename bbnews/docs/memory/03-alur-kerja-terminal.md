# 03 — Alur Kerja Terminal (end-to-end)

Semua perintah di bawah memakai **PowerShell** di Windows. Jalur git dibungkus
variabel `$git` supaya aman dipakai di PC lain.

## 0. Persiapan satu kali

```powershell
$git = 'C:\Program Files\Git\cmd\git.exe'
& $git --version
```

## 1. Clone / update repo kerja

```powershell
$repo = 'C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git'

# kalau foldernya belum ada
& $git clone --branch vercel --single-branch https://github.com/ozysparda/BBNEWS.git $repo

# kalau sudah ada
& $git -C $repo pull --ff-only origin vercel
& $git -C $repo status --short --branch
```

## 2. Edit kode

Lokasi penting:

| Path | Isi |
| --- | --- |
| `artifacts/balebeleq-web/src/pages/admin/article-form.tsx` | form admin + upload gambar |
| `artifacts/api-server/src/routes/storage.ts` | route `/api/storage/upload-token` |
| `scripts/vercel-build.mjs` | konfigurasi build + runtime function |

Setelah edit, selalu lihat diff:

```powershell
& $git -C $repo diff --stat
& $git -C $repo diff -- artifacts/balebeleq-web/src/pages/admin/article-form.tsx
```

## 3. Commit & push

```powershell
& $git -C $repo add -A
& $git -C $repo commit -m "Perbaiki upload gambar: pakai pathname dari token"
& $git -C $repo push origin vercel
```

Catatan:

- Selalu pakai `-m` supaya tidak masuk editor interaktif.
- Satu perubahan logis = satu commit.
- Jangan pernah `git push --force` ke branch `vercel` tanpa izin pemilik proyek;
  pakai commit baru atau `git revert`.
- Kalau commit-nya salah: `& $git -C $repo revert --no-edit <sha>` lalu push.

## 4. Tunggu preview, lalu promote ke production

Push ke `vercel` hanya menghasilkan **deployment preview**. Production branch di
Vercel = `main`, jadi harus promote.

### Cara A - pakai skrip di repo skill (disarankan)

```powershell
$env:VERCEL_TOKEN  = ((Get-Content "$env:TEMP\opencode\vercel-token.txt") | Select-String 'vcp_').ToString().Trim()
$env:VERCEL_TEAM_ID = 'ozyyyy310304s-projects'

powershell -ExecutionPolicy Bypass -File `
  'C:\Users\Dunia Imajinasiku\Documents\Default Project\skill-opencode-faroyzi\bbnews\skills\bbnews-deploy\scripts\promote-latest.ps1' `
  -Branch vercel
```

Opsi:

- `-DeploymentId dpl_xxx` -> promote deployment tertentu.
- `-DryRun` -> hanya mencari & menampilkan kandidat, tidak promote.

### Cara B - manual dengan Invoke-RestMethod

```powershell
$headers = @{ Authorization = "Bearer $env:VERCEL_TOKEN" }
$team    = 'ozyyyy310304s-projects'

# daftar deployment terbaru
$list = Invoke-RestMethod -Uri "https://api.vercel.com/v6/deployments?projectId=prj_rHyWehSu30eyddSdCtMrT7OAQm9J&teamId=$team&limit=15" -Headers $headers
$list.deployments | Select-Object uid, state, target, created, @{n='sha';e={$_.meta.githubCommitSha}}, @{n='branch';e={$_.meta.githubCommitRef}} | Format-Table -AutoSize

# promote
$body = @{ name='bbnews'; deploymentId='dpl_xxx'; target='production' } | ConvertTo-Json
$new  = Invoke-RestMethod -Method Post -Uri "https://api.vercel.com/v13/deployments?teamId=$team" `
          -Headers $headers -ContentType 'application/json' -Body $body

# tunggu READY
for ($i=0; $i -lt 60; $i++) {
  Start-Sleep -Seconds 5
  $d = Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments/$($new.id)?teamId=$team" -Headers $headers
  Write-Host $d.readyState
  if ($d.readyState -in @('READY','ERROR','CANCELED')) { break }
}
$d.alias
```

### Cara C - curl (Linux/macOS)

```bash
curl -sS -X POST "https://api.vercel.com/v13/deployments?teamId=$VERCEL_TEAM_ID" \
  -H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"bbnews","deploymentId":"dpl_xxx","target":"production"}'
```

## 5. Verifikasi (wajib, jangan dilewati)

a. **Byte remote == byte lokal**

```powershell
powershell -ExecutionPolicy Bypass -File `
  '...\skill-opencode-faroyzi\bbnews\skills\bbnews-deploy\scripts\verify-remote-file.ps1' `
  -Path 'artifacts/balebeleq-web/src/pages/admin/article-form.tsx'
```

Alternatif:

```powershell
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/ozysparda/BBNEWS/vercel/artifacts/balebeleq-web/src/pages/admin/article-form.tsx' -OutFile tmp.bin
(Get-FileHash tmp.bin -Algorithm SHA256).Hash -eq (Get-FileHash '<file-lokal>' -Algorithm SHA256).Hash
```

**Jebakan PowerShell (sudah diperbaiki 22 Okt 2026):** output native command
(`git show`) dibaca memakai codepage console (CP437/CP850), jadi karakter
non-ASCII jadi rusak -> file yang sebenarnya identik dilaporkan "BERBEDA".
Skrip `verify-remote-file.ps1` sekarang set `[Console]::OutputEncoding = UTF8`.
Kalau masih perlu cek manual, bandingkan **blob SHA** (bukan isi teks):

```powershell
git rev-parse "vercel:<path>"        # SHA blob di remote
git hash-object "<file-lokal>"       # SHA blob file lokal (setara, sudah dinormalisasi)
```

Kedua SHA harus sama persis. Cara ini bebas masalah encoding & line ending.

b. **Deployment READY + production**

```powershell
Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments/<id>?teamId=ozyyyy310304s-projects" -Headers $headers |
  Select-Object id, readyState, target, url
```

c. **Data artikel utuh**

```powershell
(Invoke-RestMethod 'https://berugaknews.vercel.app/api/articles?limit=100').articles | Measure-Object
```

Baseline: 2 artikel published publik (total di admin: 3 = 2 terbit + 1 draft),
142 views.

d. **Fungsi yang diperbaiki** - contoh upload gambar: buka
   `https://berugaknews.vercel.app/admin/artikel/baru`, login, pilih file PNG
   kecil, pastikan URL blob muncul di field dan preview tampil.

## 6. Rollback

Kalau deployment production bermasalah:

```powershell
# 1. cari deployment READY sebelumnya
& $git -C $repo log --oneline -10
# 2. revert commit yang bermasalah lalu push (preview baru)
& $git -C $repo revert --no-edit <sha>
& $git -C $repo push origin vercel
# 3. promote preview yang baru seperti langkah 4
```

Rollback paling cepat tanpa kode baru: promote deployment lama yang masih READY.

## 7. Membersihkan file sisa

File tes upload (blob) bisa dihapus lewat dashboard Vercel > Storage > Blob >
file `uploads/1792509104276-tes-upload.png` (68 byte). Tidak wajib, tapi rapi.

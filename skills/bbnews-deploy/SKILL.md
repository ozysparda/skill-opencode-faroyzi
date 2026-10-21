---
name: Deploy BerugakNews (BBNEWS)
description: Kelola dan deploy situs BerugakNews (repo BBNEWS, proyek Vercel bbnews) lewat terminal - edit kode, commit/push ke GitHub, promote preview ke production, serta memverifikasi upload gambar dan integritas data artikel.
---

# Deploy BerugakNews (BBNEWS)

Skill ini untuk memodifikasi dan mendeploy situs berita **BerugakNews**
(`berugaknews.vercel.app`) yang berjalan di Vercel, dengan kodenya di GitHub.

Prinsip: **semua lewat terminal + API**. Editor web GitHub (CodeMirror) hanya
me-render sebagian file sehingga perubahan besar cepat rusak - Hindari.

Rincian identifier dan konfigurasi ada di `references/fakta-proyek.md`.
Masalah nyata yang pernah terjadi beserta solusinya ada di
`references/troubleshooting.md`. Baca berkas itu kalau butuh detail.

Dokumentasi paling lengkap (semua insiden, perintah lengkap, checklist QA)
berada di repo skill `ozysparda/skill-opencode-faroyzi`:

- `MEMORY.md` - indeks pengetahuan
- `docs/memory/01-proyek-bbnews.md` - fakta proyek
- `docs/memory/02-insiden-dan-solusi.md` - insiden & solusi
- `docs/memory/03-alur-kerja-terminal.md` - alur kerja lengkap
- `docs/memory/04-trik-browser-tools.md` - trik & jebakan tool browser
- `docs/memory/05-token-dan-kredensial.md` - token & kredensial
- `docs/memory/06-qa-dan-baseline.md` - QA & baseline data

## Kapan skill ini dipakai

- Perbaiki bug di situs atau admin (mis. upload gambar gagal, artikel tidak tampil).
- Tambah atau ubah isi, layout, atau fitur admin.
- Push perubahan ke branch `vercel` dan ingin benar-benar tayang di production.
- Perlu memastikan data artikel di database tidak rusak setelah deploy.

## Alur kerja (WAJIB urutan ini)

### 1. Menyiapkan repo lokal

```powershell
$git = 'C:\Program Files\Git\cmd\git.exe'   # atau 'git' kalau sudah ada di PATH
$repo = 'C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git'
& $git -C $repo status --short --branch
& $git -C $repo pull --ff-only origin vercel
```

Kalau foldernya belum ada:

```powershell
& $git clone --branch vercel --single-branch https://github.com/ozysparda/BBNEWS.git $repo
```

### 2. Edit kode di repo lokal

- Aplikasi web: `artifacts/balebeleq-web/`
- Server API: `artifacts/api-server/`
- Skrip build Vercel: `scripts/vercel-build.mjs`
- Setelah edit, cek cepat: `& $git -C $repo diff --stat`

### 3. Commit dan push

```powershell
& $git -C $repo add -A
& $git -C $repo commit -m "pesan singkat: apa yang diubah dan kenapa"
& $git -C $repo push origin vercel
```

Aturan commit: satu perubahan logis satu commit, pesan Bahasa Indonesia yang
jelas, dan jangan pernah commit berkas berisi kredensial.

### 4. Tunggu build preview, lalu promote ke production

Push ke branch `vercel` **belum otomatis tayang** di production. Production
branch di Vercel masih `main`, sedangkan kode nyata ada di `vercel`, jadi deploy
production dilakukan dengan **promote** deployment preview.

Pakai skrip yang sudah disiapkan:

```powershell
$env:VERCEL_TOKEN = ((Get-Content "$env:TEMP\opencode\vercel-token.txt") | Select-String 'vcp_').ToString().Trim()
$env:VERCEL_TEAM_ID = 'ozyyyy310304s-projects'
powershell -ExecutionPolicy Bypass -File .\skills\bbnews-deploy\scripts\promote-latest.ps1 -Branch vercel
```

Skrip mencari deployment preview terbaru yang `READY`, melakukan promote dengan
`target: production`, lalu menunggu sampai `READY` dan mencetak alias yang
aktif (`berugaknews.vercel.app`, `berugaknews.com`, `www.berugaknews.com`).

Untuk promote deployment tertentu:

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\bbnews-deploy\scripts\promote-latest.ps1 -DeploymentId dpl_xxx
```

Alternatif tanpa skrip (curl):

```bash
curl -sS -X POST "https://api.vercel.com/v13/deployments?teamId=$VERCEL_TEAM_ID" \
  -H "Authorization: Bearer $VERCEL_TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"bbnews","deploymentId":"dpl_xxx","target":"production"}'
```

### 5. Verifikasi (jangan berhenti di "deploy sukses")

a. **Cek file di GitHub benar-benar berubah** (bandingkan byte, bukan mata):

```powershell
powershell -ExecutionPolicy Bypass -File .\skills\bbnews-deploy\scripts\verify-remote-file.ps1 `
  -Path 'artifacts/balebeleq-web/src/pages/admin/article-form.tsx'
```

b. **Cek deploy**: `GET https://api.vercel.com/v13/deployments/{id}?teamId=...`
   menghasilkan `readyState: READY` dan `target: production`.

c. **Cek data artikel masih utuh** (deploy tidak boleh menghapus artikel):

```powershell
Invoke-RestMethod 'https://berugaknews.vercel.app/api/articles?limit=100' |
  Select-Object -ExpandProperty articles | Measure-Object
```

Baseline saat skill ini dibuat: **3 artikel (3 terbit, 0 draft), 174 views**.
(Views naik mengikuti traffic - yang penting jumlah artikel tidak berkurang.)

d. **Cek fitur yang diperbaiki**. Contoh upload gambar: buka
   `https://berugaknews.vercel.app/admin/artikel/baru`, login admin, suntik
   file PNG kecil ke `input[type=file]`, lalu pastikan muncul URL
   `https://9likf3dmjkdbhrnr.public.blob.vercel-storage.com/uploads/...`
   dan preview gambarnya tampil.

## Aturan keselamatan data

- Database memakai Neon Postgres lewat env var di Vercel. **Jangan** menjalankan
  migrasi atau drop tanpa persetujuan eksplisit pengguna.
- Setelah deploy, selalu cek jumlah artikel dan draft seperti pada langkah 5c.
- Jangan menghapus branch atau remote tanpa izin pengguna.
- Kredensial admin tidak disimpan di repo ini maupun di repo proyek.

## Hal yang sering terlewat

- Build dari branch `main` gagal dengan `ERR_PNPM_NO_SCRIPT` - `main` tidak
  punya `scripts/vercel-build.mjs`.
- Runtime function harus `nodejs22.x` (sudah diatur di `scripts/vercel-build.mjs`).
- `BLOB_READ_WRITE_TOKEN` harus ada dan menunjuk ke store **publik**. Token ke
  store privat gagal dengan pesan "Cannot use public access on a private store".
- Pathname blob harus sama persis dengan payload token upload. Server
  mengembalikan `pathname` (berawalan `uploads/<timestamp>-`), dan frontend
  harus memakainya, bukan `file.name`.

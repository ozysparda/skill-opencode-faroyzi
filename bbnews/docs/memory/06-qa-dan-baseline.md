# 06 — QA, Baseline & Pemeriksaan Data

## 6.1 Baseline proyek (per Oktober 2026)

| Metrik | Nilai |
| --- | --- |
| Total artikel di admin | **3** |
| Artikel terbit (published) | **3** |
| Artikel draft | **0** |
| Total views | **174** (naik wajar dari 142 -> traffic) |
| Artikel publik via API | **3** |
| Deployment production aktif | `dpl_HDoRxfQ8fLnpWpfYBGL8rF4BYYsZ` (commit `d869aae`) |
| Store blob | `bbnews-foto` / `store_9LikF3DMJKdbhRnr` |

Angka-angka ini dipakai sebagai **baseline pembanding**. Kalau setelah deploy
jumlah artikel berubah turun, ada yang salah dan harus dicek (kemungkinan
build menimpa seed/reset data, atau migrasi tidak sengaja dijalankan).

Catatan penting:

- **Views selalu naik** seiring traffic - jangan dianggap data hilang kalau
  views bertambah. Yang penting: jumlah artikel tidak berkurang.
- **Status draft bisa berubah** karena pemilik proyek mempublikasikan artikel
  di luar sesi ini. Verifikasi ulang baseline dengan perintah di bawah sebelum
  membandingkan, jangan memakai angka lama.
- Verifikasi cepat (perlu token admin):

```powershell
$body = @{ username='admin'; password='<password>' } | ConvertTo-Json
$token = (Invoke-RestMethod -Method Post -Uri 'https://berugaknews.vercel.app/api/auth/login' `
            -ContentType 'application/json' -Body $body).token
$h = @{ Authorization = "Bearer $token" }
Invoke-RestMethod -Uri 'https://berugaknews.vercel.app/api/articles/stats' -Headers $h |
  Select-Object total, published, draft, totalViews
```

## 6.2 Checklist QA setelah deploy

```text
[ ] 1. Deployment READY + target production
[ ] 2. Alias aktif: berugaknews.vercel.app, berugaknews.com, www.berugaknews.com
[ ] 3. Halaman publik terbuka, artikel published tampil (2 artikel)
[ ] 4. /api/articles?limit=100 -> 2 artikel published
[ ] 5. /admin/dashboard -> TOTAL ARTIKEL 3, TERBIT 3, DRAFT 0 (views naik wajar)
[ ] 6. /admin/artikel/baru -> upload gambar berhasil (URL blob + preview)
[ ] 7. Gambar hasil upload bisa dibuka (HEAD 200, content-type image/*)
[ ] 8. Halaman draft tidak bocor ke publik (tidak muncul di /api/articles)
[ ] 9. Tidak ada error baru di Vercel logs untuk route yang dipakai
```

## 6.3 Cara cek cepat dari terminal

```powershell
# jumlah artikel publik
$arts = (Invoke-RestMethod 'https://berugaknews.vercel.app/api/articles?limit=100').articles
"published: $($arts.Count)"
$arts | Select-Object id, title, isPublished | Format-Table -AutoSize

# HEAD gambar blob
Invoke-WebRequest -UseBasicParsing -Method Head `
  'https://9likf3dmjkdbhrnr.public.blob.vercel-storage.com/uploads/<nama>.png' | Select-Object StatusCode, Headers
```

## 6.4 Cek lewat browser (admin)

Login dulu di `https://berugaknews.vercel.app/admin` (token ada di
`localStorage.admin_token`), lalu buka `/admin/dashboard`:

```js
const r = await tools.browser.evaluate({
  tabID: '<TAB_ID>',
  function: '() => document.body.innerText.slice(0, 2000)'
});
```

Halaman dashboard memuat kartu ringkasan: TOTAL ARTIKEL, TERBIT, DRAFT,
TOTAL VIEWS.

## 6.5 Verifikasi deployment lewat API

```powershell
$h = @{ Authorization = "Bearer $vercelToken" }
$t = 'ozyyyy310304s-projects'
$d = Invoke-RestMethod -Uri "https://api.vercel.com/v13/deployments/<id>?teamId=$t" -Headers $h
$d.readyState      # harus READY
$d.target          # harus production
$d.alias           # daftar alias aktif
$d.meta.githubCommitSha
```

## 6.6 Verifikasi byte berkas di GitHub

```powershell
powershell -ExecutionPolicy Bypass -File `
  '...\bbnews\skills\bbnews-deploy\scripts\verify-remote-file.ps1' `
  -Path 'artifacts/balebeleq-web/src/pages/admin/article-form.tsx'
```

Keluarannya: `IDENTIK` (exit 0) atau `BERBEDA` (exit 1).

## 6.7 Kalau data artikel hilang / berkurang

Urutan pemeriksaan (JANGAN langsung menebak):

1. Cek `readyState` deployment & log build - mungkin build gagal setelah
   menjalankan script seed/migrasi.
2. Cek env var `DATABASE_URL` di Vercel (production & preview) - kalau salah
   branch atau project, data yang tampil bisa dari DB lain.
3. Cek API admin dengan token admin untuk melihat semua artikel (termasuk
   draft) - mungkin artikel ada tapi `isPublished` berubah.
4. Jangan pernah menjalankan `DROP`/`TRUNCATE`/migrasi destruktif tanpa izin
   eksplisit pemilik proyek.

## 6.8 Jejak audit versi

| Tanggal | Commit | Deployment | Status |
| --- | --- | --- | --- |
| 2026-10 | `f362137` | `dpl_H8JUjig5JRa8AUKn4tDjHQV23M49` | production READY (nodejs22.x) |
| 2026-10 | `34c343b` | `dpl_38nzUS4GCuVCWGqunRCXRyLWtRpr` | ERROR (sintaks) |
| 2026-10 | `d869aae` | `dpl_EebFRSkGB3jfHAW88Su2JotsdDyp` | preview READY |
| 2026-10 | `d869aae` | `dpl_DGJ5gpp8b337mWXSaKBs6zsnToVv` | production READY |
| 2026-10 | `d869aae` | `dpl_HDoRxfQ8fLnpWpfYBGL8rF4BYYsZ` | production READY (promote ulang saat menguji skrip) |

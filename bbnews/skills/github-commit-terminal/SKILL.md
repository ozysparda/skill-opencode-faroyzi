---
name: Commit GitHub via Terminal
description: Commit dan push perubahan ke GitHub memakai git di terminal dengan personal access token yang tersimpan, termasuk setup kredensial, verifikasi hasil commit, dan pemulihan saat editor web GitHub tidak bisa dipakai.
---

# Commit GitHub via Terminal

Skill ini untuk bekerja dengan GitHub tanpa editor web: clone, edit lokal,
commit, push, verifikasi. Dipakai kalau editor web GitHub (CodeMirror) bermasalah
- misalnya file besar tidak terender utuh sehingga `Ctrl+A` + `insertText`
menghasilkan dokumen rusak, atau verifikasi isinya lewat `innerText` menyesatkan
karena hanya memuat viewport.

## Kapan skill ini dipakai

- Perubahan kode perlu masuk GitHub dan hasilnya langsung ter-deploy.
- Editor web GitHub gagal dipakai, atau tidak ada browser yang login.
- Butuh membuat commit, revert commit, atau memeriksa isi file di remote.
- Ingin menyiapkan akses push sekali saja agar tidak login ulang.

## Prasyarat

| Item | Nilai / cara |
| --- | --- |
| Git | `C:\Program Files\Git\cmd\git.exe` (sudah ditambahkan ke PATH user; pakai path penuh bila ragu) |
| Akun | `ozysparda` |
| Token | personal access token (classic) scope `repo`, tanpa kedaluwarsa |
| Penyimpanan token | credential helper `store` -> `%USERPROFILE%\.git-credentials` |
| Repo BBNEWS | `C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git` |

Detail pembuatan token ada di `references/setup-token.md`.
Versi paling lengkap ada di bundle `bbnews/` repo `ozysparda/skill-opencode-faroyzi`
-> `bbnews/docs/memory/05-token-dan-kredensial.md` (rotasi & penanganan
kebocoran) dan `bbnews/docs/memory/04-trik-browser-tools.md` (jebakan tool
browser).

## Alur kerja

### 1. Cek akses (cepat, tanpa Remote UI)

```powershell
$git = 'C:\Program Files\Git\cmd\git.exe'
$repo = 'C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git'
& $git -C $repo push --dry-run origin vercel
```

Keluar "Everything up-to-date" berarti kredensial push berfungsi.
`git ls-remote` ke repo public **bukan** bukti, karena itu bisa tanpa login.

### 2. Edit lokal, lalu cek diff

```powershell
& $git -C $repo status --short
& $git -C $repo diff --stat
& $git -C $repo diff -- <file>
```

Baca diff-nya, jangan commit buta.

### 3. Commit dan push

```powershell
& $git -C $repo add -A
& $git -C $repo commit -m "pesan singkat: apa yang diubah dan kenapa"
& $git -C $repo push origin vercel
```

Kalau `git commit` membuka editor interaktif, tambahkan `-m` (seperti di atas)
supaya tidak menggantung di terminal.

### 4. Verifikasi isi remote

Bandingkan byte berkas remote dengan lokal:

```powershell
powershell -ExecutionPolicy Bypass -File .\bbnews\skills\bbnews-deploy\scripts\verify-remote-file.ps1 `
  -Path '<path-relatif-di-repo>'
```

Alternatif tanpa skrip:

```powershell
Invoke-WebRequest -UseBasicParsing 'https://raw.githubusercontent.com/ozysparda/BBNEWS/vercel/<path>' -OutFile tmp.bin
(Get-FileHash tmp.bin -Algorithm SHA256).Hash -eq (Get-FileHash '<file-lokal>' -Algorithm SHA256).Hash
```

Cek juga daftar commit terbaru:

```powershell
& $git -C $repo log --oneline -5
```

### 5. Kalau commit yang salah, revert

```powershell
& $git -C $repo revert --no-edit <sha>
& $git -C $repo push origin vercel
```

## Jebakan yang pernah terjadi

- **Editor web GitHub**: hanya me-render sebagian file. `innerText` bukan isi
  penuh dokumen, dan `Ctrl+A` kadang tidak menyeleksi apa pun sehingga teks
  baru disisipkan di tengah file. Simpan Draft-nya sebelum reload.
- **Base64 panjang di dalam panggilan tool**: karakter sempat berubah sehingga
  satu `}` hilang dan build patah. Untuk file besar, ambil isinya dari
  `raw.githubusercontent.com` (halaman GitHub bisa melakukan fetch sendiri) atau
  pakai `browser.files.upload` yang mengirim byte apa adanya.
- **Verifikasi visual**: setelah commit, selalu bandingkan byte remote vs lokal.
- **Jangan** melakukan `git push --force` ke branch `vercel` tanpa persetujuan
  pengguna; pakai commit baru atau revert.
- **Jangan** menaruh token, `.env`, atau `.env.local` ke dalam commit.

## Rotasi token

Kalau token bocor atau kedaluwarsa: buat token baru lewat
`https://github.com/settings/tokens/new` (scope `repo`, "No expiration"), lalu
ganti isi `%USERPROFILE%\.git-credentials` dengan:

```text
https://ozysparda:<TOKEN_BARU>@github.com
```

Uji ulang dengan `git push --dry-run`.

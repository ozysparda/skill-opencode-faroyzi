# Troubleshooting BBNEWS

Catatan masalah nyata yang sudah pernah ditangani. Cari gejalanya di sini
sebelum mencoba-coba.

## Upload gambar gagal

### Gejala: 500 "Storage not configured" atau 403 saat upload

Penyebab dan solusi:

1. **Env var `BLOB_READ_WRITE_TOKEN` belum ada** di project Vercel.
   Pasang lewat Vercel Dashboard (Project > Settings > Environment Variables),
   target production dan preview.
2. **Token menunjuk ke store privat.** Frontend memakai `access: "public"`, jadi
   error: `Cannot use public access on a private store`.
   Solusi: buat store **publik** (Vercel Dashboard > Storage > Blob > Create
   store, pilih "Public Access"), lalu hubungkan ke project memakai tombol
   "Connect to Project" dan centang "Add a read-write token env var".
3. **Pathname tidak cocok dengan token.** Server mengembalikan `pathname`
   (`uploads/<timestamp>-<nama>`), tetapi frontend mengirim `file.name`.
   Gejala di log Vercel:
   `403 "pathname" <nama> does not match the token payload`.
   Solusi: klien wajib memakai `pathname` dari respons token:
   ```ts
   const { token: clientToken, pathname } = await res.json();
   const blob = await put(pathname, file, { access: "public", token: clientToken });
   ```
4. **Versi API blob.** Klien memakai `x-api-version: 12`. Versi 7 membalas
   `Invalid pathname`.

## Deploy tidak tayang

### Push ke `vercel` tapi situs tidak berubah

Normal. `vercel` bukan production branch (production branch = `main`).
Harus **promote** deployment preview ke production (lihat SKILL.md langkah 4).

### Build gagal dengan `ERR_PNPM_NO_SCRIPT`

Build dijalankan dari branch yang tidak punya `scripts/vercel-build.mjs`
(mis. `main`). Pastikan deploy berasal dari branch `vercel`.

### Build gagal karena runtime function

`nodejs20.x` sudah dihentikan Vercel. Pastikan `scripts/vercel-build.mjs`
menyebutkan `nodejs22.x`.

### Commit merusak sintaks (build ERROR)

Periksa diff commit sebelum promote:

```bash
git show --stat <sha>
git show <sha> -- <file>
```

Kalau file yang di-commit ternyata salah, revert lalu commit ulang:

```powershell
& $git -C $repo revert --no-edit <sha>
& $git -C $repo push origin vercel
```

## Editor web GitHub bermasalah

- CodeMirror hanya merender sebagian file. `innerText` hanya berisi viewport,
  sehingga verifikasi lewat `innerText` bisa menyesatkan.
- `Ctrl+A` + `execCommand('insertText')` pernah gagal memilih seluruh dokumen,
  hasilnya teks berantakan.
- **Solusi yang dipakai: bypass editor web.** Clone repo, edit di lokal,
  commit, push (skill `github-commit-terminal`).
- Alternatif tanpa editor: halaman **Upload files** GitHub
  (`/upload/<branch>/<path>`). File bisa disuntik lewat `DataTransfer`, dan
  halaman bisa mengambil sendiri isi file dari `raw.githubusercontent.com`
  lalu menyisipkan perbaikannya di memori sebelum diunggah.
- **Hindari mengirim isi file besar sebagai base64 di dalam panggilan tool**:
  ada karakter yang sempat berubah sehingga satu kurung kurawal hilang dan
  build patah. Ambil dari URL, atau pakai `files.upload` yang mengirim byte
  apa adanya.

## Sesi admin logout sendiri

`localStorage.admin_token` kedaluwarsa. Buka `/admin`, login ulang, lalu ulangi
langkah verifikasi. Jangan menyimpan kredensial di repo.

## Git dan akses

- Git ada di `C:\Program Files\Git\cmd\git.exe` (sudah ditambahkan ke PATH user).
- Akses push memakai personal access token yang tersimpan di credential store
  (`%USERPROFILE%\.git-credentials`). Uji akses cepat:
  `git -C <repo> push --dry-run origin vercel` (harus keluar "Everything up-to-date").
- `git ls-remote` ke repo public bisa berhasil tanpa kredensial - itu **bukan**
  bukti kalau push akan berhasil.

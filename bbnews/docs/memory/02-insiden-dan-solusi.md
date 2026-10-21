# 02 — Insiden & Solusi (kronologis)

Setiap insiden dicatat dengan **pesan error asli** supaya bisa dicari persis
saat masalah yang sama muncul lagi.

---

## INS-01 — Upload gambar gagal: 403 pathname does not match the token payload

**Waktu:** Oktober 2026 · **Severity:** tinggi (fitur inti rusak)

**Gejala**

Di halaman admin `/admin/artikel/baru`, pilih gambar -> toast error:

```text
Failed to upload: 403 {"error":{"code":"forbidden","message":"\"pathname\" tes-upload.png does not match the token payload"}}
```

**Penyebab**

Dua sisi yang tidak sinkron:

- Server (`artifacts/api-server/src/routes/storage.ts`) membuat token upload
  dengan payload `{pathname: "uploads/<timestamp>-<nama>"}` dan **mengembalikan
  pathname itu** ke klien.
- Klien (`artifacts/balebeleq-web/src/pages/admin/article-form.tsx`) mengabaikan
  `pathname` dan memanggil `put(file.name, file, {...})`.

Vercel Blob memvalidasi nama path harus sama persis dengan payload token, jadi
muncul 403.

**Perbaikan (kommit `d869aae`)**

```diff
-  const { token: clientToken } = await res.json();
-  const blob = await put(file.name, file, {
+  const { token: clientToken, pathname } = await res.json();
+  const blob = await put(pathname, file, {
     access: "public",
     token: clientToken,
   });
```

**Verifikasi**

- `POST /api/storage/upload-token` -> HTTP 200.
- Gambar tersimpan di
  `https://9likf3dmjkdbhrnr.public.blob.vercel-storage.com/uploads/1792509104276-tes-upload.png`
  (HEAD -> 200, `content-type: image/png`, 68 byte).
- Preview gambar tampil di form dan field URL terisi.
- Tidak ada toast error.

**Catatan:** nama file asli **tidak** hilang - `pathname` tetap memuat nama
asli setelah prefix timestamp, jadi URL tetap informatif.

---

## INS-02 — Upload gagal: "Cannot use public access on a private store"

**Gejala**

```text
Cannot use public access on a private store. Please use a private store or remove the access option.
```

**Penyebab**

Frontend mengunggah dengan `access: "public"`, sementara `BLOB_READ_WRITE_TOKEN`
yang terpasang menunjuk ke store lama `peta-politik-foto` yang **privat**.

**Perbaikan**

1. Buat store baru `bbnews-foto` dengan **Public Access**, region `iad1`
   -> id `store_9LikF3DMJKdbhRnr`.
2. Hubungkan ke project `bbnews` lewat tombol "Connect to Project".
3. Centang "Add a read-write token env var" -> Vercel otomatis membuat
   `BLOB_READ_WRITE_TOKEN`, `BLOB_STORE_ID`, `BLOB_WEBHOOK_PUBLIC_KEY` untuk
   target **production** dan **preview**.
4. Store lama dilepas dari project (tidak dihapus datanya).

**Pelajaran:** kalau frontend memakai `access: "public"`, store wajib publik.
Cek dulu daftar store yang terhubung ke project sebelum debugging kode.

---

## INS-03 — Build ERROR: `ERR_PNPM_NO_SCRIPT`

**Gejala**

Deployment preview/build gagal:

```text
Error: Command "pnpm" not found
ERR_PNPM_NO_SCRIPT
```

**Penyebab**

Build dijalankan dari branch `main` yang **tidak punya** `scripts/vercel-build.mjs`
(konfigurasi build Vercel). Kode sebenarnya ada di branch `vercel`.

**Perbaikan**

- Semua build harus dari branch `vercel`.
- Produksi tetap `main`, jadi publication lewat **promote** deployment preview
  (lihat `03-alur-kerja-terminal.md`).

---

## INS-04 — Runtime function `nodejs20.x` dihentikan Vercel

**Gejala**

Deployment build gagal / function tidak jalan, log:

```text
The Node.js version "nodejs20.x" is no longer supported by Vercel.
```

**Perbaikan**

`scripts/vercel-build.mjs` diubah dari `nodejs20.x` -> `nodejs22.x`
(kommit `f362137`, deployment `dpl_H8JUjig5JRa8AUKn4tDjHQV23M49` READY).

---

## INS-05 — Commit rusak sintaks: satu `}` hilang

**Gejala**

Deployment `dpl_38nzUS4GCuVCWGqunRCXRyLWtRpr` -> ERROR.
File `article-form.tsx` kehilangan satu tanda `}` sehingga build gagal
(timestamp `34c343b`).

**Penyebab**

Isi file besar (16.666 byte) dikirim sebagai **base64 di dalam panggilan tool**,
dan dua karakter berubah saat transit (satu `}` hilang, satu baris kosong
menjadi 18 spasi).

**Perbaikan**

1. Ambil isi file dari `raw.githubusercontent.com` (halaman GitHub bisa melakukan
   fetch sendiri lalu menyisipkan perbaikannya di memori), **atau**
2. Edit langsung di clone lokal + commit + push lewat git.
3. Perbaiki dengan kommit lanjutan `d869aae`
   ("Perbaiki sintaks: lengkapi kurung kurawal pada tombol simpan").

**Pelajaran (penting):** jangan pernah menyalin isi file besar secara manual /
lewat base64 di dalam prompt tool. Byte bisa berubah tanpa terlihat.

---

## INS-06 — Editor web GitHub (CodeMirror) tidak bisa dipakai Editing

**Gejala**

- File panjang hanya ter-render sebagian; `innerText` hanya berisi **viewport**
  (bukan isi penuh) sehingga verifikasi lewat `innerText` menyesatkan.
- `Ctrl+A` + `document.execCommand('insertText', ...)` tidak selalu menyeleksi
  seluruh dokumen -> teks baru tertanam di tengah file, dokumen kacau.
- Saat tab tidak terlihat (`document.visibilityState === 'hidden'`), browser
  membatasi `requestAnimationFrame`, sehingga animasi/editor menjadi lambat dan macet.
- Halaman upload file (`/upload/...`) tidak menyediakan `ref` yang bisa
  dipakai `browser.files.upload`.

**Solusi yang berhasil**

1. **Utama:** clone repo -> edit lokal -> `git add/commit/push`. Editor web
   tidak dipakai sama sekali.
2. **Cadangan:** halaman *Upload files* GitHub. File disuntik sebagai objek
   `File` sungguhan melalui `DataTransfer`:

```js
const res = await fetch(rawUrl);              // ambil isi file asli
const src = await res.text();
const patched = src.replace("LAMA", "BARU");  // ubah di memori
const file = new File([patched], "article-form.tsx", { type: "text/plain" });
const dt = new DataTransfer();
dt.items.add(file);
const input = document.querySelector("#upload-manifest-files-input");
input.files = dt.files;
input.dispatchEvent(new Event("input", { bubbles: true }));
input.dispatchEvent(new Event("change", { bubbles: true }));
```

Lalu isi commit summary memakai **native setter** (biar React mendeteksi):

```js
const set = Object.getOwnPropertyDescriptor(
  window.HTMLInputElement.prototype, "value").set;
set.call(summaryInput, "pesan commit");
summaryInput.dispatchEvent(new Event("input", { bubbles: true }));
```

Terakhir pastikan radio `commit-choice[value=direct]` terpilih dan
`target_branch=vercel`, lalu klik `button.js-blob-submit`.

---

## INS-07 — API GitHub kena rate limit tanpa token

**Gejala**

```text
API rate limit exceeded for 203.0.113.10. (But the API works fine with your token)
```

**Penyebab**

Panggilan tanpa autentikasi dibatasi 60/jam per IP; kuota terpakai habis.

**Perbaikan**

- Paken personal access token pada header `Authorization: Bearer <token>`.
- Alternatif tanpa API: ambil isi via `raw.githubusercontent.com` atau
  `codeload.github.com` (zip/tarball branch).

---

## INS-08 — Sesi admin logout sendiri

**Gejala**

Halaman `/admin/dashboard` memunculkan form login lagi padahal sudah login.

**Penyebab**

`localStorage.admin_token` (JWT) kedaluwarsa.

**Perbaikan**

Login ulang di `/admin` dengan kredensial dari pemilik proyek, lalu ulangi
langkah verifikasi. Kredensial **tidak** ditulis di repo manapun.

---

## INS-09 — Pengrowseran Vercel & CORS

**Gejala**

`fetch('https://api.vercel.com/v13/deployments/...')` dari tool browser pada
origin non-Vercel gagal (CORS / preflight ditolak).

**Perbaikan**

Jalankan request tersebut **dari tab `vercel.com`** (origin yang diizinkan),
dengan header `Authorization: Bearer <token>`.

**Alternatif terbaik (dipakai sekarang):** panggil API Vercel langsung dari
terminal PowerShell (`Invoke-RestMethod`) atau `curl` - tidak ada masalah CORS
karena bukan request browser. Lihat `03-alur-kerja-terminal.md`.

---

## INS-10 — Git belum terpasang di PC

**Gejala**

`git` tidak dikenali sebagai perintah.

**Perbaikan**

Git diinstal ke `C:\Program Files\Git\cmd\git.exe`, lalu `C:\Program Files\Git\cmd`
ditambahkan ke PATH user:

```powershell
$cur = [Environment]::GetEnvironmentVariable('Path','User')
[Environment]::SetEnvironmentVariable('Path', $cur.TrimEnd(';') + ';C:\Program Files\Git\cmd', 'User')
```

Clone repo BBNEWS ke
`C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git`
(branch `vercel`, single-branch).

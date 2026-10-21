# 05 — Token & Kredensial

> **Nilai token tidak ditulis di repo ini.** Repo ini adalah katalog skill yang
> bisa dibaca siapa pun yang punya akses. Simpan token di luar repo.

## 5.1 Daftar token yang dipakai

| Token | Scope | Dibuat | Lokasi lokal | Status |
| --- | --- | --- | --- | --- |
| Vercel personal access token | Full Account, tanpa kedaluwarsa | Oktober 2026 | `%TEMP%\opencode\vercel-token.txt` | aktif |
| GitHub PAT (classic) | `repo`, tanpa kedaluwarsa | Oktober 2026 | `%TEMP%\opencode\github-token.txt` + `%USERPROFILE%\.git-credentials` | aktif |

Catatan keamanan:

- Keduanya **tanpa kedaluwarsa** -> kalau bocor, dampaknya besar. Rotasi
  berkala (mis. tiap 3-6 bulan) dan segera hapus yang lama.
- `%USERPROFILE%\.git-credentials` adalah file **teks biasa**. Jangan pernah
  ikut ter-commit, dan pastikan tidak dibagikan.

## 5.2 Format file token

`%TEMP%\opencode\vercel-token.txt` (satu baris):

```text
vcp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`%TEMP%\opencode\github-token.txt` (satu baris):

```text
ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Membaca lewat PowerShell (menghilangkan spasi/newline):

```powershell
$vercelToken  = ((Get-Content "$env:TEMP\opencode\vercel-token.txt") | Select-String 'vcp_').ToString().Trim()
$githubToken  = ((Get-Content "$env:TEMP\opencode\github-token.txt") | Select-String 'ghp_').ToString().Trim()
```

## 5.3 Git: credential helper `store`

Isi `%USERPROFILE%\.git-credentials`:

```text
https://ozysparda:<TOKEN>@github.com
```

```powershell
& $git config --global credential.helper store
```

Alternatif lebih aman (Windows Credential Manager):

```powershell
& $git config --global credential.helper manager
```

Uji akses push:

```powershell
& $git -C $repo push --dry-run origin vercel     # harus: Everything up-to-date
```

**Peringatan:** `git ls-remote` ke repo public berhasil tanpa login, jadi itu
BUKAN bukti akses push berfungsi. Yang membuktikan hanya `push --dry-run`.

## 5.4 Membuat token baru

### GitHub PAT (classic)

1. `https://github.com/settings/tokens/new?scopes=repo&description=opencode-agent`
2. Note: `opencode-agent`, Expiration: **No expiration**.
3. Scope: **repo** (sub-scope ikut tercentang).
4. Generate -> salin sekali tampilannya -> simpan di file token.
5. Perbarui `.git-credentials`, uji `push --dry-run`.
6. Hapus token lama di `https://github.com/settings/tokens`.

Alternatif modern: fine-grained PAT dengan akses hanya repo `ozysparda/BBNEWS`
(permissions: Contents read/write) - lebih aman, tapi butuh penyesuaian nama
header (`Authorization: Bearer <token>` tetap sama).

### Vercel

1. Dashboard Vercel > Settings > Tokens > Create Token.
2. Scope: **Full Account** (perlu buat/promote deployment di luar dashboard).
3. Expiration: **No expiration**.
4. Simpan di `%TEMP%\opencode\vercel-token.txt`.
5. Hapus token lama di dashboard kalau sudah diganti.

## 5.5 Mengakai token Vercel dari terminal

```powershell
$headers = @{ Authorization = "Bearer $vercelToken" }
$team    = 'ozyyyy310304s-projects'
Invoke-RestMethod -Uri "https://api.vercel.com/v9/projects/bbnews?teamId=$team" -Headers $headers
```

## 5.6 Env var aplikasi (disimpan di Vercel, bukan di repo)

| Nama | Secret? | Keterangan |
| --- | --- | --- |
| `DATABASE_URL` | ya | Neon Postgres |
| `BLOB_READ_WRITE_TOKEN` | ya | token read-write store `bbnews-foto` (publik) |
| `BLOB_STORE_ID` | tidak | `store_9LikF3DMJKdbhRnr` |
| `BLOB_WEBHOOK_PUBLIC_KEY` | tidak | kunci webhook blob |
| `JWT_SECRET` / secret API | ya | untuk token admin & route API |

Semua env var harus diset untuk target **production** dan **preview**.

## 5.7 Kredensial admin aplikasi

- Login admin memakai username/password yang diberikan pemilik proyek.
- **Tidak boleh** ditulis di repo, skill, atau memory (termasuk commit).
- Sesi disimpan di `localStorage.admin_token` dan bisa kedaluwarsa; kalau
  kedaluwarsa -> form login muncul lagi, minta kredensial ke pemilik proyek.

## 5.8 Kalau token bocor

1. Cabut token lama lebih dulu (GitHub Settings > Developer settings > Personal
   access tokens > Delete; Vercel Settings > Tokens > Revoke).
2. Buat token baru dengan langkah di 5.4.
3. Perbarui file token + `.git-credentials`.
4. Uji `push --dry-run` dan satu panggilan API Vercel.
5. Kalau bocor lewat commit: `git revert` commit itu, `git push`, lalu
   `git filter-repo`/BFG bila perlu membersihkan histori (hanya dengan izin
   pemilik proyek, karena mengubah sha).

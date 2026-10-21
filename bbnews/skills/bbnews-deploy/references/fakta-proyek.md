# Fakta Proyek BBNEWS (per Oktober 2026)

Semua identifier di sini bukan rahasia, tapi **tokennya tidak boleh ditulis di
repo ini**. Token disimpan di luar repo, lihat `references/setup-token.md` pada
skill `github-commit-terminal`.

## GitHub

| Item | Nilai |
| --- | --- |
| Owner / repo | `ozysparda/BBNEWS` (public) |
| Branch kode aktif | `vercel` |
| Branch production di Vercel | `main` (hanya berisi versi lama, jangan dipakai untuk build) |
| Repo id | `1257544468` |
| Clone lokal | `C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git` |
| Struktur | `artifacts/balebeleq-web` (web), `artifacts/api-server` (API), `scripts/vercel-build.mjs` |

## Vercel

| Item | Nilai |
| --- | --- |
| Tim | `ozyyyy310304s-projects` (owner `ozyyyy310304`) |
| Project | `bbnews` |
| Project id | `prj_rHyWehSu30eyddSdCtMrT7OAQm9J` |
| Alias production | `berugaknews.vercel.app`, `berugaknews.com`, `www.berugaknews.com` |
| Token akses | `vcp_...` di `%TEMP%\opencode\vercel-token.txt` (scope Full Account, tanpa kedaluwarsa) |

Endpoint yang sering dipakai:

| Kebutuhan | Endpoint |
| --- | --- |
| Daftar deployment | `GET /v6/deployments?projectId=<id>&teamId=<tim>&limit=8` |
| Detail deployment | `GET /v13/deployments/{id}?teamId=<tim>` |
| Promote ke production | `POST /v13/deployments?teamId=<tim>` body `{name, deploymentId, target:"production"}` |
| Info project | `GET /v9/projects/bbnews` |

## Vercel Blob

| Item | Nilai |
| --- | --- |
| Store aktif | `bbnews-foto` |
| Store id | `store_9LikF3DMJKdbhRnr` |
| Region | `iad1` |
| Akses | **publik** (wajib, karena frontend memakai `access: "public"`) |
| URL publik | `https://9likf3dmjkdbhrnr.public.blob.vercel-storage.com/uploads/<timestamp>-<nama>` |
| Env var | `BLOB_READ_WRITE_TOKEN`, `BLOB_STORE_ID`, `BLOB_WEBHOOK_PUBLIC_KEY` (target production dan preview) |

Store lama `peta-politik-foto` bersifat privat dan **sudah tidak dipakai**.

## Alur upload gambar (server dan klien)

1. Klien: `POST /api/storage/upload-token` body `{name}` -> server
2. Server membuat `pathname = uploads/${Date.now()}-${name}` lalu mengembalikan
   `{token, pathname}`. Payload token memuat `{pathname, validUntil}` (~30 detik).
3. Klien: `put(pathname, file, { access: "public", token })` dari `@vercel/blob/client`.
4. Wajib: nama path yang dikirim harus identik dengan `pathname` di payload
   token, kalau tidak Vercel membalas 403
   `"pathname" <nama> does not match the token payload`.

## Build

- `scripts/vercel-build.mjs` mengatur runtime function ke `nodejs22.x`
  (`nodejs20.x` sudah dihentikan Vercel).
- Deployment preview dibuat otomatis setiap push ke branch `vercel`.
- Yang tayang di production hanya lewat promote (lihat SKILL.md langkah 4).

## Admin

- URL: `https://berugaknews.vercel.app/admin`
- Login disimpan di `localStorage.admin_token` dan **bisa kedaluwarsa**; kalau
  halaman balik ke form login, login ulang dengan kredensial dari pemilik
  proyek (jangan disimpan di repo).
- Baseline data saat skill ini dibuat: 3 artikel (3 terbit, 0 draft), 174 views.
  Views naik mengikuti traffic; yang dijaga adalah jumlah artikel.

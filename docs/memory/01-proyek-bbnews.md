# 01 — Proyek BBNEWS (BerugakNews)

Tanggal pengetahuan: Oktober 2026. Semua di bawah ini diverifikasi langsung
ke API GitHub dan Vercel.

## 1.1 Gambaran umum

| Item | Nilai |
| --- | --- |
| Nama situs | Berugak News |
| Domain | `berugaknews.com`, `www.berugaknews.com`, `berugaknews.vercel.app` |
| Repo | `ozysparda/BBNEWS` (public), repo id `1257544468` |
| Branch kode | `vercel` |
| Branch production di Vercel | `main` (hanya versi lama - jangan di-build dari sini) |
| Tim Vercel | `ozyyyy310304s-projects` (owner `ozyyyy310304`) |
| Project Vercel | `bbnews`, project id `prj_rHyWehSu30eyddSdCtMrT7OAQm9J` |
| Database | Neon Postgres (via env var di Vercel) |
| Admin | `https://berugaknews.vercel.app/admin` |

## 1.2 Struktur repo

```text
BBNEWS/
├── artifacts/
│   ├── api-server/          # server API (Express/Hono) - route storage, artikel, dll
│   │   └── src/routes/storage.ts   # route /api/storage/upload-token
│   └── balebeleq-web/       # aplikasi React (Vite) - frontend + admin
│       └── src/pages/admin/article-form.tsx  # form admin + upload gambar
├── scripts/
│   └── vercel-build.mjs     # build script Vercel (runtime nodejs22.x)
├── attached_assets/
├── lib/
└── .agents/                 # catatan/konvensi proyek
```

## 1.3 Build & deploy

- `scripts/vercel-build.mjs` mengatur runtime function serverless menjadi
  `nodejs22.x`. Semula `nodejs20.x` dan Vercel sudah menghentikannya.
- Build dari branch `main` gagal dengan `ERR_PNPM_NO_SCRIPT` karena `main` tidak
  punya `scripts/vercel-build.mjs`. Selalu build dari `vercel`.
- Push ke `vercel` -> Vercel membuat **deployment preview**.
- Production branch = `main`, jadi kode di `vercel` **tidak** otomatis tayang.
  Publication lewat **promote**: `POST /v13/deployments` dengan
  `{name:"bbnews", deploymentId, target:"production"}` dan query
  `?teamId=ozyyyy310304s-projects`.
- Alias production aktif (hasil promote `dpl_DGJ5gpp8b337mWXSaKBs6zsnToVv`):
  `berugaknews.vercel.app`, `berugaknews.com`, `www.berugaknews.com`,
  `bbnews-ozyyyy310304s-projects.vercel.app`.

Riwayat deployment penting:

| Deployment | Commit | State | Catatan |
| --- | --- | --- | --- |
| `dpl_H8JUjig5JRa8AUKn4tDjHQV23M49` | `f362137` | READY (production) | runtime nodejs22.x |
| `dpl_38nzUS4GCuVCWGqunRCXRyLWtRpr` | `34c343b` | ERROR | commit dengan `}` hilang |
| `dpl_EebFRSkGB3jfHAW88Su2JotsdDyp` | `d869aae` | READY (preview) | versi perbaikan |
| `dpl_DGJ5gpp8b337mWXSaKBs6zsnToVv` | `d869aae` | READY (production) | hasil promote, yang tayang sekarang |

## 1.4 Vercel Blob

| Item | Nilai |
| --- | --- |
| Store aktif | `bbnews-foto` |
| Store id | `store_9LikF3DMJKdbhRnr` |
| Region | `iad1` |
| Akses | **publik** (wajib, karena frontend memakai `access: "public"`) |
| Host | `9likf3dmjkdbhrnr.public.blob.vercel-storage.com` |
| Env var | `BLOB_READ_WRITE_TOKEN`, `BLOB_STORE_ID`, `BLOB_WEBHOOK_PUBLIC_KEY` (production + preview) |
| Store lama | `peta-politik-foto` (privat, sudah tidak dipakai) |

Cara membuat store + connect (kalau perlu diulang):

1. Vercel Dashboard > Storage > Blob > Create store.
2. Pilih **Public Access** (wajib), region `iad1`, nama `bbnews-foto`.
3. Tombol "Connect to Project" > pilih project `bbnews`.
4. Centang "Add a read-write token env var" (membuat `BLOB_READ_WRITE_TOKEN`
   otomatis) dan pilih target production + preview.

Tes manual upload blob (berhasil, HTTP 200):

```http
PUT https://vercel.com/api/blob/?pathname=uploads%2Ftes.png
Authorization: Bearer <clientToken>
x-api-version: 12
x-vercel-blob-store-id: store_9LikF3DMJKdbhRnr
x-api-blob-request-id: <uuid>
x-api-blob-request-attempt: 0
```

Hasil: `https://9likf3dmjkdbhrnr.public.blob.vercel-storage.com/uploads/tes.png`.

Catatan versi API: `x-api-version: 7` membalas `Invalid pathname`; versi 12 yang
dipakai library `@vercel/blob` terbaru dan berhasil.

## 1.5 Alur upload gambar (server dan klien)

**Server** - `artifacts/api-server/src/routes/storage.ts`:

```ts
const pathname = `uploads/${Date.now()}-${name}`;   // name = file asli dari klien
// generateClientTokenFromReadWriteToken({ token, pathname, ... })
return { token: clientToken, pathname };
```

Payload token memuat `{pathname, validUntil}` dengan masa berlaku sekitar 30
detik.

**Klien** - `artifacts/balebeleq-web/src/pages/admin/article-form.tsx`:

```ts
const res = await fetch(`${baseUrl}/api/storage/upload-token`, {
  method: "POST",
  headers: { "Content-Type": "application/json", Authorization: `Bearer ${authToken}` },
  body: JSON.stringify({ name: file.name }),
});
if (!res.ok) throw new Error("Gagal mendapatkan token upload");

// WAJIB pakai pathname dari server (sebelumnya salah pakai file.name)
const { token: clientToken, pathname } = await res.json();

const blob = await put(pathname, file, {
  access: "public",
  token: clientToken,
});
form.setValue("imageUrl", blob.url);
```

Kalau nama path yang dikirim tidak identik dengan payload token, Vercel membalas
403: `"pathname" <nama> does not match the token payload`.

## 1.6 Admin & data

- Login admin disimpan di `localStorage.admin_token` (JWT, bisa kedaluwarsa).
  Habis masa berlaku, halaman `/admin` memunculkan form login lagi.
- Kredensial admin **tidak disimpan** di repo ini; minta dari pemilik proyek
  saat dibutuhkan.
- Baseline data saat memory ini dibuat: **3 artikel (3 terbit, 0 draft), 174 views**.
  (Awalnya 2 terbit + 1 draft / 142 views - draft sudah dipublikasikan pemilik
  proyek. Views terus naik mengikuti traffic.)
- Cek cepat jumlah artikel published via API publik:
  `GET https://berugaknews.vercel.app/api/articles?limit=100`
  -> array `articles` dengan field `isPublished`.

## 1.7 Clone lokal (PC ini)

```text
C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git
```

Clone ulang:
`git clone --branch vercel --single-branch https://github.com/ozysparda/BBNEWS.git <tujuan>`

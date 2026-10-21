# 09 — Status Implementasi Fitur Berugak Donasi

Checkpoint: 22 Oktober 2026 (sesi dihentikan sejenak karena laptop dimatikan).
Lokasi kerja: `C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git`
(branch `vercel`, base commit `d869aae`, **perubahan BELUM di-commit**).

---

## 1. Yang sudah selesai

### Backend (API + DB)

| File | Status |
| --- | --- |
| `lib/db/src/schema/donations.ts` | selesai — tabel `donation_campaigns`, `donation_transactions`, `donation_settings` |
| `lib/db/src/schema/index.ts` | selesai — `export * from "./donations"` |
| `artifacts/api-server/src/lib/crypto.ts` | selesai — verifikasi tx hash (TronGrid / Blockchair) |
| `artifacts/api-server/src/routes/donations.ts` | selesai — endpoint publik + admin + upload-token + webhook |
| `artifacts/api-server/src/routes/index.ts` | selesai — `router.use(donationsRouter)` |

### Spec + client

- `lib/api-spec/openapi.yaml` — sudah ditambah: tag `donations`, 10 path
  (`/donations/settings`, `/donations/campaigns`, `/donations/campaigns/{slug}`,
  `/donations/transactions`, `/donations/transactions/{reference}`,
  `/admin/donations/campaigns[/{id}]`, `/admin/donations/transactions[/{id}]`,
  `/admin/donations/stats`, `/admin/donations/settings`) + 13 schema
  (`DonationCampaign`, `DonationCampaignInput`, `DonationCampaignListResponse`,
  `DonationRecentDonation`, `DonationTransaction`, `DonationTransactionInput`,
  `DonationTransactionCreated`, `DonationTransactionStatus`,
  `DonationTransactionUpdate`, `DonationTransactionListResponse`,
  `DonationStats`, `DonationSettings`, `DonationSettingsInput`).
- Client orval **sudah di-regenerate** (`lib/api-client-react/src/generated/api.ts`
  + `api.schemas.ts`). Hook yang tersedia:
  `useGetDonationSettings`, `useListDonationCampaigns`, `useGetDonationCampaign`,
  `useCreateDonationTransaction`, `useTrackDonationTransaction`,
  `useListAdminDonationCampaigns`, `useCreateDonationCampaign`,
  `useGetAdminDonationCampaign`, `useUpdateDonationCampaign`,
  `useDeleteDonationCampaign`, `useListAdminDonationTransactions`,
  `useUpdateDonationTransaction`, `useGetDonationStats`,
  `useGetAdminDonationSettings`, `useUpdateDonationSettings`.
  Pola mutasi: `mutateAsync({ id, data })` / `mutateAsync({ data })`.

### Frontend

| File | Status |
| --- | --- |
| `src/lib/format-money.ts` | selesai — `formatRupiah`, `formatNumber`, `parseNominal` |
| `src/lib/api-url.ts` | selesai — helper URL API (pakai `VITE_API_URL` kalau ada) |
| `src/pages/donation-list.tsx` | selesai — hero + daftar campaign + progress |
| `src/pages/donation-detail.tsx` | selesai — QRIS/rekening/kripto + form donasi + upload bukti + QR dari payload (`qrcode.react`) |
| `src/pages/donation-tracking.tsx` | selesai — cek status pakai nomor referensi |
| `src/pages/admin/donation-campaign-list.tsx` | selesai — tabel + filter + stats + hapus |
| `src/pages/admin/donation-campaign-form.tsx` | selesai — form create/edit (pakai `RichTextEditor`) |
| `src/pages/admin/donation-transaction-list.tsx` | selesai — verifikasi/tolak + catatan admin |
| `src/pages/admin/donation-settings.tsx` | selesai — hero + QRIS/rekening cadangan |
| `src/components/layout/public-layout.tsx` | nav desktop + mobile + footer sudah ditambah link Donasi |
| `src/components/layout/admin-layout.tsx` | nav admin sudah ditambah menu Donasi |
| `src/App.tsx` | route sudah terdaftar (lihat bagian 2) |

Route publik: `/donasi`, `/donasi/lacak`, `/donasi/:slug`.
Route admin: `/admin/donasi`, `/admin/donasi/baru`, `/admin/donasi/transaksi`,
`/admin/donasi/pengaturan`, `/admin/donasi/:id/edit`.

### Dokumentasi

- `bbnews/docs/memory/08-konsep-berugak-donasi-founding-beasiswa.md` — konsep
  Berugak Donasi (implementasi), Berugak Founding (Fase 2), Beasiswa Berugak
  (Fase 3). **Sudah ditulis.**
- `bbnews/docs/memory/09-status-implementasi-donasi.md` — file ini.

---

## 2. Yang belum selesai (lanjutkan dari sini)

1. **Typecheck belum tentu lulus.** Perintah:
   `pnpm run typecheck` di root `bbnews-git` (butuh shim `pnpm` -> sudah dibuat di
   `C:\Users\Dunia Imajinasiku\.local\bin\pnpm.cmd` + Git `usr\bin` di PATH).
   Jalankan ulang dan perbaiki error.
2. **Belum ada commit/push.** Semua perubahan di `bbnews-git` masih di working tree.
   Commit dengan `git commit --only -- <path>` per file (sesi lain mungkin aktif di repo ini).
3. **Skema DB belum diterapkan ke Neon.** Butuh `POSTGRES_URL` dari env Vercel
   (env `sensitive`; API v9 tidak mengembalikan nilainya ke token ini).
   Jalur yang dicoba:
   - `vercel link --project bbnews --yes --token <vcp_...> --scope ozyyyy310304s-projects`
     (dijalankan di `%TEMP%\opencode\vercel-env`, di luar repo) -> lalu
     `vercel env pull .env.production --environment production` untuk ambil nilainya.
   - Setelah URL didapat: `pnpm --filter @workspace/db run push` (drizzle-kit push).
4. **Belum ada deploy.** Push branch `vercel` -> preview Vercel -> **promote ke
   production hanya bila user minta**.
5. **Belum diupdate:** `bbnews/docs/memory/01-proyek-bbnews.md` (tambah fitur Donasi)
   dan `06-qa-dan-baseline.md` (baseline terbaru).

---

## 3. Catatan teknis penting (hemat waktu di sesi berikutnya)

### Windows / tooling

- `sh` tidak ada di PATH -> script `preinstall` root gagal. Tambahkan
  `C:\Program Files\Git\usr\bin;C:\Program Files\Git\bin` ke PATH.
- Script root memanggil `pnpm` langsung (bukan `corepack pnpm`) -> butuh shim
  `pnpm.cmd` yang memanggil `corepack pnpm %*`
  (sudah ada di `C:\Users\Dunia Imajinasiku\.local\bin\pnpm.cmd`).
- `corepack enable` gagal (EPERM di Program Files) -> selalu pakai `corepack pnpm`.
- orval dijalankan manual dari `lib/api-spec`:
  `& "$base\lib\api-spec\node_modules\.bin\orval.CMD" --config .\orval.config.ts`
  (bukan `node .../orval.js` — file bin-nya `orval.mjs`).
- PowerShell 5.1: perintah multi-baris harus pakai newline sungguhan, bukan
  string `\n` (parse error).

### Perbaikan yang sudah diterapkan (jangan dibalik)

- **Stats donasi**: query lama memakai `GROUP BY campaign.id` sehingga
  `collectedAmount`/`campaignCount` ikut jadi per-campaign. Sudah diganti jadi
  2 query agregat terpisah (campaign + transaksi).
- Teks mojibake di beberapa file (tulisan campaign, nama rekening, dst) sudah
  dibersihkan. Kalau lihat karakter CJK/garbled, scan ulang dengan
  `Select-String -Pattern '[\u3000-\u9fff\ufffd]'`.

### Keputusan desain donasi

- Auto-konfirmasi **hanya kripto** (verifikasi tx hash ke explorer publik).
  QRIS & transfer bank -> **konfirmasi manual admin** (sudah disetujui user).
  Route webhook `POST /api/donations/webhook` (secret env `DONATION_WEBHOOK_SECRET`)
  disiapkan untuk payment gateway di kemudian hari.
- Total donasi = agregat `SUM(status='verified')`, tanpa kolom counter.
- Bukti transfer diunggah lewat `POST /api/donations/upload-token`
  (blob client token, path `uploads/donasi/`, rate limit 8/jam/IP).
- Campaign `draft|active|closed|archived`; transaksi `pending|verified|rejected`
  (+ flag `autoVerified`).

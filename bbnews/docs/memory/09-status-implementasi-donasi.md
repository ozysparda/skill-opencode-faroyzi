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


## 4. Status final (selesai)

- Commit pertama: `d38f3e4` (feat: Berugak Donasi).
- Commit perbaikan keamanan: `89de2b6` (validasi input, retry ref, batasi publik,
  harden IP rate-limit).
- Push ke branch `vercel`: sukses (`d38f3e4..89de2b6`).
- Deployment preview: `dpl_9NfFWe5ojctKQbAcVNLLdSM5mKh3` (READY).
- Deployment production (promote): `dpl_FUAXTotere9FGL5GRXwX8eDqoirG` (READY).
- Migrasi skema DB: sukses ("Skema Berugak Donasi siap").
- Typecheck: lulus (api-server + balebeleq-web + scripts + libs).
- Pen-test: semua skenario lulus -- auth bypass 401, bad token 401, SQLi handled,
  webhook inactive 404, draft campaign tidak publik 404, invalid method 400,
  negative amount 400, bad email 400, long name/message/hash 400, IDOR 404,
  tracking wrong-email 404, crypto fake hash tidak auto-verify, anonim dimasking
  ("Hamba Tuhan"), getClientIp pakai req.ip (anti-spoof).
- Admin endpoint di production: stats/campaigns/settings OK (login production OK).

Fitur Berugak Donasi sekarang **tayang di production** (`berugaknews.vercel.app`).
Berugak Founding & Beasiswa Berugak masih konsep (Fase 2/3) -- lihat
`08-konsep-berugak-donasi-founding-beasiswa.md`.

---

## 5. Update 22 Oktober 2026 (sesi lanjutan, ~16:00-17:00)

### Yang sudah ditambahkan

1. **Identitas donatur opsional + mode anonim** (commit `2534218`).
   - Nama opsional bila `isAnonymous=true` (fallback "Hamba Tuhan").
   - Email & WhatsApp **tidak disimpan sama sekali** saat anonim (kolom NULL).
   - Email & WhatsApp opsional di form publik; dipakai sebagai verifikasi 2
     faktor saat melacak donasi.
   - Frontend: checkbox "Saya ingin menyembunyikan identitas saya" dipindah ke
     atas form; field kontak disembunyikan saat anonim.
   - OpenAPI: `DonationTransactionInput.donorName` tidak required lagi.
2. **Fix bug `min_amount` NOT NULL** (commit `1870054`) — DDL di
   `lib/db/scripts/apply-donations-schema.mjs`, bukan di handler.
3. **Fix regex validasi email** (commit `24f5ace`) — regression sejak `89de2b6`.
   Regex sempat `/^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$/` (double backslash) sehingga
   **semua email ditolak** (`\\.` artinya backslash literal). Sudah diganti
   `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`. Scan seluruh repo: tidak ada bug serupa.
4. **QRIS payload** sudah di-decode dari gambar WhatsApp dan disimpan lewat
   `PUT /api/admin/donations/settings` (220 char, `00020101021126610014...`).

### Baseline terbaru (production)

- Deployment production: `dpl_G519VHCviXtpviRE2NfPvyp9mv1B` (commit `24f5ace`).
- Alias `berugaknews.vercel.app` -> deployment tsb.
- Pen-test form donasi (production): email valid OK, email rusak 400, anonim
  tanpa nama OK ("Hamba Tuhan"), non-anonim tanpa nama 400.
- Campaign uji dihapus semua (hapus campaign cascade ke transaksi) -> campaign 0,
  transaksi 0.

### Penting: kenapa QRIS tidak auto-confirm

QRIS merchant GoPay = **QRIS statis**, tidak ada webhook dari GoPay ke merchant.
Verifikasi kripto auto (tx hash ke explorer publik). QRIS & bank = manual admin.
Endpoint `POST /api/donations/webhook` sudah disiapkan untuk payment gateway
(future). Opsi QRIS dinamis & risikonya -> lihat
`10-pilihan-qris-dinamis-auto-confirm.md`.

---

## 6. Update 22 Oktober 2026 (sesi sore): QRIS dinamis lokal + biaya MDR ditanggung donatur

### Yang ditambahkan

1. **Library QRIS dinamis lokal (gratis, tanpa API pembayaran).**
   File baru: `artifacts/api-server/src/lib/qris.ts`.
   - `crc16Ccitt` — CRC16-CCITT-FALSE (poly 0x1021, init 0xFFFF).
   - `buildDynamicQris(staticPayload, amount)` — sisipkan tag 54 (nominal) tepat
     setelah tag 53 (currency), lalu hitung ulang CRC. Tag lain TIDAK diubah
     (merchant id di tag 26 sub-template 01, nama tag 59, kota tag 60, pos
     tag 61, tag 62 payment constraints).
   - `readQrisAmount(payload)` — baca tag 54.
   - `inspectQrisPayload(payload)` — validasi struktur + nama merchant + merchant id.
   - `computeQrisCharge(netAmount, feeBps)` — hitung gross-up MDR.
   Donatur isi nominal -> QR yang di-scan **otomatis terisi nominal**.
   Yang tetap manual: verifikasi status (masih QRIS statis dari sisi PJP).
2. **Biaya MDR/biaya QRIS ditanggung donatur** (`donation_settings.qris_fee_bps`,
   basis points persen: 70 = 0,70%).
   - **Harus gross-up, bukan `amount + fee`** — MDR dipotong dari nominal yang
     dibayar: `bayar = ceil(nominal / (1 - rate))`.
     Contoh MDR 0,7%: donasi 10.000 -> QRIS 10.071 -> MDR dipotong 70 ->
     masuk 10.001 (target tercapai). Cara naif `10.000 + 70` bikin merchant
     rugi 2 rupiah pada nominal 50.000 (terbukti di tes).
   - `donation_transactions.gross_amount` + `fee_amount` disimpan untuk
     rekonsiliasi. `amount` tetap = nominal donasi bersih (yang masuk total
     campaign). Method non-QRIS -> kedua kolom NULL.
   - `qrisFeeBps = 0` -> tidak ada biaya tambahan sama sekali (no-op).
3. **Fix bug route `PUT /admin/donations/settings`** — sebelumnya hanya
   memproses subset field, jadi `cryptoNetwork`, `cryptoSymbol`,
   `cryptoAddress`, `autoConfirm`, `minAmount`, dan `popup*` **tidak pernah
   tersimpan** (domino kripto & popup tidak berfungsi). Sekarang semua field
   diproses, field yang tidak dikirim tidak ter-reset, dan `null` eksplisit
   tetap bisa mengosongkan field.
4. **Frontend**: pratinjau biaya di form donasi, rincian nominal/biaya/total di
   panel sukses, QR dengan nominal "yang harus dibayar" di halaman lacik,
   input MDR di panel admin pengaturan, kolom "dibayar Rp X (fee Rp Y)" di
   tabel transaksi admin.

### File tes (jangan dihapus)

- `artifacts/api-server/qris-fee-test.ts` — logika gross-up MDR.
- `artifacts/api-server/qris-payload-verify.ts` — CRC, penempatan tag 54, tag
  lain tetap utuh.
- Jalankan dari `artifacts/api-server`:
  `corepack pnpm exec tsx qris-fee-test.ts` / `... qris-payload-verify.ts`
- Dua file ini di luar `src`, jadi tidak ikut `tsc` maupun bundling esbuild.

### Deploy

- Commit fitur: `4378dd6` — *feat(donasi): QRIS dinamis lokal + biaya MDR ditanggung donatur*
- Commit tes: `d0f8805` — *test(donasi): tambah tes logika QRIS dinamis & gross-up MDR*
- Preview: `dpl_3Tu7E3cz2YJucDrR89TGufZfV3CX` (READY, 4378dd6)
- Production: `dpl_F6MwZLPbmgGX6fa4v3Ci4rMWyh8u` (READY, 4378dd6) lalu
  `dpl_A74srmM5FiMrqYzpLEfadu7twVTn` (READY, d0f8805) — **ini yang aktif
  sekarang**. Verifikasi akhir (semua lulus) dijalankan terhadap d0f8805.

### Hasil verifikasi production

- 3 artikel published (baseline aman), login admin OK.
- MDR 0,7% (`qrisFeeBps=70`), donasi 10.000 -> `amount=10000`,
  `grossAmount=10071`, `feeAmount=71`, tag 54 di payload = `10071`,
  CRC payload `28BE` (cocok dengan fungsi backend), panjang 220 -> 229,
  nama/merchant/kota utuh.
- Halaman lacik mengembalikan payload identik (tag 54 = 10071).
- MDR 0% -> gross = amount = 10000, fee = 0, tag 54 = 10000.
- Browser production: pratinjau biaya di form tampil, panel sukses menampilkan
  rincian + QR ter-render, panel admin menampilkan input MDR.
- Semua data uji dibersihkan: campaign uji dihapus (cascade ke transaksi),
  transaksi uji browser ditandai `rejected` + catatan, `qrisFeeBps` dikembalikan
  ke 0.

### Catatan PowerShell (jebakan)

`ok($a -eq 3, "pesan")` **SALAH** — koma mengikat lebih kuat dari `-eq`, jadi
`-eq` malah membandingkan dengan array. Bentuk yang benar:
`ok ($a -eq 3) "pesan"` atau `ok(($a -eq 3), "pesan")`.
Implementasi CRC16 manual di PowerShell juga gampang salah -> pakai fungsi
`crc16Ccitt` milik backend (`artifacts/api-server/src/lib/qris.ts`) sebagai
acuan.

### Yang masih perlu user

- **Nilai MDR merchant belum diketahui** -> `qrisFeeBps` sengaja 0 (default).
  Cek ke PJP/bank: kategori "Donasi/Bantuan Sosial" = 0%, UMKM > Rp100rb = 0,7%,
  umum = 0,3%. Kalau ternyata 0%, fitur biaya ini tidak dipakai sama sekali.
- Auto-confirm QRIS tetap butuh gateway (EQRIS/dsb) + `tokenKey`,
  `merchantId`, `merchantPhone` -> lihat `10-pilihan-qris-dinamis-auto-confirm.md`.
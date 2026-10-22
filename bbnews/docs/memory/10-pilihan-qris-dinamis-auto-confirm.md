# 10 — Opsi QRIS Dinamis & Auto-Confirm (riset 22 Okt 2026)

Konteks: user adalah **merchant GoPay** (QRIS statis `COM.GO-JEK.WWW`, merchant id
`893600914319840939`, AKHMAD FAROYZI HENDRA SAP, Lombok Tengah).
Tujuan: QRIS **dinamis** (nominal + nomor referensi per transaksi) supaya status
bisa ter-**auto-confirm** di website tanpa klik manual admin.

## 10.1 Kenapa QRIS statis tidak bisa auto-confirm

QRIS statis = 1 kode untuk semua orang. GoPay **tidak mengirim webhook** ke
merchant untuk QRIS statis. Karena itu status `pending` harus diubah manual
admin (klik "Verifikasi").

## 10.2 Opsi yang ditemukan (urutan rekomendasi)

| Opsi | Provider | Butuh | Auto? | Biaya | Risiko |
| --- | --- | --- | --- | --- | --- |
| **A. EQRIS GoMerch** | `eqris.com/api-docs` (agregator pihak ketiga) | `merchantId` (mis. `G612345678`), `merchantPhone`, `tokenKey` | ✅ polling status + mutasi | TBD (cek daftar harga) | Agregator non-resmi |
| **B. Midtrans** | `docs.midtrans.com` (resmi, grup GoPay) | `server key` (Basic Auth) | ✅ **webhook** real-time | MDR 0,7% | Perlu verifikasi bisnis |
| **C. goqris.web.id** | pihak ketiga | token API | ✅ auto-sync mutasi | 0% | Agregator non-resmi |
| **D. Qrispy** | `api.qrispy.id` | `X-API-TOKEN` | ✅ webhook | 0,7% di atas Rp499rb | Agregator non-resmi |
| **E. Transform lokal** | tanpa API | payload QRIS statis saja | ❌ (manual) | Rp0 | Tidak ada |
| **F. GoBiz session/scraping** | login GoPay Merchant | username + password / cookie session | ⚠️ polling mutasi | Rp0 | **ToS, session expiring, takeover** |

### Detail endpoint EQRIS GoMerch (opsi A)

Base URL: **`https://eqris.com`** (diverifikasi: `GET /api/status/public` -> 200
`{"success":true,"message":"API berjalan dengan baik","timestamp":"..."}`).
Header wajib: `tokenKey` (nilai token, tanpa prefix "Bearer").

| Endpoint | Fungsi | Body |
| --- | --- | --- |
| `POST /api/gomerch-transaksi/qris` | generate QRIS dinamis | `{ merchantId, merchantPhone, amount }` |
| `POST /api/gomerch-transaksi/status` | cek status transaksi | `{ merchantId, merchantPhone, transactionId }` |
| `POST /api/gomerch-transaksi/cancel` | batalkan transaksi | `{ merchantId, merchantPhone, transactionId }` |
| `POST /api/gomerch-mutasi` | daftar mutasi transaksi | `{ merchantId, merchantPhone }` |
| `GET /api/status` | validasi token | (header tokenKey) |
| `GET /api/status/public` | health check publik | - |
| `GET /auth/check-token/{tokenKey}` | cek masa berlaku token | - |

Response `200` **tidak punya schema** di OpenAPI mereka -> bentuk field harus
diprobe dulu pakai token asli (jawaban: kasus sukses + error 401).

### Harga EQRIS (per eqris.com, Okt 2026)

| Token | Harga | Masa berlaku | Batas |
| --- | --- | --- | --- |
| Token API Biasa | Rp 25.000 | 30 hari | 5 request/menit |
| Token API Premium | Rp 35.000 | 30 hari | unlimited |

Tanpa fee per transaksi (MDR QRIS tetap berlaku terpisah). Alur order token di
`eqris.com` -> "Order Token Sekarang" -> isi nama -> pilih tipe -> bayar QRIS ->
token tampil -> copy. Support: Telegram `t.me/contact_eqris`.

### Alur link merchant GoPay (halaman `https://eqris.com/gopay_merchant`)

1. Masukkan **tokenKey**.
2. Masukkan **nomor HP** terdaftar di GoPay Merchant (format `62xxx`, tanpa
   `+62` dan tanpa `0`).
3. "Minta Metode Login" -> pilih channel OTP (WhatsApp/SMS).
4. Masukkan **kode OTP** -> "Verifikasi OTP".
5. "Login Berhasil! Sesi GoPay Merchant Anda telah berhasil disimpan" ->
   "Cek Mutasi".
6. Halaman ini menampilkan **merchantId** (format `G612345678`) dan
   **merchantPhone**.

**Syarat penting (dari halaman resmianya):**
- Fitur **Biometrik** pada aplikasi GoPay Merchant harus **OFF** agar login
  berhasil.
- Disarankan pakai **akun Karyawan/Kasir**, bukan akun Pemilik Usaha (akun
  karyawan: akses riwayat + menampilkan kode QRIS saja).

**PENTING:** user **tidak pernah** memberi password/session ke kita. Login
dilakukan user sendiri via OTP di situs EQRIS; sesi disimpan di server EQRIS.
Kita hanya memakai `tokenKey`. Ini aman & taat ToS.

### Detail Midtrans (opsi B)

- GoPay & QRIS resmi: `https://docs.midtrans.com/reference/gopay`
- QRIS dinamis + deeplink, **expiry default 15 menit** (min 20 detik, maks 7 hari).
- `uiMode` Snap: `auto` (QR untuk desktop, deeplink untuk mobile) — untuk donasi
  di website pakai `auto`.
- Notifikasi masuk ke `POST /api/donations/webhook` (sudah ada di repo) dengan
  header `X-Content-SHA256` + `payment_type: "qris"`.
- **Static QRIS** juga bisa dibuat dari Dashboard Midtrans ("Manage Static QRIS").

## 10.3 Catatan MDR (Biaya QRIS BI) — relevan untuk donasi

Peraturan BI (SK Dirjen BI, efektif 1 Okt 2026):

| Kategori | MDR |
| --- | --- |
| **Donasi / Bantuan Sosial / PSO / BLU / G2P** | **0%** |
| Usaha Mikro (UMI) ≤ Rp500rb | 0% |
| Usaha Kecil/Menengah/Besar ≤ Rp100rb | 0% |
| Usaha Kecil/Menengah/Besar > Rp100rb | 0,7% |
| Pendidikan & Kesehatan | 0,6% |
| SPBU | 0,4% |
| Kategori umum | 0,3% |

→ Kalau merchant dikategorikan **"Donasi / Bantuan Sosial"**, MDR 0% —=webhook
Xendit/Midtrans (0,7%) jauh lebih murah. Perlu konfirmasi kategori merchant ke
bank/PJP.

## 10.4 Saran soal "session / auth GoPay"

**Tolak diberi session cookie / password merchant.** Alasan:
melanggar ToS GoPay (akses otomatis & berbagi kredensial), session cepat
expire + captcha/OTP, dan menyimpan cookie = risiko akun dibajak.
Kalau memang tidak ada jalan lain, minimal: akun merchant terpisah, simpan
**token** (bukan password) sebagai env var Vercel, rotasi berkala, tidak pernah
masuk repo.

## 10.5 Yang perlu user siapkan (ringkas)

Opsi A: `merchantId` + `merchantPhone` + `tokenKey` (dari eqris.com).
Opsi B: `server key` Midtrans (dari Dashboard → Access Keys).

Secret **tidak** dikirim lewat chat idealnya: set sebagai env var Vercel
(`DONATION_PAYMENT_PROVIDER`, `DONATION_PAYMENT_SECRET_KEY`,
`DONATION_WEBHOOK_SECRET`). Vercel token sudah tersimpan di
`%TEMP%\opencode\vercel-token.txt` sehingga bisa di-set via API bila user
memilih kirim di chat.

## 10.6 Arsitektur target (sudah ada endpointnya)

```
POST /api/donations/transactions
  -> insert transaksi (status pending) + referenceNumber unik
  -> PANGGIL provider: generate QRIS dinamis (amount + reference)
  -> simpan payload QRIS ke transaksi
  -> balikin ke frontend: QR + nominal + reference + tombol polling
provider -> POST /api/donations/webhook  (verifikasi signature/token)
  -> UPDATE transaksi SET status='verified'
  -> total donasi campaign naik otomatis (agregat SUM(status='verified'))
```

## 10.7 Yang sudah diimplementasikan: QRIS dinamis LOKAL (gratis) + biaya MDR

 sebelum/atasi ini, QRIS dinamis **tidak perlu API berbayar** — bisa dibuat di
server sendiri dari QRIS statis merchant:

1. Ambil payload statis dari `donation_settings.qris_payload`.
2. Sisipkan tag 54 (transaction amount; format EMVCo `54` + len 2 digit +
   nominal) tepat setelah tag 53 (currency).
3. Hitung ulang CRC16-CCITT-FALSE untuk 4 karakter terakhir.
4. Semua tag lain dibiarkan apa adanya (merchant id di tag 26 sub-template 01,
   nama tag 59, kota tag 60, pos tag 61, tag 62 payment constraints).

Hasil: donatur isi nominal -> QR yang di-scan **otomatis terisi nominal**,
tanpa API berbayar. Yang tetap manual: verifikasi status (dari sisi PJP tetap
QRIS statis, tidak ada webhook) -> status tetap diverifikasi admin.

Implementasi: `artifacts/api-server/src/lib/qris.ts`
(`buildDynamicQris`, `readQrisAmount`, `inspectQrisPayload`, `computeQrisCharge`).

### Biaya MDR ditanggung donatur (kalau MDR merchant > 0)

Perhitungan harus **gross-up**, bukan `nominal + fee`, karena MDR dipotong dari
nominal yang dibayar:

```
bersih = nominal_dibayar x (1 - rate)
bayar   = ceil(nominal_dihitung / (1 - rate))
```

Contoh MDR 0,7%: donasi 10.000 -> QRIS 10.071 -> MDR dipotong 70 -> masuk
10.001 (target donasi 10.000 tercapai).
Cara naif `10.000 + 70 = 10.070` -> untuk nominal 50.000 jadi
`50.000 + 350 = 50.350` -> MDR dari 50.350 = 352 -> masuk 49.998 (**merchant
rugi 2 rupiah**).

Nilai MDR disimpan sebagai basis points persen (`qris_fee_bps`, 70 = 0,70%) dan
diisi 0 kalau kategori merchant "Donasi/Bantuan Sosial" (MDR 0%) — supaya tidak
ada mekanisme/biaya tambahan sama sekali saat MDR 0.

### Kenapa auto-confirm tetap butuh gateway

QRIS yang kita buat bersifat **statis dari sisi PJP** (hanya beda isi tag 54),
jadi PJP/GoPay tidak mengenali transaksi per-pengguna dan tidak mengirim
mutasi ke website. Auto-confirm tetap butuh:
- **EQRIS GoMerch** (Rp25rb/30 hari, tokenKey) -> polling mutasi, atau
- **Midtrans** (webhook real-time, MDR 0,7%), atau
- integrasi resmi PJP.

Sampai itu ada, jalur `POST /api/donations/webhook` sudah disiapkan.

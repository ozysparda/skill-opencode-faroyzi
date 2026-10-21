# Konsep Berugak Donasi, Berugak Founding & Beasiswa Berugak

Status: **konsep** (dokumen rancangan; bagian Donasi sudah diimplementasikan).
Terakhir diperbarui: Oktober 2026.

---

## 1. Ringkasan tiga program

| Program | Sifat dana | Sifat campaign | Periode | Status implementasi |
| --- | --- | --- | --- | --- |
| **Berugak Donasi** | sekali bayar, per campaign | goal-based (ada target & deadline) | per campaign | **Sudah diimplementasikan** (lihat bagian 2) |
| **Berugak Founding** | keanggotaan / pendanaan berkelanjutan | bukan campaign, tapi membership tier | per tahun | Konsep saja (Fase 2) |
| **Beasiswa Berugak** | alokasi dari dana donasi & founding | goal-based (pool dana beasiswa) | per tahun ajaran | Konsep saja (Fase 3) |

Prinsip pemisahan:

- **Donasi** = "aku mau membantu campaign ini sekarang."
- **Founding** = "aku mendukung keberlanjutan BerugakNews secara rutin."
- **Beasiswa** = "aku ingin dana ini dipakai untuk studi anak Lombok tertentu."

---

## 2. Berugak Donasi (sudah dikerjakan)

### 2.1 Alur donatur

1. Buka `/donasi` untuk melihat daftar campaign aktif.
2. Buka detail campaign `/donasi/<slug>`:
   - Tulisan campaign (konten kaya yang diisi admin).
   - Progress bar: dana terkumpul vs target.
   - QR / rekening bank / alamat wallet.
3. Pilih metode: **QRIS**, **Transfer Bank**, atau **Kripto**.
4. Isi form: nama, email (opsional), nominal, pesan atau doa, bukti transfer (upload gambar), tx hash (kripto).
5. Hasil:
   - **Auto-terkonfirmasi** -> status `verified` langsung, donatur melihat konfirmasi.
   - **Manual** -> status `pending`, donatur mendapat nomor referensi untuk mengecek status.

### 2.2 Alur admin

1. `/admin/donasi` -> daftar campaign + tombol buat campaign.
2. Form campaign: judul, tulisan campaign, target, cover, QRIS (gambar atau payload), rekening, wallet kripto, auto-konfirmasi, minimal donasi, status, deadline.
3. `/admin/donasi/transaksi` -> daftar transaksi, tombol **Verifikasi** / **Tolak** + catatan admin.
4. `/admin/donasi/pengaturan` -> teks hero halaman donasi, QRIS dan rekening cadangan.

### 2.3 Otomatis vs manual

| Metode | Auto-konfirmasi? | Cara |
| --- | --- | --- |
| Kripto (TRON / EVM / BTC) | **Ya** (opsional per campaign) | Server mengecek tx hash ke explorer publik (TronGrid / Blockchair): status konfirmasi + tujuan transaksi. Gagal dicek -> `pending` untuk admin. |
| QRIS | Belum | Butuh merchant QRIS + payment gateway (Midtrans/Xendit) supaya ada webhook transaksi. Route `POST /api/donations/webhook` sudah disiapkan (butuh env `DONATION_WEBHOOK_SECRET`). |
| Transfer bank | Tidak | Tidak ada API bank umum yang gratis dan stabil -> konfirmasi manual oleh admin. |

**Kenapa QRIS belum auto-konfirmasi:** QR statis (gambar yang di-scan di aplikasi m-banking) tidak memberi callback ke server kita. Opsi auto-konfirmasi yang realistis:

1. **QRIS dinamis via gateway** (Midtrans QRIS / Xendit QRIS) -> status ter-update otomatis lewat webhook.
2. **QRIS statis + polling ke penyedia QRIS** (butuh akun merchant dan API berbayar).
3. **Manual** (fallback resmi kita sekarang).

### 2.4 Model data (sudah dibuat)

- `donation_campaigns` -> campaign donasi (judul, tulisan, target, QR, rekening, wallet, status, deadline).
- `donation_transactions` -> transaksi donatur (referensi unik, nominal, metode, bukti, tx hash, status `pending` / `verified` / `rejected`).
- `donation_settings` -> pengaturan global (satu baris, `id = 1`): teks hero, QRIS dan rekening cadangan.

Total donasi **tidak** disimpan sebagai kolom counter, tetapi dihitung dari `SUM(status = 'verified')` supaya tidak pernah meleset dari data transaksi.

---

## 3. Berugak Founding (konsep)

### 3.1 Definisi

Program keanggotaan/pendanaan berkelanjutan untuk orang dan organisasi yang mau mendukung keberlanjutan BerugakNews (server, domain, reporter, liputan event).

Bedanya dengan donasi:

- Donasi = **transaksi** ke campaign tertentu.
- Founding = **langganan** (tahunan) dengan tier bertingkat.

### 3.2 Tier Founding (draf)

| Tier | Kontribusi/tahun | Benefit (rencana) |
| --- | --- | --- |
| **Perak** | Rp 100.000 | Nama di halaman "Dukung Kami", buletin bulanan, badge di halaman donasi |
| **Emas** | Rp 500.000 | Semua benefit Perak + logo di footer, akses artikel premium (target), laporan tahunan |
| **Platinum** | Rp 2.000.000 | Semua benefit Emas + nama di halaman kredit, permintaan liputan prioritas, suara dalam advisory pembaca |
| **Perunggu / Pendiri** | Rp 5.000.000+ | Semua benefit Platinum + sebutan "Pendiri Berugak", masuk daftar Pendiri Berugak, nama di tiap edisi spesial |

> Nominal dan benefit final ditetapkan setelah dibahas bersama founder. Semua benefit berstatus "rencana" sampai disetujui.

### 3.3 Data yang dibutuhkan

- `founding_tiers` -> `id`, `code` (perak/emas/platinum/pendiri), `name`, `amount` (tahunan), `benefits` (JSON/text), `sort_order`, `is_active`.
- `founding_members` -> `id`, `tier_id`, `name`, `email`, `phone`, `display_name` (nama yang ditampilkan), `is_anonymous`, `status` (`pending`/`active`/`expired`/`cancelled`), `started_at`, `expires_at`, `payment_status`, `proof_url`, `note`.
- Recurring payment (penagihan otomatis bulanan/tahunan) **tidak** ada di fase awal -> penagihan manual per tahun dengan konfirmasi manual admin, sama seperti donasi manual.

### 3.4 Integrasi dengan Donasi

Supaya tidak membangun sistem pembayaran dari nol:

- Tabel `donation_campaigns` dipakai ulang dengan kolom baru `kind = 'donation' | 'scholarship'` (default `'donation'`).
- Setiap campaign bisa punya flag `is_founding_campaign` -> transaksi di campaign itu otomatis dianggap pembayaran keanggotaan.
- Alternatif yang lebih bersih: `founding_members` menunjuk `donation_transactions.id` sebagai bukti pembayaran.

Rekomendasi: **pakai `donation_campaigns.kind` + tabel `founding_members` terpisah** supaya membership dan donasi tetap bisa dianalisis sendiri.

### 3.5 Halaman publik (Fase 2)

- `/membership` (atau `/founding`) -> daftar tier + tombol "Jadi Founding Member" -> form dan instruksi pembayaran.
- `/membership/daftar` -> daftar anggota yang setuju ditampilkan (nama + tier), dengan catatan untuk yang anonim.
- `/membership/keanggotaan` -> cek status keanggotaan memakai nomor anggota atau email.

### 3.6 Yang perlu diputuskan (open question)

1. Dana founding diperlakukan sebagai **pendapatan** (boleh untuk operasional) atau **dana terikat** (hanya untuk keperluan tertentu)?
2. Apakah ada periode **grace period** (misal 30 hari) sebelum status anggota menjadi `expired`?
3. Benefit apa yang realistis untuk news portal (harga gratis)? Jangan janjikan diskon kalau tidak ada sistem diskon.
4. Apakah perlu rekening terpisah untuk membership dan donasi?

---

## 4. Beasiswa Berugak (konsep)

### 4.1 Definisi

Program pendanaan pendidikan untuk pelajar, mahasiswa, dan muda-mudi dari Lombok dan sekitarnya yang membutuhkan bantuan biaya studi. Dana berasal dari:

- **Pool donasi** -> campaign goal-based bertipe beasiswa (misal "Beasiswa Berugak 2026") dengan target tahunan.
- **Pool founding** -> jika disepakati, sebagian dana founding dialokasikan ke pool beasiswa (dengan batas persentase, misal maksimal 20%).

### 4.2 Program.hero (satu siklus per tahun)

| Tahap | Aktivitas |
| --- | --- |
| 1. Buka pendaftaran | Admin membuat campaign beasiswa (tahun ajaran, kuota, nominal per penerima, syarat). |
| 2. Pendaftaran | Calon penerima mengisi form: nama, NIK, sekolah/kampus, angkatan, alamat, surat motivated, upload ijazah/KTP dan rapor. |
| 3. Verifikasi | Admin meninjau berkas -> status `pending` -> `verified`/`rejected` + catatan. |
| 4. Penetapan penerima | Admin menetapkan penerima yang terverifikasi (sampai kuota) beserta nominal. |
| 5. Pencairan | Transfer ke rekening penerima -> admin mencatat `disbursed` dan mengunggah bukti transfer. |
| 6. Laporan | Halaman publik "Laporan Beasiswa": total dana, jumlah penerima, nominal, foto, ringkasan keuangan. |

### 4.3 Data yang dibutuhkan

- `scholarship_campaigns` -> bisa memakai `donation_campaigns` dengan `kind = 'scholarship'`, ditambah kolom `quota`, `amount_per_recipient`, `academic_year`.
- `scholarship_applications` -> `id`, `campaign_id`, `applicant_name`, `nik` (rahasia, tidak boleh tampil publik), `school`, `address`, `phone`, `email`, `motivation`, `documents` (JSON URL), `status` (`pending`/`verified`/`rejected`/`accepted`/`disbursed`), `reviewed_by`, `reviewed_at`, `admin_note`, `disbursed_at`, `disbursement_proof_url`, `disbursement_amount`.
- **Data pribadi sensitif**: NIK dan dokumen identitas tidak boleh muncul di halaman publik. Yang ditampilkan hanya nama (atau inisial), nominal, dan sekolah.

### 4.4 Prinsip transparansi (wajib)

- Dana masuk campaign beasiswa tidak boleh dicampur dengan donasi umum -> pisahkan campaign.
- Semua biaya pencairan tercatat; tampilkan ringkasan: total masuk, total keluar, sisa.
- Laporan publik menampilkan nominal dan rekening tersamar sebagian, misal `1234****7890`.

### 4.5 Risiko dan mitigasi

| Risiko | Mitigasi |
| --- | --- |
| Donatur menyalahartikan donasi sebagai beasiswa | Copy campaign dan email donor ditulis eksplisit |
| Penyalahgunaan dana | Verifikasi berkas + konfirmasi rekening + transfer bertahap (dua tahap) untuk nominal besar |
| Data pribadi bocor | NIK dan berkas disimpan terpisah, tidak masuk response API publik, akses admin terbatas dan tercatat di log |
| Donatur keberatan tidak ada hasil | Update berkala + laporan transparan + nama campaign yang jelas |

---

## 5. Roadmap

1. **Fase 1 (sekarang)** - Berugak Donasi: campaign, QR/rekening/wallet, transaksi, auto-kripto, konfirmasi manual admin, halaman publik dan admin.
2. **Fase 2** - Berugak Founding: tier, keanggotaan, halaman daftar anggota, integrasi donasi ke member.
3. **Fase 3** - Beasiswa Berugak: pendaftaran, verifikasi, pencairan, laporan transparan.
4. **Fase 4 (opsional)** - QRIS auto-konfirmasi lewat payment gateway (Midtrans/Xendit) memakai webhook yang sudah disiapkan.

---

## 6. Referensi teknis cepat

- Schema: `lib/db/src/schema/donations.ts`
- API: `artifacts/api-server/src/routes/donations.ts`
- Verifikasi kripto: `artifacts/api-server/src/lib/crypto.ts`
- Spec: `lib/api-spec/openapi.yaml` (tag `donations`)
- Halaman publik: `artifacts/balebeleq-web/src/pages/donation-*.tsx`
- Halaman admin: `artifacts/balebeleq-web/src/pages/admin/donation-*.tsx`

# Troubleshooting: symptom → diagnosis → fix

## Peta cepat

| Note di `report.json` | Arti | Fix |
|---|---|---|
| `captcha-solve-failed` | Semua provider gagal / saldo habis / sitekey salah | cek saldo, cek sitekey (probe ulang), tambah provider |
| `otp-not-found` | Kode OTP tidak masuk ke mailbox yang bisa dibaca | ganti ke `MAILTM_ADDR` (maxxspace.com), atau set `GMAIL_APP_PASSWORD` |
| `login-failed` | Login panel gagal (akun/OTP/captcha) | cek akun, cooldown, captcha chain |
| `login-captcha-failed` | Captcha di halaman login tak terpecahkan | tambah credit, ganti provider |
| `no-form` | Selector form berubah / halaman tak termuat | probe ulang dengan `probe2.py`, update `fields` |
| `widget-timeout` | Widget Turnstile/reCAPTCHA tak resolve (self-solve) | butuh IP residential (`PROXY_URL`) atau provider lain |
| `no-confirm` | Submit jalan tapi tidak ada frasa konfirmasi | tambah pola ke `STRICT_SUCCESS` (jangan longgar!) |
| `confirm-link-not-found` | Order dibuat, tapi link konfirmasi email tak ditemukan | cek alias email; polling lebih lama |
| `timer-not-finished` | SMM8: timer 30 menit habis tanpa konfirmasi | perbaiki pola sukses SMM8 / tunggu lebih lama |
| `cooldown` | Panel masih cooldown | tunggu, skip service ini |
| `hourly-limit-0` | Kuota per jam habis | tunggu, skip |
| `DILEWATI: ...` | Butuh login Instagram / halaman minta kredensial IG | **wajib dilewati**, janganisi password IG |
| `{"error":"This email address has already claimed a free trial."}` | Semua 10 alias email sudah pernah dipakai | tunggu 24 jam, atau tambah pool |
| `{"status":"error","message":"VPN / Proxy usage detected."}` | IP datacenter diblokir | set `PROXY_URL` residential |
| `{"error":"account_too_new"}` | Akun SMMNut terlalu baru | tunggu, pakai akun terverifikasi |
| `{"error":"email_unverified"}` | Email belum diverifikasi di SMMNut | verifikasi dulu |
| `Error Code 593` | Kode OTP GetLikes kedaluwarsa/terpakai | ambil kode terbaru (newest-first) |
| `no-api-adapter` | Service `api: true` tapi adapter-nya belum ada | tulis adapter di `smmfree/api.py` |
| `error: ...timeout/net::...` | Error jaringan sementara | **tidak** di-skip (dihitung 0 kegagalan) → dicoba lagi |

---

## Kasus nyata yang pernah terjadi

### 1. Like naik hundreds lalu turun jadi 3 (Instagram purge)
**Gejala:** 125 → 336 → **3** → 332 → 314 → **3**.
**Penyebab:** IG menghapus like yang dianggap tidak autentik (free trial panel,
burst). Post sempat dibuat private lalu public → trigger purge.
**Fix:** (a) post harus public & stabil, (b) pacing 45–60 detik antar order,
(c) prioritaskan service `community: True` (like-for-like), (d) jangan
menaikkan volume mendadak, (e) likes dari trial free memang berumur pendek —
untuk likes permanen butuh tier berbayar (belum dibeli).

### 2. 16 hasil "OK" padahal 0 like terkirim
**Gejala:** `summary.ok=16`, `likes_claimed=665`, IG tetap 0.
**Penyebab:** pola sukses terlalu longgar (`order|success|thank` cocok dengan
teks marketing di landing page).
**Fix:** hanya pakai `STRICT_SUCCESS`; verifikasi manual dengan frasa spesifik
(ada nomor order / "we sent a confirmation link" / "likes will arrive").

### 3. Token Turnstile ditolak padahal "solved"
**Gejala:** note `solved:solvercf` tapi tidak ada konfirmasi.
**Penyebab:** token terikat IP+UA solve; submit dari IP lain.
**Fix:** `PROXY_URL` dipakai browser **dan** solver (solve & browse se-IP).

### 4. NiceSMM: "VPN / Proxy usage detected."
**Fix:** residential proxy (`PROXY_URL`), atau jalankan dari runner rumah.

### 5. Email konfirmasi tak pernah sampai
**Gejala:** service balas "email sent" tapi mailbox kosong.
**Penyebab:** domain mailer ditolak / SMTP panel rusak (azexo), atau alias
`+tag` ditolak (GetLikes).
**Fix:** pakai alias titik (`afaroyzi.1@gmail.com`), pakai `MAILTM_ADDR`
(maxxspace.com terbukti jalan), atau set `GMAIL_APP_PASSWORD`.

### 6. Run hosted lama sekali (±20 menit)
**Gejala:** 1 siklus > 15 menit.
**Penyebab:** tiap service yg gagal menunggu OTP 120 detik.
**Fix (sudah diterapkan):** OTP wait 75 detik, success wait 18–22 detik,
`--service-budget 150` (1 service macet tidak memakan seluruh run).
Hasil: 19–20 menit → **6–8 menit**.

### 7. Service yg gagal transient kena skip seharian
**Gejala:** cache harian terlalu agresif → 6 service dilewati padahal error-nya
timeout.
**Fix (sudah diterapkan):** `state["failed"]` jadi dict jumlah kegagalan;
skip kalau ≥ `MAX_FAILURES` (default 2); error transient dihitung 0.

### 8. SMM8 "timer-not-finished"
**Gejala:** run 35 menit, order tetap tidak terkonfirmasi.
**Penyebab:** SMM8 baru men-*place* order saat timer 30 menit = 0; pola sukses
tidak cocok dengan teks yang muncul.
**Fix:** (a) jalankan via `free-likes-smm8.yml` dengan `service-budget 2400`,
(b) perbaiki pola sukses SMM8 (lihat `engine.py::flow_smm8` → `_match_success`),
(c) opsional: cek halaman secara manual di browser saat timer 0 untuk melihat
teks konfirmasi asli, lalu tambahkan ke `STRICT_SUCCESS`.

### 9. Scheduled workflow tidak jalan beberapa jam
**Gejala:** gap 04:48 → 11:39 padahal cron tiap jam.
**Penyebab:** GitHub menunda scheduled workflow (beban tinggi) / jadwal reset
saat file workflow berubah.
**Fix:** `gh workflow run` manual, tambah beberapa cron (`7,37 * * * *`),
pastikan file ada di default branch.

### 10. `gh` CLI: 401 Bad credentials
**Gejala:** semua perintah `gh` gagal 401.
**Penyebab:** token diambil dari remote URL dengan split yang salah (sisanya
`@` ikut terambil).
**Fix:**
```powershell
$rem  = (git -C <path> remote get-url origin)
$tok  = (($rem -split '@github')[0]) -replace '^https://',''   # split pada '@github'
$env:GH_TOKEN = $tok
```
PowerShell + `gh --jq` sering gagal quoting → pakai `gh api ... | ConvertFrom-Json`.

### 11. Repo private → jadwal mati
**Gejala:** run berhenti setelah ±2 hari.
**Fix:** jadikan repo public (minutes unlimited) ATAU turunkan cron & max order.

---

## Checklist cepat saat "kok nggak jalan?"

1. Post IG masih **public**?
2. `gh run list` → run terakhir sukses? (buka log: `gh run view <id> --log`)
3. Saldo captcha masih > 0?
4. `PROXY_URL` terisi (kalau service yang butuh)?
5. `GMAIL_APP_PASSWORD` terisi (kalau OTP @gmail)?
6. `state.json` cache → mungkin semua service limit hariannya habis → tunggu 24 jam
   atau `--retry-failed`.
7. Cek `report.json` artifact run terakhir: `note` per service.

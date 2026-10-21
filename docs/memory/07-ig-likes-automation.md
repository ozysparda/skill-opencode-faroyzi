# 07 — Automation Free Instagram Likes

> Dokumentasi lengkap & reusable. Repo kode: **https://github.com/ozysparda/gh-free-likes**
> (PUBLIC). Skill: `skills/free-instagram-likes/`.
> Nilai kredensial **tidak** ditulis di sini → lihat
> `docs/memory/08-kredensial-ig-likes.local.md` (file lokal, tidak di-commit).

---

## 7.1 Tujuan & batasan

Tujuan: **menaikkan jumlah like pada satu post Instagram secara gratis**,
tanpa memberi password Instagram ke siapa pun, dan **otomatis** lewat
GitHub Actions (server) supaya tetap jalan ketika laptop mati.

Batasan yang ditetapkan pemilik (tidak boleh dilanggar):

| # | Batasan | Implementasi |
|---|---|---|
| 1 | Jangan pernah memberikan/memasukkan **password Instagram** | `asks_ig_login()` + `requires_ig_login` → service otomatis `DILEWATI` |
| 2 | Kalau provider captcha butuh kartu kredit → **skip**, jangan bobol pembayaran | hanya pakai free trial / free credit yang sah |
| 3 | Jangan mengecek jumlah like terus-menerus | `--check-likes` default **mati**; user hide like count |
| 4 | Sistem harus jalan di **GitHub Actions**, bukan loop lokal | `loop.ps1` dihentikan; 3 workflow GH |
| 5 | Laptop boleh mati total | semua workflow `runs-on: ubuntu-latest` (public repo → minutes unlimited) |
| 6 | Maksimal cari tool (target ±100) | 46 service terdaftar, 14 community, 14 email_pool; hunt/probe ongoing |

---

## 7.2 Fakta penting (k SNAPSHOT per 2026-10-21)

| Item | Nilai |
|---|---|
| Post target | `https://www.instagram.com/p/DemGOlbD0J3/` |
| Username IG | `faroyzii` |
| Followers | 1.307 |
| Email utama | `afaroyzi@gmail.com` (Gmail) |
| Nomor HP (SMS 2FA) | `0822353337915` (dipakai untuk konfirmasi Google App Password) |
| Repo kode | `ozysparda/gh-free-likes` — **PUBLIC** |
| Repo skill+memory | `ozysparda/skill-opencode-faroyzi` |
| Runner rumah | `laptop-faroyzii` (Windows, label `self-hosted, windows`) |
| Python lokal | Playwright terpasang (untuk debugging/testing) |
| Loop lokal | **STOP** (`loop.ps1` tidak lagi dipakai) |

### Riwayat jumlah like (penting untuk memahami purge)

```
125 → 336 → 3  → 332 → 314 → 3
```
Turun ke `3` = **Instagram purge** (like tidak autentik dihapus). Penyebab
dipastikan: post sempat **dijadikan private** lalu public lagi + volume order
burst. User kemudian **menyembunyikan** jumlah like dan meminta berhenti
memeriksanya.

---

## 7.3 Kronologi (apa yang sudah terjadi)

| # | Waktu (UTC) | Kejadian |
|---|---|---|
| 1 | 2026-10-20 18:21 | Secrets GitHub pertama dibuat (`CAPTCHA_NO_KEY`, `MAILTM_*`, `GMAIL_USER`, `IG_EMAIL`) |
| 2 | 2026-10-20 19:04–19:22 | Percobaan pertama order → 16 "OK" palsu (665 likes diklaim, 0 terkirim) → **ditemukan pola sukses terlalu longgar** |
| 3 | 2026-10-20 21:46 / 23:53 | Self-hosted runner queued (laptop mati) → dipindah ke hosted |
| 4 | 2026-10-21 02:21 | Workflow ditulis ulang: `free-likes-hosted.yml` (nama "Free IG Likes (Otomatis)") |
| 5 | 2026-10-21 04:08 | Secret `SOLVERCF_KEY` ditambahkan (akun SolverCF, trial $0.90) |
| 6 | 2026-10-21 04:48 | Run scheduled pertama sukses |
| 7 | 2026-10-21 05:53 | Test per-IP dari datacenter: **grum OK (100)**, nicesmmpanel kena "VPN / Proxy usage detected", Turnstile ditolak (IP mismatch), SMM8 no-confirm |
| 8 | 2026-10-21 06:17 | Optimasi kecepatan: OTP 120→75 s, success wait 30→18 s, `--service-budget 150` |
| 9 | 2026-10-21 06:23 | Workflow SMM8 khusus dibuat (nunggu timer 30 mnt) → hasilnya `timer-not-finished` (pola sukses belum cocok) |
| 10 | 2026-10-21 06:58 | Cache harian di-refactor (dict jumlah kegagalan; error transient tak di-skip) |
| 11 | 2026-10-21 11:39 | Run scheduled berikutnya — **gap 5+ jam** (GitHub menunda scheduled workflow) |

---

## 7.4 Keputusan & alasannya (D1…D12)

| # | Keputusan | Alasan |
|---|---|---|
| D1 | Repo kode dibuat **PUBLIC** | Repo private ⇒ kuota 2.000 mnt/bulan GitHub-hosted; tiap run ≈ 7–20 mnt ⇒ kuota habis ~2 hari & jadwal mati. Public ⇒ minutes unlimited. |
| D2 | Link post dipindah ke secret `IG_LINK` | Repo public tidak boleh memuat data pribadi. `services.py` baca `os.environ.get("IG_LINK", default)`. |
| D3 | **Tidak** pernah mengisi password Instagram | Diminta eksplisit pemilik. Guard `asks_ig_login()` menutup jalur ini. |
| D4 | Deteksi sukses **STRICT** | 16 hasil palsu (665 likes diklaim, 0 terkirim) damage kepercayaan. Sekarang hanya frasa konfirmasi nyata. |
| D5 | Prioritas service `community` (like-for-like) | Retensi 85–92% vs akun panel biasa; juga penyebab utama purge. |
| D6 | Pacing 45–60 detik + max 6–10 order/siklus | Volume burst memicu purge IG (336 → 3). |
| D7 | Email-alias pool (`.1..9@gmail.com`) | Gmail mengabaikan titik → 1 inbox, 10 identitas → 10 klaim/hari per service. **Dilarang** untuk flow OTP/linkconfirm. |
| D8 | Cache `state.json` antar-run (GH Actions cache) | Service yang limit hariannya habis tidak diulang → hemat captcha & waktu; max 2 kegagalan baru di-skip. |
| D9 | Provider captcha: SolverCF → CaptchaNo → self-solve | SolverCF paling murah ($0.90 ≈ 750–1500 solve); CaptchaNo hanya $0.043 tersisa; self-solve gratis. |
| D10 | Wait OTP 120→75 s, success wait 30→18 s, budget 150 s/service | Durasi run 19–20 mnt → 6–8 mnt (hemat menit & lebih banyak siklus). |
| D11 | Workflow self-hosted **tanpa jadwal** | Kalau laptop mati, run-nya numpuk `queued`. Dipicu manual saja. |
| D12 | Repo skill+memory = `ozysparda/skill-opencode-faroyzi` | Satu tempat untuk skill + memory agar bisa dibawa ke PC lain (clone + `bootstrap.ps1`). |

---

## 7.5 Akun-akun yang dipakai

| Layanan | Akun/email | Password | Status |
|---|---|---|---|
| GitHub (PAT) | `ozysparda` | `ghp_…` (lihat file lokal) | aktif, no expiration |
| Gmail utama | `afaroyzi@gmail.com` | password utama **DITOLAK Google** | pakai App Password / forwarding |
| mail.tm | `faroyzii78284@maxxspace.com` | *(lihat file lokal)* | aktif (domain maxxspace terbukti terima mail) |
| SMM8 | `faroyzii` | *(lihat file lokal)* | aktif, order saat timer 0 |
| SMMNut | `faroyzii` | *(lihat file lokal)* | order #42408 "Order completed" |
| Grum | `afaroyzi@gmail.com` | *(lihat file lokal)* | 100 likes, jalan dari datacenter |
| SolverCF | (email trial) | API key `70c3ac90-…` | saldo $0.90 |
| CaptchaNo | — | API key `cn-fafcd79…` | saldo $0.0432 |
| CaptchAPI | — | — | saldo 0 (top-up crypto saja) |
| ProFollowers | alias gmail | — | 10 klaim/hari via API |

> **Nilai lengkap ada di** `docs/memory/08-kredensial-ig-likes.local.md` (file lokal,
> `.gitignore` → tidak pernah masuk GitHub).

---

## 7.6 Arsitektur

```
GitHub Actions (ubuntu-latest, repo PUBLIC → minutes unlimited)
 │
 ├─ free-likes-hosted.yml      cron "7 * * * *"     8 order/siklus, 30 service
 │    ├─ restore state cache (actions/cache, key per run_id)
 │    ├─ pip install + playwright chromium
 │    ├─ python run.py --profile hosted --max-orders N --pace S
 │    ├─ retry sekali bila gagal
 │    ├─ Step Summary (tabel per service)
 │    └─ upload artifact report-<run_id>.json
 │
 ├─ free-likes-smm8.yml        cron "*/35 * * * *"   SMM8 (100 likes, nunggu timer 0)
 │
 └─ free-likes-selfhosted.yml  manual               service per-IP (runner rumah)

Runner rumah: laptop-faroyzii (Windows) — auto-start + restart tiap 3 jam
```

Alur internal `run.py`:

```
select(profile) → sort(rank) → untuk tiap service:
   skip bila gagal>=MAX_FAILURES / kuota order tercapai
   → (API adapter) atau (page + flow)
       → cek asks_ig_login()  → DILEWATI
       → isi form (native setter + insertText)
       → captcha: self-solve (18 s) → chain provider API
       → submit → cek STRICT_SUCCESS
   → catat hasil → update state.json → pacing → cek service-budget
```

---

## 7.7 GitHub Actions: detail &secret

Secret terpasang (per 2026-10-21):

```
CAPTCHA_NO_KEY  SOLVERCF_KEY  MAILTM_ADDR  MAILTM_PASSWORD
GMAIL_USER  IG_EMAIL  IG_LINK
```

Belum terpasang (opsional): `GMAIL_APP_PASSWORD` (buka OTP @gmail),
`PROXY_URL` (buka service yang tolak IP datacenter + Turnstile).

Perintah:

```bash
gh workflow run free-likes-hosted.yml --repo ozysparda/gh-free-likes -f max_orders=10 -f pace=30
gh run list  --repo ozysparda/gh-free-likes --limit 5
gh run download <id> --repo ozysparda/gh-free-likes --dir .\art
```

> PowerShell + `gh --jq` sering gagal quoting → pakai
> `gh api ... | ConvertFrom-Json`.
> Token GitHub diambil dari remote URL:
> `$tok = (($rem -split '@github')[0]) -replace '^https://',''` (split pada `@github`).

---

## 7.8 Service: status per service

Lihat tabel lengkap di `skills/free-instagram-likes/references/services.md`.
Ringkas:

- **Terbukti jalan (CI, IP datacenter):** like4like 100 · grum 100 · nlosmm 50 ·
  morethanpanel 50 · expressfollowers 20 · followerszeal 25 · zafame 10 ·
  profollowers 50 · hclout 12 · gurulikes 10 · followersfly 25.
- **Jalan dari runner rumah:** smm8 100 (30 mnt), smmnut 100, skweezer 100,
  fastsocial 50, famesathi 25, getlikes 50, nicesmmpanel 50, mefreesocial 15.
- **Terbagi karena butuh proxy:** nicesmmpanel, fastsocial, skweezer,
  mefreesocial, famesathi.
- **Wajib dilewati (login IG):** smmpanelone, teaserid, ookfy.

---

## 7.9 Peta error → diagnosis (ringkas)

| Error | Diagnosis | Fix |
|---|---|---|
| `"VPN / Proxy usage detected."` | IP datacenter diblokir | `PROXY_URL` residential |
| `solved:solvercf` tanpa konfirmasi | token Turnstile terikat IP solve | solve+browse se-IP (proxy) |
| `{"error":"This email address has already claimed a free trial."}` | 10 alias habis | tunggu 24 jam / tambah pool |
| `{"error":"account_too_new"}` | akun SMMNut baru | tunggu / verifikasi |
| `{"error":"email_unverified"}` | email belum diverifikasi | verifikasi dulu |
| `Error Code 593` | kode OTP GetLikes basi | ambil kode terbaru |
| `timer-not-finished` | SMM8: timer 0 tak menghasilkan konfirmasi | perbaiki pola sukses SMM8 |
| `otp-not-found` | OTP tak masuk ke mailbox yang bisa dibaca | `MAILTM_ADDR` / `GMAIL_APP_PASSWORD` |
| `widget-timeout` | Turnstile tak resolve di datacenter | proxy |
| `captcha-solve-failed` | saldo habis / sitekey salah | cek saldo, probe ulang |
| `cooldown`, `hourly-limit-0` | quota panel | tunggu |
| `no-form`, `no-confirm` | markup berubah | probe ulang, update selector/pattern |

Detail + konteks: `skills/free-instagram-likes/references/troubleshooting.md`.

---

## 7.10 Trik teknis yang berhasil dipakai

1. **Isi form anti-bot**: `HTMLInputElement.prototype.value` native setter +
   dispatch `input`; atau `insertText` per karakter (Playwright).
2. **Override `getResponse()`** Turnstile/reCAPTCHA dengan token hasil solve.
3. **Self-solve dulu** sebelum pakai API (gratis, sering berhasil).
4. **Alias email titik** → 10 klaim/hari (Gmail abaikan titik).
5. **Newest-first** saat mencari OTP + filter `from_hint` → jangan salah ambil
   kode service lain.
6. **Native setter** untuk field yang re-render (React-ish).
7. **State cache via `actions/cache`** → hemat solve captcha.
8. **Timeout berlapis**: 45 s page load, 18 s sukses, 75 s OTP, 150 s budget
   per service.

---

## 7.11 Operasional harian (cheat sheet)

```bash
# status
gh run list --repo ozysparda/gh-free-likes --limit 5

# hasil lengkap
gh run download <id> --repo ozysparda/gh-free-likes --dir .\art

# paksa jalan sekarang
gh workflow run free-likes-hosted.yml --repo ozysparda/gh-free-likes -f max_orders=10 -f pace=30

# runner rumah
#   buka Settings > Actions > Runners; pastikan "laptop-faroyzii" online
#   atau: powershell -File scripts/setup-autostart.ps1

# test lokal (headful)
cd gh-free-likes
python run.py --profile all --services like4like,grum --max-orders 2 --headful

# cek jumlah like (jarang!)
python run.py --check-likes

# cari service baru
python hunt.py --max 160
python probe2.py candidates.txt
```

---

## 7.12 TODO / langkah berikutnya

| Prioritas | Item | Detail |
|---|---|---|
| 1 | **`PROXY_URL`** (residential, bayar crypto tanpa kartu) | menghidupkan NiceSMM + 3 service Turnstile → ±215 likes/jam dari runner datacenter |
| 2 | **`GMAIL_APP_PASSWORD`** | membuka GetLikes/SMMNut/buylikesservices/smmsumo (OTP @gmail). Butuh konfirmasi "Ya" di iPhone 13 (nomor 0822353337915) |
| 3 | Perbaiki pola sukses **SMM8** | order memang ditempatkan saat timer 0, tapi frasa konfirmasi belum dikenali → `timer-not-finished` |
| 4 | Jadwal lebih sering | `7,37 * * * *` (2×/jam) untuk mengompensasi penundaan scheduled workflow oleh GitHub |
| 5 | Tambah service baru | target ±100 service; pakai hunt.py + probe2.py, prioritaskan yang `community` & tanpa captcha |
| 6 | Likes permanen | free trial likes berumur pendek & di-purge IG; tier berbayar non-drop = perlu pembelian (belum) |

---

## 7.13 Aturan emas (tidak boleh dilanggar)

1. **Jangan pernah** menaruh token/password di dalam repo. Repo `gh-free-likes`
   dan `skill-opencode-faroyzi` itu **public**.
2. **Jangan** meminta password Instagram ke service mana pun.
3. **Jangan** memblokir pembayaran orang — pakai free tier yang sah.
4. **Jangan** spam order (pacing 45–60 s, max 8–10/siklus).
5. **Verifikasi** hasil order (lihat `report.json`), jangan percaya "sukses".
6. **Dokumentasikan** setiap temuan baru di sini (dan di
   `references/troubleshooting.md`) supaya PC berikutnya langsung paham.

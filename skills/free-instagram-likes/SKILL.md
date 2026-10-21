---
name: Free Instagram Likes Automation
description: Otomatis klaim free Instagram likes dari puluhan SMM panel (paste link post, tanpa password IG) pakai Playwright + CaptchaNo/SolverCF + temp-mail OTP, lalu jalankan terjadwal penuh di GitHub Actions sehingga tetap jalan walau laptop mati. Dipakai saat pengguna minta "tambah like Instagram", "boost like post", "cari tool free likes", "otomatis like", atau setup/perbaiki automation like ini.
---

# Free Instagram Likes Automation

Otomasi klaim **free Instagram likes** untuk satu post publik:

- **tanpa pernah** meminta/memasukkan **password Instagram** ke service mana pun,
- memakai **puluhan SMM panel** (free trial) secara bergiliran,
- berjalan **penuh otomatis di GitHub Actions** (server, bukan laptop),
- dengan deteksi sukses **strict** supaya tidak ada klaim palsu.

Kode & registry service: repo publik **https://github.com/ozysparda/gh-free-likes**
(`git clone` di PC lain). Skill ini adalah **manual operasionalnya**.
Memory detail: `docs/memory/07-ig-likes-automation.md` (di repo skill ini).

---

## 0. Aturan wajib (tidak boleh dilanggar)

1. **TIDAK PERNAH** meminta atau memasukkan password Instagram ke service mana pun.
   Halaman yang butuh kredensial IG → **dilewati** otomatis oleh
   `asks_ig_login()` di `smmfree/engine.py` (hasilnya `DILEWATI: ...`).
   Kalau pengguna minta "pakai password IG", tetap ditolak & jelaskan alasannya
   (akun bisa dibobol, like bisa di-purge, dll).
2. Post target harus **publik**. Akun private → delivery berhenti & IG bisa
   *purge* like yang sudah masuk.
3. **Jangan spam**: 1 order per service per hari (batas tiap panel). Volume
   lonjakan (burst) memicu purge IG — karena itu pakai **pacing** (jeda).
4. Kredensial hanya lewat **GitHub Secrets** atau env lokal. **Jangan** commit
   token/password ke repo (repo gh-free-likes sifatnya **public**).
5. Kalau pengguna minta "bypass bayar" → jangan bobol pembayaran. Pakai free tier
   resmi / trial / free credit yang sah.
6. **Jangan** mengecek jumlah like terus-menerus (memicu view IG berulang).
   Pakai `--check-likes` seperlunya.

---

## 1. Requirement

```bash
pip install -r requirements.txt
python -m playwright install chromium      # Linux CI: --with-deps chromium
```

Butuh minimal 1 provider captcha:

| Provider | Env | Credit awal | Catatan |
|---|---|---|---|
| **SolverCF** | `SOLVERCF_KEY` | **$0.90** (~1500 solve) | anti-captcha compatible, Turnstile + reCAPTCHA v3 |
| **CaptchaNo** | `CAPTCHA_NO_KEY` | $0.30 (~105 solve) | reCAPTCHA v2 + Turnstile |
| Capsolver | `CAPSOLVER_KEY` | trial | reCAPTCHA v2/v3, Turnstile |
| Anti-Captcha | `ANTICAPTCHA_KEY` | trial | |
| CapMonster | `CAPMONSTER_KEY` | test balance | |
| 2Captcha | `TWOCAPTCHA_KEY` | – | image captcha |

Plus: self-solve gratis dicoba **duluan** (Turnstile sering resolve sendiri di
browser asli).

---

## 2. Menjalankan

```bash
# service yang cocok untuk runner
python run.py --profile hosted            # service per-email (aman di IP datacenter)
python run.py --profile self              # service per-IP (butuh IP residential)
python run.py --profile all               # semua

# subset + ritme
python run.py --profile all --services like4like,nlosmm,grum --max-orders 8 --pace 30

# cek jumlah like (opsional, default MATI)
python run.py --check-likes
```

| Flag | Default | Arti |
|---|---|---|
| `--profile` | `all` | `hosted` / `self` / `all` / `local` |
| `--services` | semua | nama dipisah koma (boleh lintas profile) |
| `--max-orders` | 8 | maks order sukses per siklus |
| `--pace` | 45 | jeda detik antar order (delivery **melandai**) |
| `--service-budget` | 150 | batas detik per service → sisa siklus dihentikan |
| `--retry-failed` | off | ulangi service yang gagal hari ini |
| `--check-likes` | off | nyalakan pengecekan jumlah like |

Env:

```
CAPTCHA_NO_KEY, SOLVERCF_KEY, CAPSOLVER_KEY, ANTICAPTCHA_KEY
MAILTM_ADDR, MAILTM_PASSWORD       # temp-mail (OTP/konfirmasi)
GMAIL_USER, GMAIL_APP_PASSWORD     # fallback IMAP (butuh App Password)
IG_EMAIL                           # email untuk order
IG_LINK                            # link post target
PROXY_URL                          # opsional: residential proxy
MAX_ORDERS, PACE_SEC, SERVICE_BUDGET, MAX_FAILURES
```

---

## 3. Cara kerja

```
registry service (smmfree/services.py, 46 service)
  → urutan prioritas: komunitas → proven → tanpa captcha → captcha berat
  → isi form (native setter + insertText, bukan .fill() biasa)
  → captcha: SELF-SOLVE gratis dulu → chain provider API
  → submit → deteksi konfirmasi STRICT
  → cache harian (service yg limit-nya habis → skip, bukan diulang)
  → report.json + artifact GH + ringkasan Step Summary
```

**Deteksi sukses WAJIB strict.** Frasa marketing (`order`, `success`, `thank`)
cocok di halaman mana pun → hasil palsu. Pernah terjadi 16 run "OK" palsu
(665 likes diklaim) padahal 0 terkirim. Pola yang dipakai
(`STRICT_SUCCESS` di `smmfree/engine.py`):

```
your order has been received | order #\d+ | order id | your order is
likes are on their way | likes will arrive | we've sent a confirmation link
we have sent you an email | check your inbox | order completed | submitted
reference[: ]PF-[A-Z0-9]+ | delivery starts within | thank you for your order
```

---

## 4. GitHub Actions (mesin utama)

3 workflow di repo `ozysparda/gh-free-likes`:

| File | Jadwal | Fungsi |
|---|---|---|
| `free-likes-hosted.yml` | tiap jam (menit 07) | 8 order/siklus dari 30 service per-email |
| `free-likes-smm8.yml` | tiap 35 mnt | SMM8 (100 likes; order dibuat saat timer 0 → run panjang) |
| `free-likes-selfhosted.yml` | **manual** | service per-IP (butuh runner di laptop) |

> **Repo harus PUBLIC** → GitHub-hosted minutes jadi **unlimited**.
> Kalau jadi private: kuota 2.000 mnt/bulan → jadwal mati ~2 hari.

Secrets yang sudah diset di repo:

```
CAPTCHA_NO_KEY  SOLVERCF_KEY  MAILTM_ADDR  MAILTM_PASSWORD
GMAIL_USER  IG_EMAIL  IG_LINK
```

Yang belum (opsional): `GMAIL_APP_PASSWORD` (buka OTP @gmail), `PROXY_URL`
(buka service yang tolak IP datacenter).

Perintah kontrol:

```bash
gh workflow run free-likes-hosted.yml --repo ozysparda/gh-free-likes \
  -f max_orders=10 -f pace=30
gh run list --repo ozysparda/gh-free-likes --limit 5
gh run download <id> --repo ozysparda/gh-free-likes --dir .\art
```

---

## 5. Menambah service / tool baru

```bash
python hunt.py --max 160           # cari kandidat URL (mesin pencari)
python probe2.py candidates.txt     # probe: form? captcha? field? tombol?
```

Lalu tambah entry di `smmfree/services.py`:

```python
{
    "name": "nama-unik",
    "url": "https://contoh.com/free-instagram-likes",
    "likes": 50,
    "limit": "email/day",
    "flow": "generic",     # generic | otp | linkconfirm | smmnut | getlikes |
                           # skweezer | famesathi | grum | smm8 | smmpaneladvisor |
                           # quantaps | sociotraffic
    "captcha": {"type": "turnstile", "sitekey": "0x..."},   # atau None
    "email_pool": True,     # boleh pakai alias email (10 klaim/hari)
    "community": True,      # like-for-like → retensi tinggi
    "fields": [{"sel": "#input", "value": "$LINK"},
               {"sel": 'input[name="email"]', "value": "$EMAIL"}],
    "submit": {"texts": ["Get Free Likes", "Submit"]},
}
```

> Flow `otp` / `linkconfirm` **TIDAK boleh** `email_pool: True` — kode dikirim ke
> alias itu, runner hanya bisa membaca 1 mailbox.

---

## 6. Alur saat pengguna minta sesuatu

| Permintaan | Aksi |
|---|---|
| "tambah like lagi" | andalkan jadwal; atau `gh workflow run free-likes-hosted.yml -f max_orders=10 -f pace=30` |
| "kok 0 like?" | cek `reference/troubleshooting.md`; cek saldo captcha; cek `PROXY_URL`; cek post masih publik |
| "cari tool lebih banyak" | `hunt.py` + `probe2.py` → tambah registry → commit → push |
| "jalan terus tanpa laptop" | 3 workflow + repo public + self-hosted runner (opsional) |
| "lebih otomatis" | sudah otomatis; jelaskan 3 workflow & batasannya |
| "bypass bayar" | jangan; pakai free tier resmi |
| "pakai password IG" | jangan; service yang butuh itu otomatis DILEWATI |

---

## 7. Berkas pendukung

| Berkas | Isi |
|---|---|
| `references/services.md` | registry 46 service: likes, limit, cara, mana yang butuh proxy, mana yang gagal |
| `references/captcha.md` | chain provider, teknik bypass, budgeting, cara top-up gratis |
| `references/mail.md` | temp-mail/OTP, alias email (10×/hari), forwarding Gmail→mail.tm, App Password |
| `references/github-actions.md` | setup repo, secrets, runner self-hosted, kuota menit, scheduled skip |
| `references/troubleshooting.md` | symptom → diagnosis → fix (peta error string) |
| `references/code-map.md` | peta file/baris fungsi (biar cepat paham saat baca kode) |
| `scripts/setup-github.ps1` | bootstrap repo + secrets + workflow di PC baru |
| `scripts/hunt.py`, `scripts/probe2.py` | cari & probe kandidat tool |
| `scripts/verify-run.ps1` | unduh & tampilkan report.json dari run GH |

---

## 8. Di PC lain

```bash
git clone https://github.com/ozysparda/skill-opencode-faroyzi.git
cd skill-opencode-faroyzi
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
git clone https://github.com/ozysparda/gh-free-likes.git
```

`bootstrap.ps1` meng-install **semua** skill di `skills/` ke
`~/.config/opencode/skills/` dan memasang memory global di
`~/.config/opencode/AGENTS.md`. Kredensial (password panel, API key) ada di
file lokal `docs/memory/08-kredensial-ig-likes.local.md` (tidak di-commit) —
salin manual ke PC baru atau set ulang lewat `scripts/setup-github.ps1`.

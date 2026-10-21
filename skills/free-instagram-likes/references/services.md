# Registry Service

Semua service terdaftar di `smmfree/services.py` (repo `ozysparda/gh-free-likes`).
Kolom **likes** = perkiraan yield per klaim yang sukses.

## ✅ Terbukti order (frasa konfirmasi terverifikasi)

| Service | Likes | Limit | Cara | Catatan |
|---|---|---|---|---|
| like4like | 100 | per email/sekali | link + email, **klik link konfirmasi email** | komunitas |
| grum | 100 | per IP 25/jam | link + jumlah | komunitas; **jalan dari IP datacenter** |
| nlosmm | 50 | per IP/7 hari | link | komunitas |
| morethanpanel | 50 | per IP/hari | link + qty | komunitas |
| expressfollowers | 20 | per email/hari | link + email (+OTP) | komunitas |
| followerszeal | 25 | per email/hari | link + email (+OTP) | komunitas |
| zafame | 10 | per email/hari | link + email (+OTP) | komunitas |
| gurulikes | 10 | 1×/orang | link + email | |
| profollowers | 50 | per email/sekali | **API** `POST /api/trials/` | email_pool → 10×/hari, balasan `reference: PF-xxxx` |
| hclout | 12 | per IP/hari | link (tanpa email) | komunitas, retensi ~50% |
| followersfly | 25 | per email/hari | link + email | konfirmasi `FT-261020-DF3964` |
| smm8 | 100 | per koneksi/30 mnt | link; **order dibuat saat timer 0** | butuh workflow khusus |
| smmnut | 100 | per email/hari | akun + link + verify email | order #42408 "Order completed" |
| getlikes | 50 | per email/sekali | link + email + OTP | butuh domain @gmail yang bisa dibaca |

## 🔒 Perlu IP residential / proxy

| Service | Likes | Alasan |
|---|---|---|
| nicesmmpanel | 50 | API balas `"VPN / Proxy usage detected."` |
| fastsocial | 50 | token Turnstile nge-bind ke IP solve |
| skweezer | 100 | idem |
| mefreesocial | 15 | idem |
| famesathi | 25 | widget self-solve timeout di IP datacenter |
| smm8 (via runner) | 100 | kuota per koneksi |

> **Turnstile mem-bind token ke IP + User-Agent.** Wajib: *solve* dan *browse*
> lewat IP yang sama. Di GitHub-hosted runner IP-nya datacenter & berubah →
> ditolak. Solusi: `PROXY_URL` dipakai oleh browser (`run.py`) **dan** solver.

## ⛔ Dilewati otomatis (butuh login Instagram)

`smmpanelone`, `teaserid`, `ookfy` → `requires_ig_login` / `asks_ig_login()`
→ hasil `DILEWATI`.

## 🧪 Sudah dicek tapi GAGAL (jangan diulang)

| Service | Masalah |
|---|---|
| getlikes (via runner) | OTP dikirim ke @gmail → runner tak bisa baca (perlu IMAP/App Password) |
| socialfollowers | 404 di path lama → pakai `/free-instagram-tools` |
| feirasocial, take-top, socialz, buycheapfollower, gtrsocials, primelikes, followdeh | form JS / butuh akun |
| smmpanelnet, smmpanelking | submit tanpa konfirmasi (kemungkinan butuh akun) |
| buylikesservices, smmsumo | OTP tidak sampai ke mail.tm |
| tokboostly, socialkart | form JS / butuh akun |
| gtrsolutions, mybcf, botviewer | bukan halaman tool |
| azexo | SMTP rusak, email konfirmasi tak pernah sampai |
| poprey, likesforyou | backend ambil-post IG mati (proxy 407) |
| captchapi | saldo 0, top-up hanya crypto |

## 📋 Registry lengkap (46 service) & profil runner

Profil: `hosted` = aman dari IP datacenter (per-email), `self` = butuh IP rumah.

| Service | Likes | Limit | Flow | pool | kom | Profil |
|---|---|---|---|---|---|---|
| nicesmmpanel | 50 | post/week | nicesmmpanel (API) | | | self |
| profollowers | 50 | email/once | profollowers (API) | ✔ | ✔ | hosted |
| smmpaneladvisor | 100 | email/day | smmpaneladvisor | | | hosted |
| leofame | 30 | ip/day | generic | | | hosted |
| gurulikes | 10 | person/once | generic | ✔ | | hosted |
| quantaps | 5 | email/day | quantaps | | | hosted |
| sociotraffic | 15 | email/once | sociotraffic | | | hosted |
| fastsocial | 50 | post/once | generic | | | self |
| skweezer | 100 | ip/day | skweezer | | | self |
| famesathi | 25 | ip/day(5) | famesathi | | | self |
| smmnut | 100 | email/day | smmnut | | | hosted |
| getlikes | 50 | email/once | getlikes | | | self |
| mefreesocial | 15 | ip/6h | generic | | | self |
| smm8 | 100 | connection/30m | smm8 | | | self |
| grum | 100 | ip/hour(25) | grum | | ✔ | hosted + self |
| like4like | 100 | email/once | linkconfirm | | ✔ | hosted |
| zafame | 10 | email/day | otp | | ✔ | hosted |
| socialfollowers | 30 | ip/day | generic | | | hosted |
| feirasocial | 25 | email/day | generic | ✔ | | hosted |
| take-top | 10 | email/day | generic | | | hosted |
| tokboostly | 30 | email/day | generic | ✔ | | hosted |
| socialkart | 51 | email/day | generic | ✔ | | hosted |
| buyfans | 100 | email/day | generic | ✔ | | hosted |
| followersfly | 25 | email/day | generic | ✔ | ✔ | hosted |
| smmpanelone | 100 | connection/30m | generic | | | self |
| nlosmm | 50 | ip/7d | generic | | ✔ | hosted |
| teaserid | 50 | email/day | generic | ✔ | | self (DILEWATI) |
| iamprovider | 50 | manual/once | generic | | | self |
| primelikes | 100 | email/day | generic | | | hosted |
| gtrsocials | 50 | ip/day | generic | | | hosted |
| socialz | 100 | email/day | generic | ✔ | | hosted |
| buycheapfollower | 30 | email/day | generic | ✔ | | hosted |
| ookfy | 10 | email/day | generic | ✔ | | self (DILEWATI) |
| followdeh | 25 | email/day | generic | ✔ | | hosted |
| expressfollowers | 20 | email/day | generic | | ✔ | hosted |
| followerszeal | 25 | email/day | otp | | ✔ | hosted |
| techyhit | 50 | ip/day | generic | | | hosted |
| morethanpanel | 50 | ip/day | generic | | ✔ | hosted |
| smmpanelnet | 50 | ip/day | generic | | ✔ | hosted |
| smmpanelking | 50 | ip/day | generic | | ✔ | hosted |
| buylikesservices | 30 | email/day | otp | | | hosted |
| smmsumo | 50 | email/day | otp | | | hosted |
| hclout | 12 | ip/day | generic | | ✔ | hosted |
| swapcool | 30 | email/day | generic | ✔ | ✔ | hosted |
| getlike | 30 | email/day | otp | | ✔ | hosted |

Ringkasan: **46 service**, 14 flagged `community`, 14 pakai `email_pool`,
30 di profil hosted, 15 di profil self.

## 🔁 Rotasi & anti-limit

- `email_pool=True` → 10 alias `afaroyzi.1..9@gmail.com` per service/hari
  (Gmail mengabaikan titik → 1 inbox, 10 identitas).
- State cache harian: `state.json` = `{date, ok:[], failed:{nama:jumlah}}`;
  skip kalau jumlah kegagalan ≥ `MAX_FAILURES` (default 2). Error transient
  (timeout/captcha) dihitung 0 → masih dicoba di siklus berikutnya.
- Workflow menyimpan `state.json` lewat `actions/cache` (key per `run_id`,
  restore-keys `free-likes-state-`) → limit harian tidak terulang antar-run.

## 📌 Prioritas (urutan `rank()` di `run.py`)

1. `community: True` (like-for-like, akun nyata → paling tahan purge)
2. service yang sudah pernah sukses (`state["ok"]`)
3. service tanpa captcha (murah)
4. sisanya (captcha berat, paling akhir)

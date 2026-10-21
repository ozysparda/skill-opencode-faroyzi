# Mailbox: OTP, konfirmasi, alias email

Sumber (dicoba berurutan, `smmfree/mailbox.py`):

1. **tempmail.lol** (utama, tanpa akun) — `POST /v2/inbox/create` → `{address, token}`,
   baca `GET /v2/inbox?token=...`
2. **mail.tm** (fallback) — `POST /token` (akun), `GET /messages`, `GET /messages/{id}`
3. **Gmail IMAP** (fallback terakhir) — butuh `GMAIL_USER` + `GMAIL_APP_PASSWORD`

Fungsi unified yang dipakai flow:
- `wait_code_any(pattern, timeout, exclude, from_hint)` → kode OTP
- `wait_link_any(must_contain, timeout)` → link konfirmasi

Keduanya **mengurutkan email dari terbaru** dulu dan menyaring `from_hint`
(mis. `zafame`) supaya tidak salah ambil kode service lain yang tertinggal.
Modul `_SEEN` mencegah email yang sama dibaca dua kali.

## Domain yang terbukti bisa terima mail

| Domain | Sumber | Status |
|---|---|---|
| `maxxspace.com` | mail.tm | ✅ dipakai Zafame, soc-promotion |
| `lucktaro.com`, `paxeluni.com` | tempmail.lol | ✅ |
| `gmail.com` | milik sendiri | ✅ tapi runner tidak bisa baca tanpa App Password |

## Alias email = 10× klaim/hari per service

Gmail **mengabaikan titik** di local-part, jadi:

```
afaroyzi@gmail.com
afaroyzi.1@gmail.com   → masuk inbox yang sama
afaroyzi.2@gmail.com
...
afaroyzi.9@gmail.com
```

Service berbasis "1 trial per email" menghitung alamat berbeda → **10 klaim/hari**
dengan 1 inbox. Implementasi: `build_email_pool()` di `run.py`.

> Hanya untuk service yang email-nya cuma "kunci anti-abuse".
> Service yang **butuh OTP/konfirmasi email** TIDAK boleh pakai pool
> (kode dikirim ke alias itu, runner hanya bisa membaca 1 mailbox).

## Alias aman & yang ditolak

| Bentuk | Hasil |
|---|---|
| `afaroyzi.1@gmail.com` | ✅ DITERIMA (service menghitung berbeda) |
| `afaroyzi+1@gmail.com` | ❌ DITOLAK GetLikes (validasi domain ketat) |

## Forwarding Gmail → mail.tm (supaya OTP @gmail terbaca runner)

1. Gmail → Settings → Forwarding and POP/IMAP → *Tambahkan alamat penerusan*
2. Masukkan alamat mail.tm → *Berikutnya* → kode verifikasi dikirim ke mail.tm
   (baca via `mailtm_wait_code()` / `wait_code_any()`)
3. Masukkan kode → *Verifikasi* → **Simpan Perubahan**
4. Pilih "Teruskan salinan surat masuk kepada [alamat]" → **Simpan** → kode
   konfirmasi dikirim ke alamat tujuan → masukkan lagi.

## Gmail App Password (alternatif)

Google Account → Security → **2-Step Verification** → **App Passwords** → buat
16 karakter → simpan sebagai secret `GMAIL_APP_PASSWORD`.
Password utama **tidak bisa** dipakai (Google menolaknya di IMAP).

> Kendala yang pernah terjadi: pembuatan App Password berhenti di prompt
> "konfirmasi di perangkat" yang meminta menekan **"Ya"** + memasukkan nomor
> HP di iPhone 13 (nomor `0822353337915`). Tanpa itu, App Password tak bisa
> dibuat → layanan OTP @gmail (GetLikes, SMMNut, buylikesservices, smmsumo)
> tetap terkunci di runner.

## Pola OTP yang terlihat

| Pola | Contoh nyata |
|---|---|
| 6 digit | subject "**562853** is your Zafame sign-in code" |
| link konfirmasi | body berisi `https://panel/.../confirmation?token=...` |
| kode + referensi | ProFollowers `PF-015C1E0C`, `PF-9F13FAD1`, `PF-F88A35A6`, `PF-41B5EB2C`, `PF-F79232B4`, `PF-A59D919C`, `PF-261D556F`, `PF-3D382DB1` |
| id order | FollowersFly `FT-261020-DF3964`, SMMNut order `#42408` |

## Timeout

- OTP: **75 detik** (turunkan dari 120 → run jauh lebih cepat).
- Link konfirmasi: 10–18 detik.
- Polling interval: 4–6 detik.

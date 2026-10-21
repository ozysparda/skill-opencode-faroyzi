# Peta Kode (repo `ozysparda/gh-free-likes`)

Struktur berkas dan peran tiap bagian — supaya cepat paham saat perlu mengubah
sesuatu di PC lain.

```
gh-free-likes/
├─ run.py                     # runner utama (CLI)
├─ smmfree/
│  ├─ services.py             # registry 46 service + profil CI
│  ├─ engine.py               # flow Playwright + deteksi sukses strict
│  ├─ captcha.py              # chain provider captcha
│  ├─ mailbox.py              # OTP / link verifikasi
│  ├─ api.py                  # adapter pure-HTTP (tanpa browser)
│  └─ __init__.py
├─ .github/workflows/
│  ├─ free-likes-hosted.yml   # mesin utama (tiap jam)
│  ├─ free-likes-smm8.yml     # SMM8 nunggu timer (tiap 35 mnt)
│  └─ free-likes-selfhosted.yml # runner rumah (manual)
├─ setup-selfhosted.ps1       # daftarkan self-hosted runner
├─ setup-autostart.ps1        # auto-start runner saat laptop nyala
├─ hunt.py / probe2.py / probe5.py / probe_panels.py / hunt5.py
├─ candidates*.txt / tools_found*.json   # hasil pencarian kandidat tool
└─ requirements.txt           # playwright, requests
```

## `run.py`

| Bagian | Isi |
|---|---|
| `REPORT_PATH` / `STATE_PATH` | env `REPORT_FILE` (default `report.json`), `STATE_FILE` (default `state.json`) |
| `load_state()` | cache harian; `failed` = dict `{nama: jumlah}`; migrasi dari list lama |
| `save_state()` | tulis `state.json` (dipakai workflow untuk cache GH) |
| `build_email_pool()` | alias Gmail titik `.1..9` → 10 identitas, 1 inbox |
| `check_likes()` | baca jumlah like dari halaman publik (regex "Start the conversation") |
| `rank(s)` | urutan prioritas: komunitas → proven → tanpa captcha |
| `main()` | loop service: cek cache → jalankan flow → catat hasil → pacing → batas waktu |

Flag CLI: `--services`, `--profile {all,hosted,self,local}`, `--max-orders`,
`--pace`, `--service-budget`, `--retry-failed`, `--check-likes`, `--headful`,
`--only`.

Env yang dibaca: `IG_EMAIL`, `GMAIL_USER`, `PROXY_URL`, `MAX_ORDERS`,
`PACE_SEC`, `SERVICE_BUDGET`, `MAX_FAILURES`, `REPORT_FILE`, `STATE_FILE`.

## `smmfree/engine.py` (12 flow)

| Fungsi | Fungsi |
|---|---|
| `_set_value()` | set value via native setter (`HTMLInputElement.prototype.value`) + event |
| `_type_text()` | ketik karakter demi karakter (fallback anti-bot) |
| `_patch_captcha()` | override `turnstile.getResponse()` / `grecaptcha.getResponse()` |
| `_click_text()` | klik berdasarkan teks tombol (exact / nth) |
| `STRICT_SUCCESS` | 40+ pola konfirmasi sah (lihat `references/troubleshooting.md`) |
| `_strict_hit()` | cek pola strict + opsi wajib punya link |
| `asks_ig_login()` | deteksi halaman yang minta kredensial Instagram → DILEWATI |
| `_match_success()` / `_wait_success()` | pencocokan pola di body halaman |
| `_self_solve_token()` | tunggu token Turnstile/reCAPTCHA resolve sendiri (18 detik) |
| `_solve_if_needed()` | self-solve → chain provider API; patch ke halaman |
| `flow_generic` | isi form → submit → cek konfirmasi |
| `flow_otp` | submit → baca OTP → isi → submit lagi |
| `flow_linkconfirm` | submit → baca link konfirmasi → klik link |
| `flow_smmnut` | login panel (captcha) → order → verifikasi email |
| `flow_getlikes` | daftar akun → OTP → order |
| `flow_grum` | order + cek limit jam/cooldown |
| `flow_smm8` | order **ditempatkan saat timer 30 menit = 0** → tunggu (`timer_wait` 1950 dtk) |
| `flow_skweezer`, `flow_famesathi` | widget khusus + captcha |
| `flow_sociotraffic`, `flow_smpaneladvisor`, `flow_quantaps` | form khusus panel |
| `FLOWS` | peta `nama flow → fungsi` |

## `smmfree/captcha.py`

`PROVIDERS` = [solvercf, captchano, capsolver, anticaptcha, capmonster, 2captcha].
`solve()` mencoba berurutan; **skip CaptchaNo kalau saldo < $0.02**.
`balance()` → `GET https://api.captchano.com/v1/balance`.

## `smmfree/mailbox.py`

`TempMail` (tempmail.lol), `mailtm_*` (mail.tm), `gmail_wait_code()` (IMAP),
`wait_code_any()` / `wait_link_any()` (unified, newest-first + `from_hint`).

## `smmfree/api.py`

Adapter HTTP tanpa browser (cepat, 0 captcha):
- `nicesmmpanel()` → `POST https://test.socialfruit.co/api/gateway`
- `profollowers(email)` → `POST https://www.profollowers.uk/api/trials/`
  (balasan punya `reference`: `PF-xxxx`)

## `smmfree/services.py`

- `LINK` = `os.environ.get("IG_LINK", "<default>")` → link post (secret).
- `SERVICES` = list of dict (46 service).
- `CI_HOSTED` (30 nama) & `CI_SELF_ONLY` (15 nama) → service per-IP butuh
  IP rumah.
- `select(profile)` → filter sesuai profil.

Field tiap service: `name`, `url`, `likes`, `limit`, `flow`, `captcha`
(`{"type","sitekey"}` atau None), `fields` (`sel` + `value` `$LINK`/`$EMAIL`),
`submit` (`texts`), `community`, `email_pool`, `requires_ig_login`, `api`.

## Deklarasi service baru (templat)

```python
{
    "name": "contoh",
    "url": "https://contoh.com/free-instagram-likes",
    "likes": 50,
    "limit": "email/day",
    "flow": "generic",
    "captcha": None,                 # atau {"type":"turnstile","sitekey":"0x..."}
    "fields": [
        {"sel": "#url", "value": "$LINK"},
        {"sel": 'input[name="email"]', "value": "$EMAIL"},
    ],
    "submit": {"texts": ["Get Free Likes", "Submit", "Order"]},
    "community": False,
    "email_pool": True,              # HANYA kalau tidak butuh OTP
}
```

Setelah menambah service: `python -c "import smmfree.services"` untuk cek
syntax, commit, push, lalu trigger workflow.

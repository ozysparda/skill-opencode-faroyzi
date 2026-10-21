# Captcha: provider, bypass, budgeting

## Chain provider (`smmfree/captcha.py` → `PROVIDERS`)

| # | Provider | Env key | Free credit | Dukungan |
|---|---|---|---|---|
| 1 | **SolverCF** | `SOLVERCF_KEY` | **$0.90** (~750–1500 solve) | Turnstile, reCAPTCHA **v3** |
| 2 | CaptchaNo | `CAPTCHA_NO_KEY` | $0.30 (~105 solve) | reCAPTCHA **v2** + Turnstile |
| 3 | Capsolver | `CAPSOLVER_KEY` | trial | reCAPTCHA v2/v3, Turnstile, DataDome |
| 4 | Anti-Captcha | `ANTICAPTCHA_KEY` | trial | Enterprise + custom screens |
| 5 | CapMonster | `CAPMONSTER_KEY` | test balance | volume tinggi |
| 6 | 2Captcha | `TWOCAPTCHA_KEY` | – | image captcha |

### Format SolverCF (anti-captcha compatible)

```jsonc
// POST https://solvercf.com/token/extension/createTask
{ "clientKey": "KEY",
  "task": { "type": "TurnstileTask", "websiteUrl": "...", "websiteKey": "0x..." } }
// POST https://solvercf.com/token/extension/getTaskResult
{ "clientKey": "...", "taskId": "..." }
// -> { "status": "ready", "solution": { "token": "..." } }
```

Tipe: `TurnstileTask` (Turnstile), `RecaptchaV3TaskProxyless` (reCAPTCHA v3).
⚠️ reCAPTCHA **v2 tidak didukung** SolverCF → jatoh ke CaptchaNo (hemat, pakai
seperlunya).

### Format CaptchaNo

```jsonc
// POST https://api.captchano.com/v1/solve?wait=20
{ "type": "turnstile|recaptcha_v2", "sitekey": "...", "url": "...", "action": "..." }
// header: Authorization: Bearer <key>
// polling: GET https://api.captchano.com/v1/task/<id>
```

## Teknik bypass (hasil eksperimen)

1. **Self-solve DULUAN (gratis)** — Turnstile di browser asli sering resolve
   sendiri. Tunggu token muncul di `input[name=cf-turnstile-response]`.
   Timeout default 18 detik.
2. **Override `getResponse()`** (`_patch_captcha` di `engine.py`):

```js
// Turnstile
const o = window.turnstile.getResponse.bind(window.turnstile);
window.turnstile.getResponse = (w) => o(w) || TOKEN;
// reCAPTCHA (v2/v3)
const o = window.grecaptcha.getResponse.bind(window.grecaptcha);
window.grecaptcha.getResponse = (w) => o(w) || TOKEN;
```

3. Isi hidden input token + dispatch `input`/`change`.
4. **Token Turnstile terikat IP + User-Agent** → solve & browse HARUS lewat IP
   yang sama:
   - browser lokal (IP rumah) → selalu jalan,
   - GitHub-hosted runner (IP datacenter, berubah-ubah) → sering ditolak
     (`solved:solvercf` tapi tanpa konfirmasi),
   - solusi: `PROXY_URL` dipakai **browser + solver** lewat IP sama.

## Budgeting

```bash
# cek saldo CaptchaNo
python -c "import requests;print(requests.get('https://api.captchano.com/v1/balance',headers={'Authorization':'Bearer '+KEY}).json())"
```

- `captcha.solve()` **skip** CaptchaNo kalau saldo < $0.02 (hemat sisa kredit).
- Harga perkiraan: Turnstile ~$0.0044, reCAPTCHA v2 ~$0.0029.
- SolverCF $0.90 ≈ 750–1500 solve (pakai untuk Turnstile, Jangan untuk v2).

## Kalau credits habis

1. **SolverCF trial**: daftar ulang (email/akun Google lain) → $0.90 baru.
2. **CaptchaNo**: signup ulang → $0.30 (pakai email lain).
3. **Self-solve** di prioritaskan → hampir gratis.
4. **Anti-Captcha / CapMonster**: minta test balance ke support.
5. Stop order ber-captcha & andalkan 14 service komunitas tanpa captcha.

## Rekomendasi: self-hosted runner

IP rumah = residential = token Turnstile valid + kuota per-IP milik sendiri.

```powershell
# Settings > Actions > Runners > New self-hosted runner (Windows, x64)
.\setup-selfhosted.ps1      # daftarkan runner
.\setup-autostart.ps1       # auto-start saat laptop nyala + restart tiap 3 jam
```

Runner yang terpasang: `laptop-faroyzii` (Windows, label `self-hosted, windows`).

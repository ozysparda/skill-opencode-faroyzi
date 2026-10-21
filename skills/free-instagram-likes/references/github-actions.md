# GitHub Actions: setup, secrets, runner, kuota

## 0. Repo

- Repo kode: **`ozysparda/gh-free-likes`** — **PUBLIC** (wajib, biar minutes
  unlimited).
- Repo skill+memory: **`ozysparda/skill-opencode-faroyzi`** — katalog skill,
  dipakai `bootstrap.ps1` di PC baru.

> Kenapa harus public: repo private ⇒ kuota **2.000 menit/bulan** untuk
> GitHub-hosted runner. Satu run ≈ 7 menit (sebelum optimasi 20 menit) ⇒ kuota
> habis dalam ~2 hari dan jadwal mati. Repo public ⇒ minutes unlimited.

## 1. Workflow

### `free-likes-hosted.yml` — mesin utama
- Jadwal: `7 * * * *` (tiap jam, menit 07).
- `--profile hosted`, `MAX_ORDERS` 6–10, `PACE_SEC` 30–60.
- Cache state: `actions/cache@v4` dengan key `free-likes-state-${{ github.run_id }}`
  dan `restore-keys: free-likes-state-` → `state.json` bertahan antar-run.
- `concurrency: free-likes-hosted`, `cancel-in-progress: false`.
- Upload artifact `report-${{ github.run_id }}` (retensi 7 hari).
- Step Summary berisi tabel hasil per service.

### `free-likes-smm8.yml` — SMM8 (order dibuat saat timer 0)
- Jadwal: `*/35 * * * *`, `timeout-minutes: 50`.
- `python run.py --profile all --services smm8 --max-orders 1 --pace 5 --service-budget 2400`
- PENTING: harus tetap **menunggu timer 30 menit**; kalau timeout terlalu kecil,
  order belum ditempatkan.

### `free-likes-selfhosted.yml` — IP rumah
- `runs-on: [self-hosted, windows]`, pakai **python sistem** (`shell: cmd`),
  bukan `setup-python` (runner Windows tidak punya setup tool bawaan).
- Jadwal **dimatikan** (di-comment): kalau laptop mati, run-nya cuma numpuk
  `queued`. Trigger manual saja.

## 2. Secrets

```bash
gh secret set CAPTCHA_NO_KEY  --repo ozysparda/gh-free-likes
gh secret set SOLVERCF_KEY    --repo ozysparda/gh-free-likes
gh secret set MAILTM_ADDR     --repo ozysparda/gh-free-likes
gh secret set MAILTM_PASSWORD --repo ozysparda/gh-free-likes
gh secret set IG_EMAIL        --repo ozysparda/gh-free-likes
gh secret set IG_LINK         --repo ozysparda/gh-free-likes
# opsional:
gh secret set GMAIL_APP_PASSWORD --repo ozysparda/gh-free-likes
gh secret set PROXY_URL          --repo ozysparda/gh-free-likes
```

`IG_LINK` dipakai supaya **repo public tidak memuat data pribadi** — link post
disimpan sebagai secret, default di `smmfree/services.py` (`LINK`).

Sudah terpasang (per 2026-10-21): `CAPTCHA_NO_KEY`, `SOLVERCF_KEY`,
`MAILTM_ADDR`, `MAILTM_PASSWORD`, `GMAIL_USER`, `IG_EMAIL`, `IG_LINK`.
Belum: `GMAIL_APP_PASSWORD`, `PROXY_URL`.

## 3. Self-hosted runner (Windows)

```powershell
# 1) Settings > Actions > Runners > New self-hosted runner (Windows, x64)
# 2) unduh & jalankan config.cmd
# 3) daftarkan repo: setup-selfhosted.ps1
# 4) auto-start: setup-autostart.ps1
```

`setup-autostart.ps1` membuat 3 lapis belt-and-suspenders:
1. Shortcut di folder **Startup**,
2. entri `HKCU\...\Run`,
3. **Scheduled Task** yang me-restart runner tiap 3 jam.

Runner aktif: `laptop-faroyzii` (label `self-hosted, windows`).

## 4. Workflow "scheduled" kadang tidak jalan

Gejala: gap beberapa jam tanpa run sama sekali, padahal cron tiap jam.
Penyebab yang pernah terjadi:

- **GitHub menunda scheduled workflow** saat beban tinggi (terlihat: run 04:48
  lalu 11:39, padahal cron `7 * * * *`).
- Workflow baru dibuat/berubah → jadwal di-reset, run pertama bisa telat.
- File workflow tidak ada di **default branch**.

Mitigasi yang dipakai:
- trigger manual: `gh workflow run free-likes-hosted.yml --repo ... -f max_orders=10`
- tambah beberapa cron (mis. `7,37 * * * *`) supaya peluang jalan lebih besar,
- `workflow_dispatch` + `repository_dispatch` sebagai pintu masuk eksternal
  (cron-job.org / UptimeRobot bisa menembak `repository_dispatch`).

## 5. Membaca hasil run

```bash
gh run list --repo ozysparda/gh-free-likes --limit 5
gh run download <id> --repo ozysparda/gh-free-likes --dir .\art
# report.json: {"summary":{"ok":n,"fail":n,"likes_claimed":n},"results":[...]}
```

Atau pakai `scripts/verify-run.ps1` (skill ini) yang langsung mencetak tabel.

## 6. Kalau kuota menit habis (repo sempat private)

- Steps: `--max-orders 4`, `--pace 30`, cron `7 */6 * * *`, matikan workflow SMM8.
- SMM8 saja menghabiskan ~35 menit per run → paling boros.

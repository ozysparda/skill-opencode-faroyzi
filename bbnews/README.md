# Bundle: BBNEWS + GitHub Terminal

Subfolder ini adalah **unit kerja mandiri**: skill + memory + skrip install
untuk_task BerugakNews (BBNEWS) dan alur commit GitHub via terminal.

Dipisahkan dari subfolder lain di repo `skill-opencode-faroyzi` supaya dua
sesi OpenCode yang bekerja bersamaan tidak saling menimpa berkas.

## Isi folder ini

```text
bbnews/
├── README.md                  <- berkas ini
├── MEMORY.md                  <- indeks pengetahuan + aturan emas
├── install.ps1 / install.sh   <- pasang skill ke ~/.config/opencode/skills
├── bootstrap.ps1 / .sh        <- setup 1 perintah untuk PC baru
├── docs/memory/01..06         <- dokumentasi lengkap
└── skills/
    ├── bbnews-deploy/         <- skill: deploy & rawat BerugakNews
    └── github-commit-terminal/<- skill: commit/push GitHub via terminal
```

## Skill

| Skill ID | Untuk apa |
| --- | --- |
| `bbnews-deploy` | Edit kode BBNEWS, commit/push, promote preview ke production, verifikasi upload gambar & data artikel |
| `github-commit-terminal` | Commit/push tanpa editor web GitHub, setup token, verifikasi byte, recovery |

## Memory

| Berkas | Isi |
| --- | --- |
| `MEMORY.md` | Indeks pengetahuan + aturan emas |
| `docs/memory/01-proyek-bbnews.md` | Fakta proyek: GitHub, Vercel, Blob, admin, alur upload |
| `docs/memory/02-insiden-dan-solusi.md` | Semua insiden nyata + penyebab + perbaikan (pesan error asli) |
| `docs/memory/03-alur-kerja-terminal.md` | Alur end-to-end: clone, edit, commit, push, promote, verifikasi, rollback |
| `docs/memory/04-trik-browser-tools.md` | Trik tool browser + jebakan (CodeMirror, CORS, base64, PowerShell) |
| `docs/memory/05-token-dan-kredensial.md` | Token Vercel/GitHub, lokasi simpan, pembuatan, rotasi, risiko |
| `docs/memory/06-qa-dan-baseline.md` | Checklist QA, angka baseline, cara memastikan data aman |

## Pasang di PC ini

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

## Setup PC baru (1 perintah)

```powershell
git clone https://github.com/ozysparda/skill-opencode-faroyzi.git
cd skill-opencode-faroyzi
powershell -ExecutionPolicy Bypass -File .\bbnews\bootstrap.ps1
```

`bootstrap.ps1` melakukan:

1. Memastikan Git terpasang (opsional pasang via winget).
2. Menginstal skill `bbnews-deploy` + `github-commit-terminal` ke
   `~/.config/opencode/skills/`.
3. Memasang blok memory ke `~/.config/opencode/AGENTS.md` (ditandai marker
   `BEGIN/END: skill-opencode-faroyzi`, jadi aman coexist dengan bundle lain).
4. Clone/update repo kerja BBNEWS ke `<sibling>/bbnews-git` (branch `vercel`).
5. Menyiapkan credential git bila file token GitHub tersedia.

Opsi: `-SkipGitInstall`, `-SkipClone`, `-SkipMemory`, `-TokenFile <path>`.

## Yang tidak boleh masuk repo

Token, password, `.env` - semuanya ditolak `.gitignore`. Simpan di luar repo,
mis. `%TEMP%\opencode\github-token.txt` dan `%TEMP%\opencode\vercel-token.txt`.

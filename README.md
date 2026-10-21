# Skill OpenCode — Faroyzi

Kumpulan **skill OpenCode** pribadi + **memory** kerja. Semuanya bisa dibawa ke
PC mana pun: clone repo ini, jalankan `bootstrap`, skill dan memory ikut
terpasang.

Repo ini adalah katalog tunggal — tinggal tambah folder baru di `skills/`,
OpenCode menemukannya otomatis setelah di-install.

## Isi

### Skill

| Skill ID | Nama | Untuk apa |
| --- | --- | --- |
| `bbnews-deploy` | Deploy BerugakNews (BBNEWS) | Edit kode, commit/push, promote preview ke production, verifikasi upload gambar & data artikel |
| `github-commit-terminal` | Commit GitHub via Terminal | Commit/push tanpa editor web GitHub, setup token, verifikasi hasil commit, recovery |
| `free-instagram-likes` | Free Instagram Likes Automation | Otomasi klaim free IG likes (repo `ozysparda/gh-free-likes`) |
| `free-instagram-likes` | Free Instagram Likes Automation | Klaim free IG likes dari 46 SMM panel (tanpa password IG), captcha multi-provider, temp-mail OTP, jadwal penuh di GitHub Actions |

### Memory (dokumentasi lengkap)

| Berkas | Isi |
| --- | --- |
| `MEMORY.md` | Indeks seluruh pengetahuan + aturan emas |
| `docs/memory/01-proyek-bbnews.md` | Fakta proyek: GitHub, Vercel, Blob, admin, struktur kode, alur upload |
| `docs/memory/02-insiden-dan-solusi.md` | Semua error nyata + penyebab + perbaikan (dengan pesan error asli) |
| `docs/memory/03-alur-kerja-terminal.md` | Alur end-to-end: clone, edit, commit, push, promote, verifikasi, rollback |
| `docs/memory/04-trik-browser-tools.md` | Trik tool browser OpenCode + jebakan (CodeMirror, CORS, base64, PowerShell) |
| `docs/memory/05-token-dan-kredensial.md` | Token Vercel/GitHub, lokasi simpan, pembuatan, rotasi, risiko |
| `docs/memory/06-qa-dan-baseline.md` | Checklist QA, angka baseline, cara memastikan data tidak rusak |
| `docs/memory/07-ig-likes-automation.md` | Automation free IG likes: arsitektur GH Actions, registry service, keputusan & alasan, peta error, trik anti-bot |
| `docs/memory/08-kredensial-ig-likes.local.md` | *(lokal, tidak di-commit)* kredensial panel SMM, API key captcha, mail.tm |

## Cara pakai di PC lain (1 perintah)

```bash
git clone https://github.com/ozysparda/skill-opencode-faroyzi.git
cd skill-opencode-faroyzi
```

**Windows (PowerShell)**

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

**macOS / Linux**

```bash
chmod +x bootstrap.sh install.sh
./bootstrap.sh
```

`bootstrap` akan:

1. Memastikan Git terpasang (bisa otomatis via winget).
2. Menginstal semua skill ke `~/.config/opencode/skills/`.
3. Memasang memory global di `~/.config/opencode/AGENTS.md` (dibuat/di-update
   otomatis, aman dijalankan berulang).
4. Clone/update repo kerja BBNEWS ke `<sibling>/bbnews-git` (branch `vercel`).
5. Menyiapkan credential git bila file token GitHub tersedia.

Opsi yang berguna:

```powershell
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -SkipGitInstall -SkipClone
powershell -ExecutionPolicy Bypass -File .\bootstrap.ps1 -TokenFile D:\secure\github-token.txt
```

Tanpa `bootstrap`, cukup jalankan `install.ps1` (Windows) atau `install.sh`
(macOS/Linux) untuk memasang skill saja.

### Yang TIDAK dibawa

Token & password **tidak** ada di repo ini (`.gitignore` juga menolak file
token). Untuk PC baru:

1. Buat GitHub PAT: <https://github.com/settings/tokens/new> — scope `repo`,
   *No expiration*.
2. Buat Vercel token: Vercel Dashboard > Settings > Tokens > Create Token,
   scope *Full Account*, *No expiration*.
3. Simpan di luar repo, mis. `%TEMP%\opencode\github-token.txt` dan
   `%TEMP%\opencode\vercel-token.txt`.
4. Jalankan `bootstrap.ps1 -TokenFile <path>`.

## Cara install skill saja

| Scope | Lokasi |
| --- | --- |
| Global | `~/.config/opencode/skills/` |
| Project | `.opencode/skills/` (dari folder kerja sampai root proyek) |

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1     # Windows
./install.sh                                               # macOS/Linux
```

Folder yang sudah ada ditimpa. Jalankan ulang setiap kali isi skill berubah.
Cek hasilnya: buka sesi OpenCode baru, skill muncul di daftar skill yang
tersedia, atau dipanggil manual dengan `@bbnews-deploy`.

## Menambah skill baru

```text
skills/
└── nama-skill/              <- ID skill = nama folder (kebab-case)
    ├── SKILL.md             <- wajib, nama file harus persis SKILL.md
    ├── references/          <- dokumen pendukung, dibaca saat perlu
    └── scripts/             <- skrip yang bisa dijalankan agen
```

Aturan penting:

- Nama folder = **ID skill**: huruf kecil, angka, tanda hubung
  (`^[a-z0-9]+(-[a-z0-9]+)*$`).
- `SKILL.md` wajib punya frontmatter:

  ```markdown
  ---
  name: Nama Tampilan
  description: Satu kalimat kapan skill ini dipakai.
  ---
  ```

- `description` menjelaskan **kondisi pemakaian**, bukan cuma isi — itu yang
  dibaca agen untuk memutuskan memanggil skill atau tidak.
- Sembunyikan skill dari daftar otomatis dengan `metadata:` ->
  `opencode/autoinvoke: false`.
- Path di dalam skill relatif terhadap folder skill tersebut.
- Jangan taruh token/password di repo ini. Rujuk ke file di luar repo
  (mis. `%TEMP%\opencode\github-token.txt`) atau variabel lingkungan.

## Prinsip kerja yang dipegang

1. Jangan pernah menaruh token/password/`.env` di dalam repo.
2. Data artikel adalah aset utama — setelah deploy, selalu cek jumlah artikel
   (baseline: 3 artikel = 2 terbit + 1 draft, 142 views).
3. Editor web GitHub bukan alat utama — selalu terminal (`git commit` + `push`).
4. Jangan mengirim base64 panjang di dalam panggilan tool — ambil dari URL
   atau kirim byte apa adanya.
5. Verifikasi byte-per-byte setelah commit, bukan hanya "commit sukses".

## Referensi

- Dokumentasi skill OpenCode V2: <https://opencode.ai/v2/docs/skills/>
- Dokumentasi instructions (`AGENTS.md`): <https://opencode.ai/v2/docs/instructions/>

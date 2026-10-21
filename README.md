# Skill OpenCode — Faroyzi

Katalog **skill OpenCode** + **memory** kerja. Repo ini berisi beberapa
*bundle*, masing-masing di subfolder sendiri supaya beberapa sesi OpenCode bisa
bekerja bersamaan tanpa saling menimpa berkas.

| Bundle | Isi | Lokasi |
| --- | --- | --- |
| `bbnews/` | Skill deploy BerugakNews (BBNEWS) + commit GitHub via terminal, memory 01-06 | subfolder `bbnews/` repo ini |
| free IG likes | Otomasi free Instagram likes | repo `ozysparda/skill-free-instagram-likes` |

## Struktur

```text
skill-opencode-faroyzi/
├── bbnews/                  <- bundle BBNEWS (skill + memory + install/bootstrap)
│   ├── README.md
│   ├── MEMORY.md
│   ├── install.ps1 / install.sh
│   ├── bootstrap.ps1 / bootstrap.sh
│   ├── docs/memory/01..06
│   └── skills/bbnews-deploy/, skills/github-commit-terminal/
├── README.md                <- katalog (berkas ini)
├── MEMORY.md                <- indeks katalog
└── .gitignore
```

Aturan: **satu bundle = satu subfolder**. Skill & memory tidak pernah
diletakkan langsung di root, supaya sesi lain bebas menambah bundle-nya
tanpa bentrok.

## Bundle `bbnews/`

Detail lengkap + cara pakai: **[`bbnews/README.md`](bbnews/README.md)**.

| Skill ID | Nama | Untuk apa |
| --- | --- | --- |
| `bbnews-deploy` | Deploy BerugakNews (BBNEWS) | Edit kode, commit/push, promote preview ke production, verifikasi upload gambar & data artikel |
| `github-commit-terminal` | Commit GitHub via Terminal | Commit/push tanpa editor web GitHub, setup token, verifikasi hasil commit, recovery |

| Memory | Isi |
| --- | --- |
| [`bbnews/MEMORY.md`](bbnews/MEMORY.md) | Indeks pengetahuan + aturan emas |
| [`bbnews/docs/memory/01-proyek-bbnews.md`](bbnews/docs/memory/01-proyek-bbnews.md) | Fakta proyek: GitHub, Vercel, Blob, admin, struktur kode, alur upload |
| [`bbnews/docs/memory/02-insiden-dan-solusi.md`](bbnews/docs/memory/02-insiden-dan-solusi.md) | Semua error nyata + penyebab + perbaikan (pesan error asli) |
| [`bbnews/docs/memory/03-alur-kerja-terminal.md`](bbnews/docs/memory/03-alur-kerja-terminal.md) | Alur end-to-end: clone, edit, commit, push, promote, verifikasi, rollback |
| [`bbnews/docs/memory/04-trik-browser-tools.md`](bbnews/docs/memory/04-trik-browser-tools.md) | Trik tool browser OpenCode + jebakan (CodeMirror, CORS, base64, PowerShell) |
| [`bbnews/docs/memory/05-token-dan-kredensial.md`](bbnews/docs/memory/05-token-dan-kredensial.md) | Token Vercel/GitHub, lokasi simpan, pembuatan, rotasi, risiko |
| [`bbnews/docs/memory/06-qa-dan-baseline.md`](bbnews/docs/memory/06-qa-dan-baseline.md) | Checklist QA, angka baseline, cara memastikan data tidak rusak |
| [`bbnews/docs/memory/07-skill-opencode-dan-audit.md`](bbnews/docs/memory/07-skill-opencode-dan-audit.md) | Standar skill OpenCode (discovery, presedensi, format) + hasil audit semua skill & perbaikannya |

### Setup PC baru (1 perintah)

```powershell
git clone https://github.com/ozysparda/skill-opencode-faroyzi.git
cd skill-opencode-faroyzi
powershell -ExecutionPolicy Bypass -File .\bbnews\bootstrap.ps1
```

`bbnews\bootstrap.ps1` akan: memastikan Git terpasang, memasang skill ke
`~/.config/opencode/skills/`, memasang blok memory ke `~/.config/opencode/AGENTS.md`
(marker `BEGIN/END: skill-opencode-faroyzi`, jadi aman berdampingan dengan
bundle lain), clone repo kerja BBNEWS, dan menyiapkan credential git.

macOS/Linux: `./bbnews/bootstrap.sh`

### Yang TIDAK dibawa

Token & password **tidak** ada di repo ini (`.gitignore` juga menolak file
token dan `*.local.md`). Untuk PC baru:

1. Buat GitHub PAT: <https://github.com/settings/tokens/new> — scope `repo`,
   *No expiration*.
2. Buat Vercel token: Vercel Dashboard > Settings > Tokens > Create Token,
   scope *Full Account*, *No expiration*.
3. Simpan di luar repo, mis. `%TEMP%\opencode\github-token.txt` dan
   `%TEMP%\opencode\vercel-token.txt`.
4. Jalankan `bbnews\bootstrap.ps1 -TokenFile <path>`.

## Cara install skill saja

| Scope | Lokasi |
| --- | --- |
| Global | `~/.config/opencode/skills/` |
| Project | `.opencode/skills/` (dari folder kerja sampai root proyek) |

```powershell
powershell -ExecutionPolicy Bypass -File .\bbnews\install.ps1   # Windows
./bbnews/install.sh                                            # macOS/Linux
```

Folder yang sudah ada ditimpa. Jalankan ulang setiap kali isi skill berubah.
Cek hasilnya: buka sesi OpenCode baru, skill muncul di daftar skill yang
tersedia, atau dipanggil manual dengan `@bbnews-deploy`.

## Menambah bundle / skill baru

```text
<nama-bundle>/
├── README.md                <- penjelasan bundle
├── MEMORY.md                <- indeks pengetahuan bundle
├── install.ps1 / install.sh
├── bootstrap.ps1 / bootstrap.sh
├── docs/memory/..           <- dokumentasi
└── skills/
    └── nama-skill/          <- ID skill = nama folder (kebab-case)
        ├── SKILL.md         <- wajib, nama file harus persis SKILL.md
        ├── references/      <- dokumen pendukung, dibaca saat perlu
        └── scripts/         <- skrip yang bisa dijalankan agen
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
  dibaca agen untuk Decide memanggil skill atau tidak.
- Sembunyikan skill dari daftar otomatis dengan `metadata:` ->
  `opencode/autoinvoke: false`.
- Path di dalam skill relatif terhadap folder skill tersebut.
- Blok memory di `AGENTS.md` pakai marker `BEGIN/END: <nama-bundle>` supaya
  tiap bundle bisa memasang/memperbarui bagiannya sendiri tanpa menimpa
  bundle lain.
- Jangan taruh token/password di repo ini. Rujuk ke file di luar repo
  (mis. `%TEMP%\opencode\github-token.txt`) atau variabel lingkungan.

## Prinsip kerja yang dipegang

1. Jangan pernah menaruh token/password/`.env` di dalam repo.
2. Data artikel adalah aset utama — setelah deploy, selalu cek jumlah artikel
   (baseline terbaru: 3 artikel = 3 terbit + 0 draft; views naik sesuai traffic).
3. Editor web GitHub bukan alat utama — selalu terminal (`git commit` + `push`).
4. Jangan mengirim base64 panjang di dalam panggilan tool — ambil dari URL
   atau kirim byte apa adanya.
5. Verifikasi byte-per-byte setelah commit, bukan hanya "commit sukses"
   (normalisasi CRLF/LF saat membandingkan di Windows).
6. Skill OpenCode dibaca dari `SKILL.md` saja; `skills` di config = array path;
   presedensi project > global; file `.ps1` untuk PS 5.1 = UTF-8 + BOM.
7. Cek `visibility` repo sebelum push — repo yang pernah public masih menyimpan
   kredensial lama di riwayat git.

## Referensi

- Dokumentasi skill OpenCode V2: <https://opencode.ai/v2/docs/skills/>
- Dokumentasi instructions (`AGENTS.md`): <https://opencode.ai/v2/docs/instructions/>

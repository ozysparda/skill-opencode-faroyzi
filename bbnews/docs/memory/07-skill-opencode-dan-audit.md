# 07 — Standar Skill OpenCode & Hasil Audit Semua Skill

Dokumen ini menjawab dua pertanyaan yang selalu muncul:
1. **Bagaimana cara OpenCode menemukan & memilih skill** (aturan resminya).
2. **Audit lengkap semua skill** — mana yang aktif, mana yang rusak, mana yang
   membayangi (shadow) skill lain.

Semua fakta di sini diverifikasi terhadap
<https://opencode.ai/v2/docs/skills/> (di-fetch 21 Okt 2026) dan terhadap
keadaan nyata di PC ini.

---

## 1. Cara OpenCode menemukan skill (aturan resmi V2)

### Lokasi penemuan (source root)

| Scope | Sumber |
| --- | --- |
| Global | `~/.config/opencode/skills` |
| Global compat | `~/.claude/skills`, `~/.agents/skills` |
| Project | `.opencode/skills` |
| Project compat | `.claude/skills`, `.agents/skills` |

Untuk sumber project, OpenCode mencari dari direktori kerja **ke atas sampai
project root** dan menyertakan folder yang cocok di setiap level.

### Bentuk yang dikenali

```text
skills/
├── review.md              <- skill flat (ID = "review")
└── git-release/
    └── SKILL.md           <- skill direktori (ID = "git-release")
```

- Skill flat: file `*.md` **harus ada langsung di root source**.
- Skill direktori: file **harus bernama persis `SKILL.md`**, boleh nested
  (`skills/teams/release/SKILL.md` → ID `release`).
- Satu direktori yang berisi `SKILL.md` = satu skill. OpenCode **tidak**
  mencari skill di dalamnya.
- File/folder tersembunyi dan `node_modules` dilewati.
- Pencarian berhenti 6 direktori di bawah source root.

> **Penting:** format `skill.json` **TIDAK** dikenali OpenCode. Hanya
> `SKILL.md` (atau `*.md` flat). Ringkasan: file `skill.json` = 0 skill
> terdeteksi.

### Menambah sumber lain (`skills` di config)

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "skills": [
    "./skills",
    "~/shared/opencode-skills",
    "/opt/company-skills",
    "https://example.com/opencode/skills/"
  ]
}
```

| Nilai | Resolusi |
| --- | --- |
| Path relatif | Dari **direktori kerja aktif**, bukan dari lokasi file config |
| `~/` | Dari home user |
| Path absolut | Dipakai apa adanya |
| `http(s)://` | Dimuat sebagai HTTP catalog |

Semua file config yang ditemukan **menggabungkan** array `skills`, bukan
menggantikan. **Nilai WAJIB berupa array**, bukan object
`{"nama": "./path"}` — bentuk object diabaikan diam-diam (tanpa error).

### Presedensi (paling penting!)

Skill dipilih berdasarkan **ID**. Kalau dua sumber punya ID sama, **sumber yang
terdaftar belakangan** yang dimuat:

```text
~/.config/opencode/skills/git-release/SKILL.md   <- presedensi lebih rendah
.opencode/skills/git-release/SKILL.md             <- yang dimuat
```

Urutan pendaftaran (dari rendah ke tinggi):

1. Built-in skills
2. `.claude/skills` (global dulu, lalu dari ancestor terjauh ke direktori kerja)
3. `.agents/skills` (global dulu, lalu dari ancestor terjauh ke direktori kerja)
4. `~/.config/opencode/skills`
5. Project `.opencode/skills` (dari project root ke direktori kerja)
6. Entri `skills` eksplisit di config (urutan prioritas & urutan array)

> **Jebakan yang sudah menimpa kita:** versi skill di `.opencode/skills`
> (project) **mengalahkan** versi global, meskipun versinya lebih lama. Perilaku
> agent mengikuti versi yang menang, bukan versi terbaru.

### Frontmatter

```yaml
---
name: Git Release          # hanya label tampilan, ID tetap dari path
description: ...           # ringkasan yang dilihat model
metadata:
  opencode/autoinvoke: false   # sembunyikan dari daftar otomatis
---
```

- Semua field opsional saat runtime, tapi **tanpa `description` skill tidak
  pernah diiklankan** ke model → model tidak akan memanggilnya.
- `disable-model-invocation: true` punya efek sama.
- Kalau keduanya diisi, `opencode/autoinvoke` yang menang.
- V2 menerima field portabel (`license`, `compatibility`) tapi tidak
  mengartikannya.

### ID

| File | ID |
| --- | --- |
| `<source>/git-release.md` | `git-release` |
| `<source>/git-release/SKILL.md` | `git-release` |
| `<source>/teams/release/SKILL.md` | `release` |

ID bersifat **case-sensitive**. Untuk skill portabel: ID unik, kebab-case
lowercase, 1–64 karakter, sepreferably sama dengan nama folder
(`^[a-z0-9]+(-[a-z0-9]+)*$`). V2 belum menegakkan pola ini.

### Cara memanggil

- Model memanggil lewat tool `skill` dengan **ID persis** (bukan `name`).
- Manusia memanggil dengan `@skill-id` di prompt.
- Isi `references/` & `scripts/` **tidak** dimuat otomatis; agen membacanya
  saat SKILL.md menyuruh.

### Permissions (opsional)

```jsonc
{ "permissions": [
  { "action": "skill", "resource": "*", "effect": "allow" },
  { "action": "skill", "resource": "internal-*", "effect": "deny" }
]}
```

Efek: `allow` (tayang), `ask` (tanya), `deny` (sembunyi + tolak muat).
Aturan:last matching rule wins. Bisa dibatasi per agent lewat
`agents.<id>.permissions`.

---

## 2. Hasil audit semua skill (21 Okt 2026, 20:20)

### Skill yang aktif & valid (terpasang di `~/.config/opencode/skills/`)

| ID | Sumber kebenaran | SKILL.md | File pendukung | Status |
| --- | --- | --- | --- | --- |
| `bbnews-deploy` | `skill-opencode-faroyzi/bbnews/skills/` | ✅ | 5 | aktif, sinkron |
| `github-commit-terminal` | `skill-opencode-faroyzi/bbnews/skills/` | ✅ | 2 | aktif, sinkron |
| `free-instagram-likes` | `skill-free-instagram-likes/skills/` | ✅ | 14 | aktif, sinkron |
| `cek-desil-dtsen` | `_skill-pip-desil/PORTABLE/skills/` | ✅ | 4 | aktif, sinkron |
| `format-usulan-pip` | `_skill-pip-desil/PORTABLE/skills/` | ✅ | 9 | aktif, sinkron |
| `elearning-ut` | `opencode-skills/skills/` | ✅ | 4 | aktif, sinkron |

Semua punya frontmatter `name` + `description` → semua terdaftar ke model.
Semua `scripts/` & `references/` yang dirujuk di SKILL.md **ada** (except
rujukan lintas-skill yang memang disengaja: `cek-desil-dtsen` →
`isi_desil.py` milik `format-usulan-pip`, dan sebaliknya).

### Sumber skill di disk (peta lokasi)

| Lokasi | Isi | Peran |
| --- | --- | --- |
| `skill-opencode-faroyzi/bbnews/skills/` | 2 skill | bundle BBNEWS (repo publik) |
| `skill-free-instagram-likes/skills/` | 1 skill | bundle IG (repo publik) |
| `_skill-pip-desil/PORTABLE/skills/` | 2 skill | paket PIP/DTSEN ( installer `install.py` ) |
| `opencode-skills/skills/` | 6 skill | katalog multi-proyek (lokal, bukan git) |
| `Default Project/.opencode/skills/` | (kosong) | sebelumnya berisi versi lama `format-usulan-pip` |
| `ECC/.agents/skills/` | 46 skill | library ECC (bukan milik repo ini) |

---

## 3. Masalah yang ditemukan & cara memperbaikinya

### 3.1 🔴 Kredensial asli terpublikasi di repo publik `ozysparda/gh-free-likes`

**Gejala:** `loop.ps1` berisi password mail.tm, API key CaptchaNo, API key
SolverCF; `smmfree/engine.py` berisi password SMMNut. Repo ber-`visibility:
public` → dapat diunduh siapa saja.

**Perbaikan (21 Okt 2026):**
1. `gh repo edit ozysparda/gh-free-likes --visibility private
   --accept-visibility-change-consequences`
   → terverifikasi: API anonim → **404**, `raw.githubusercontent` → **404**
   (cache CDN sempat masih HIT ±1 jam, lalu expired).
2. Hardcode dihapus:
   - `loop.ps1` → memuat kredensial dari file `.env` (gitignored) atau env var
     yang sudah ada; nilai tidak ada lagi di source.
   - `smmfree/engine.py` → `os.environ.get("SMMNUT_PASSWORD", "")`
     (+ `import os` yang sebelumnya belum ada).
3. `.env.example` dibuat (placeholder) sebagai template.
4. Secret GitHub `SMMNUT_PASSWORD` dibuat; 3 workflow (+`SMMNUT_PASSWORD:
   ${{ secrets.SMMNUT_PASSWORD }}`).
5. Commit `fe51484` push ke repo privat.

**Pelajaran:** repo = publik berarti **kebocoran permanen** (riwayat git).
Rotasi kredensial + privatisasi + hapus dari source **belum cukup** bila
riwayat masih menyimpan nilai lama. Untuk kebocoran yang sudah published,
langkahnya: rotasi dulu (tutup akses), privatisasi, lalu bersihkan history
(`git filter-repo --replace-text` + force push).

### 3.2 🟠 `format-usulan-pip` versi lama yang aktif (shadowing)

**Gejala:** project punya `.opencode/skills/format-usulan-pip` versi 96 baris
(19:19), global punya versi 322 baris (19:48, lalu 20:16). Karena project
memiliki presedensi lebih tinggi, **versi lama yang aktif** → skill kehilangan
fitur (`buat_berkas_baru.py`, alur gabungan, dsb).

**Perbaikan:** project copy dipindah ke
`_skill-pip-desil/workspace/backup_skill_project_level/`, lalu global
di-refresh dari sumber resmi:

```powershell
cd _skill-pip-desil\PORTABLE
python install.py --no-deps     # salin 2 skill ke ~/.config/opencode/skills + self-test
```

Hasil self-test: **16 lulus, 0 gagal** (cek sintaks 11 skrip, deteksi header,
pembersihan NIK, tulis kolom O dengan XML tetap valid, konektivitas
cekbansos.kemensos.go.id, lookup NPSN resmi).

**Aturan:** jangan pernah menaruh salinan skill di `.opencode/skills/` kalau
skill yang sama juga terpasang global — project selalu menang.

### 3.3 🟠 `opencode-skills/`: 6 skill tidak akan pernah terbaca

**Gejala:**
- Semua skill memakai `skill.json` → format tidak dikenali OpenCode.
- `opencode.jsonc` menulis `skills` sebagai **object**, bukan array.
- Isi `skill.json` untuk `bbnews-deploy` stale: "Repo: ozysparda/bbnews
  (private)" (aslinya `ozysparda/BBNEWS`, public), baseline "2 terbit + 1
  draft, 142 views" (aktual 3 terbit + 0 draft, 174 views), path docs lama.

**Perbaikan:**
1. 5 skill disalin dari sumber kanonik (SKILL.md + references/ + scripts/):
   `bbnews-deploy`, `github-commit-terminal` (dari bundle BBNEWS),
   `free-instagram-likes` (dari repo IG), `cek-desil-dtsen` &
   `format-usulan-pip` (dari paket PORTABLE).
2. Skrip lokal yang versi lama dipindah ke `scripts-legacy/`
   (`cek-desil.js`, `pip-tools.py`) — tidak dihapus, tapi tidak lagi
   dirujuk SKILL.md.
3. `elearning-ut` (tidak punya SKILL.md kanonik) dibuat dari `skill.json`:
   frontmatter `name` + `description`, body = `instructions` + tabel skrip +
   salinan `peta-endpoint-tuton.md` ke `references/`.
4. `opencode.jsonc` → `"skills": ["./skills"]`.
5. `setup-new-pc.ps1` & `.py` diubah: `opencode skill install <path>` (perintah
   yang tidak ada) diganti **copy folder** ke `~/.config/opencode/skills/`, dan
   sekarang memasang keenam skill (sebelumnya hanya 3).
6. Backup: `opencode-skills/skills.bak-<timestamp>/`.

### 3.4 🟡 `.ps1` UTF-8 tanpa BOM → error parse palsu

**Gejala:** `setup-new-pc.ps1` gagal parse dengan 8 error
("output stream already redirected", "string is missing the terminator") —
padahal syntax-nya benar. Penyebab: file disimpan **UTF-8 tanpa BOM**;
Windows PowerShell 5.1 membaca `.ps1` tanpa BOM sebagai ANSI, sehingga
karakter emoji (✅ ➖ 🔐 🧪) jadi byte berantakan dan merusak parsing.

**Perbaikan:** tulis ulang dengan **UTF-8 WITH BOM** → parse error 0.
Verifikasi cepat:

```powershell
$errs=$null;$toks=$null
[System.Management.Automation.Language.Parser]::ParseFile($f,[ref]$toks,[ref]$errs) | Out-Null
$errs.Count
```

> **Aturan:** file `.ps1` yang dipakai Windows PowerShell 5.1 → simpan dengan
> BOM. Kalau skrip sudah pasti ASCII, BOM tidak wajib tapi aman.
> PowerShell 7 (`pwsh`) membaca UTF-8 tanpa BOM dengan benar.

### 3.5 Catatan lain

- `Default Project/.opencode/skills/` sengaja dikosongkan (0 item) supaya
  tidak ada yang membayangi versi global.
- `~/.config/opencode/skills/cek-desil-dtsen/` sempat punya `__pycache__`
  (artefak `py_compile`) → sudah dibersihkan oleh `install.py`
  (`ignore_patterns("__pycache__", "*.pyc")`).
- `ECC/.agents/skills/` (46 skill) adalah library pihak ketiga, di-register
  pada presedensi #3 — **tidak** menimpa skill kita.

---

## 4. Prosedur audit skill (ulangi kapan saja)

```powershell
# 1. Daftar skill terpasang + validasi frontmatter
$g = "$env:USERPROFILE\.config\opencode\skills"
Get-ChildItem $g -Directory | ForEach-Object {
    $f = Join-Path $_.FullName 'SKILL.md'
    $c = Get-Content $f -Raw -Encoding UTF8
    [PSCustomObject]@{
        Skill  = $_.Name
        FM     = [bool]($c -match '(?s)^---\s*\r?\n(.*?)\r?\n---')
        Name   = if ($c -match '(?m)^name:\s*(.+)$') { $Matches[1].Trim() } else { '-' }
        Desc   = if ($c -match '(?m)^description:\s*(.+)$') { $Matches[1].Trim().Length } else { 0 }
        Files  = (Get-ChildItem $_.FullName -Recurse -File).Count
    }
}

# 2. Cek file yang dirujuk SKILL.md tapi tidak ada
Select-String -Path "$g\*\SKILL.md" -Pattern '(scripts|references)/[\w\.\-]+' |
    ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | ForEach-Object {
        $p = Join-Path $g (Split-Path (Split-Path $_ -Parent) -Parent) $_
        "{0,-40} {1}" -f $_, (Test-Path $p)
    }

# 3. Scan kebocoran kredensial di semua folder skill
Select-String -Path "$g\*\*" -Pattern 'ghp_[A-Za-z0-9]{20,}|vcp_[A-Za-z0-9]{20,}' -ErrorAction SilentlyContinue

# 4. Bandingkan global vs sumber repo (normalisasi line ending!)
$a = (Get-Content "$g\nama-skill\SKILL.md" -Raw) -replace "`r`n","`n"
$b = (Get-Content "sumber\SKILL.md" -Raw)               -replace "`r`n","`n"
$a.TrimEnd() -ceq $b.TrimEnd()
```

---

## 5. Aturan emas tambahan (hasil audit)

1. **Skill = `SKILL.md`, bukan `skill.json`.** Format JSON tidak dibaca
   OpenCode.
2. **`skills` di config = array path**, bukan object.
3. **Project > global.** Kalau versi global lebih baru, hapus/sinkronkan salinan
   project-nya; jangan andalkan "yang terbaru menang".
4. **Satu sumber kebenaran per skill.** Instalasi = salin, bukan symlink
   yang bisa mengarah ke tempat lain.
5. **`.ps1` → UTF-8 dengan BOM** (PowerShell 5.1).
6. **`.env` = tempat kredensial lokal**; `.env.example` = template yang boleh
   masuk repo; `*.local.md` untuk dokumen kredensial lokal.
7. **Cek `gh repo view --json visibility` sebelum push** kalau repo pernah
   publik — kalau pernah publik, nilai lama masih ada di riwayat git.

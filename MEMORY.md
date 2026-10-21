# MEMORY — Indeks Pengetahuan (katalog)

Katalog skill + memory OpenCode. Tiap bundle punya subfolder sendiri supaya
beberapa sesi bisa bekerja bersamaan tanpa saling menimpa berkas.

| Bundle | Subfolder | Memory | Skill |
| --- | --- | --- | --- |
| BBNEWS (BerugakNews) | [`bbnews/`](bbnews/) | [`bbnews/MEMORY.md`](bbnews/MEMORY.md) | `bbnews-deploy`, `github-commit-terminal` |
| Free IG likes | repo `ozysparda/skill-free-instagram-likes` | di repo tersebut | `free-instagram-likes` |

## Bundle BBNEWS

| Berkas | Isi |
| --- | --- |
| `bbnews/docs/memory/01-proyek-bbnews.md` | Fakta proyek: GitHub, Vercel, Blob, admin, struktur kode, alur upload |
| `bbnews/docs/memory/02-insiden-dan-solusi.md` | Setiap error nyata, penyebab, dan perbaikannya (pesan error asli) |
| `bbnews/docs/memory/03-alur-kerja-terminal.md` | Alur end-to-end lewat terminal: clone, edit, commit, push, promote, verifikasi |
| `bbnews/docs/memory/04-trik-browser-tools.md` | Cara pakai tool browser OpenCode, termasuk jebakan (CodeMirror, CORS, base64) |
| `bbnews/docs/memory/05-token-dan-kredensial.md` | Token Vercel & GitHub, lokasi penyimpanan, pembuatan, rotasi, risikonya |
| `bbnews/docs/memory/06-qa-dan-baseline.md` | Checklist QA, angka baseline, cara memastikan data tidak rusak |

## Aturan emas ( berlaku di semua bundle)

1. **Jangan pernah menaruh token, password, atau `.env` di dalam repo.**
2. **Data artikel adalah aset utama.** Setelah deploy, selalu cek jumlah artikel
   (baseline terbaru: 3 artikel = 3 terbit + 0 draft; views naik mengikuti
   traffic dari 142 -> 174, itu normal).
3. **Editor web GitHub tidak boleh jadi alat utama.** Selalu pakai terminal.
4. **Jangan sebarkan base64 panjang di dalam panggilan tool**; ambil dari URL
   atau kirim byte apa adanya.
5. **Verifikasi byte-per-byte** setelah commit, bukan hanya "commit sukses".
6. **Bedakan LF vs CRLF** saat verifikasi berkas (git di Windows mengonversi
   otomatis) - bandingkan isi ternormalisasi.
7. **Satu bundle = satu subfolder.** Jangan menaruh skill/memory langsung di
   root repo katalog.
8. **Kredensial lokal** (password panel, API key) ditulis di file
   `*.local.md` yang di-ignore git, bukan di dokumen yang di-commit.

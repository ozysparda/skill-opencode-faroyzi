# MEMORY — Indeks Pengetahuan (bundle BBNEWS)

Semua yang dipelajari selama menangani **BerugakNews (BBNEWS)**. Bundle ini
sudah mandiri: clone repo `ozysparda/skill-opencode-faroyzi`, jalankan
`bbnews/bootstrap.ps1`, skill dan memory ikut terpasang di PC mana pun.

| Berkas | Isi |
| --- | --- |
| `docs/memory/01-proyek-bbnews.md` | Fakta proyek: GitHub, Vercel, Blob, admin, struktur kode, alur upload |
| `docs/memory/02-insiden-dan-solusi.md` | Setiap error nyata, penyebab, dan perbaikannya (pesan error asli) |
| `docs/memory/03-alur-kerja-terminal.md` | Alur end-to-end lewat terminal: clone, edit, commit, push, promote, verifikasi |
| `docs/memory/04-trik-browser-tools.md` | Cara pakai tool browser OpenCode, termasuk jebakan (CodeMirror, CORS, base64) |
| `docs/memory/05-token-dan-kredensial.md` | Token Vercel & GitHub, lokasi penyimpanan, pembuatan, rotasi, risikonya |
| `docs/memory/06-qa-dan-baseline.md` | Checklist QA, angka baseline, cara memastikan data tidak rusak |
| `docs/memory/07-skill-opencode-dan-audit.md` | Standar skill OpenCode (discovery, presedensi, format) + hasil audit semua skill & perbaikannya |

Skill di bundle ini: `bbnews-deploy`, `github-commit-terminal`.

Aturan emas yang berlaku di semua dokumen:

1. **Jangan pernah menaruh token, password, atau `.env` di dalam repo.**
2. **Data artikel adalah aset utama.** Setelah deploy, selalu cek jumlah artikel
   (baseline terbaru: 3 artikel = 3 terbit + 0 draft; views naik mengikuti
   traffic dari 142 -> 174, itu normal).
3. **Editor web GitHub tidak boleh jadi alat utama.** Selalu pakai terminal.
4. **Jangan sebarkan base64 panjang di dalam panggilan tool**; ambil dari URL
   atau kirim byte apa adanya.
5. **Verifikasi byte-per-byte** setelah commit, bukan hanya "commit sukses".
6. Bedakan unggahan file dengan line ending LF vs CRLF saat verifikasi
   (git di Windows mengonversi otomatis - bandingkan isi ternormalisasi).
7. **Skill OpenCode hanya dibaca dari `SKILL.md`** (bukan `skill.json`), dan
   `skills` di config harus **array path**.
8. **Presedensi skill: project > global.** Salinan di `.opencode/skills/`
   mengalahkan versi global meski lebih lama - jangan biarkan "versi lama"
   aktif diam-diam.
9. **File `.ps1` simpan dengan UTF-8 + BOM** kalau dipakai Windows
   PowerShell 5.1 (emoji/karakter non-ASCII bikin error parse palsu).
10. **Cek `visibility` repo sebelum push.** Repo yang pernah public = riwayat
    git masih menyimpan kredensial lama meski sudah dihapus dari source.

## Ringkasan facts (detail di `docs/memory/01`)

- Repo: `ozysparda/BBNEWS`, branch kode `vercel` (production branch Vercel =
  `main`, jadi publication lewat **promote** preview).
- Vercel: project `bbnews`, tim `ozyyyy310304s-projects`.
- Blob: store publik `bbnews-foto` (`store_9LikF3DMJKdbhRnr`).
- Admin: `https://berugaknews.vercel.app/admin`.

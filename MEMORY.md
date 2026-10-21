# MEMORY — Indeks Pengetahuan

Semua yang dipelajari selama menangani **BerugakNews (BBNEWS)**. Repo ini adalah
"otak" yang bisa dibawa ke PC mana pun: clone repo ini, jalankan `bootstrap`,
maka skill dan memory ikut terpasang.

Dokumen memory dipisah per tema supaya mudah ditengok:

| Berkas | Isi |
| --- | --- |
| `docs/memory/01-proyek-bbnews.md` | Fakta proyek: GitHub, Vercel, Blob, admin, struktur kode, alur upload |
| `docs/memory/02-insiden-dan-solusi.md` | Setiap error nyata, penyebab, dan perbaikannya (dengan pesan error asli) |
| `docs/memory/03-alur-kerja-terminal.md` | Alur kerja end-to-end lewat terminal: clone, edit, commit, push, promote, verifikasi |
| `docs/memory/04-trik-browser-tools.md` | Cara pakai tool browser OpenCode, termasuk jebakan (CodeMirror, CORS, base64) |
| `docs/memory/05-token-dan-kredensial.md` | Token Vercel & GitHub, lokasi penyimpanan, pembuatan, rotasi, dan risikonya |
| `docs/memory/06-qa-dan-baseline.md` | Checklist QA, angka baseline, cara memastikan data tidak rusak |

Skill lain di repo ini: `free-instagram-likes` (otomasi free IG likes, project
terpisah `ozysparda/gh-free-likes`).
| `docs/memory/07-ig-likes-automation.md` | Automation free Instagram likes: arsitektur GH Actions, registry 46 service, keputusan & alasannya, error→fix, trik anti-bot |
| `docs/memory/08-kredensial-ig-likes.local.md` | *(LOCAL, tidak di-commit)* kredensial panel SMM, API key captcha, mail.tm, alias Gmail |

Aturan emas yang berlaku di semua dokumen:

1. **Jangan pernah menaruh token, password, atau `.env` di dalam repo.**
2. **Data artikel adalah aset utama.** Setelah deploy, selalu cek jumlah artikel
   (baseline terbaru: 3 artikel = 3 terbit + 0 draft; views naik mengikuti
   traffic dari 142 -> 174, itu normal).
3. **Editor web GitHub tidak boleh jadi alat utama.** Selalu pakai terminal.
4. **Jangan sebarkan base64 panjang di dalam panggilan tool**; ambil dari URL
   atau kirim byte apa adanya.
5. **Verifikasi byte-per-byte** setelah commit, bukan hanya "commit sukses".
6. **Jangan pernah memasukkan password Instagram ke tool mana pun** (aturan
   pemilik untuk automation like IG). Guard otomatis ada di kode.
7. **Jangan percaya hasil "sukses" tanpa verifikasi**: pakai frasa konfirmasi
   strict, bukan kata marketing (`order`, `success`, `thank`).

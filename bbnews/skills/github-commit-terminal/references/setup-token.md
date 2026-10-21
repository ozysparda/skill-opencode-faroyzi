# Setup Token & Kredensial GitHub

Dokumen ini untuk menyiapkan akses push GitHub **sekali saja** di sebuah mesin.
Token tidak pernah ditulis ke dalam repo.

## 1. Pastikan Git terpasang

```powershell
$git = 'C:\Program Files\Git\cmd\git.exe'
& $git --version
```

Kalau command `git` tidak dikenali, tambahkan `C:\Program Files\Git\cmd` ke PATH
user:

```powershell
$cur = [Environment]::GetEnvironmentVariable('Path','User')
[Environment]::SetEnvironmentVariable('Path', $cur.TrimEnd(';') + ';C:\Program Files\Git\cmd', 'User')
```

## 2. Buat personal access token

1. Buka `https://github.com/settings/tokens/new?scopes=repo&description=opencode-agent`
2. **Note** / deskripsi: `opencode-agent`
3. **Expiration**: pilih `No expiration` (kalau tidak tersedia, pilih yang
   terpanjang lalu jadwalkan rotasi).
4. **Scopes**: centang `repo` (sudah otomatis tercentang beserta sub-scope-nya).
5. Klik **Generate token**.
6. Token hanya ditampilkan sekali. Salin dan simpan di luar repo, misalnya:
   `%TEMP%\opencode\github-token.txt`

## 3. Simpan kredensial di git (credential store)

```powershell
$token = 'ghp_...'
Set-Content -Path (Join-Path $env:USERPROFILE '.git-credentials') `
  -Value "https://ozysparda:$token@github.com" -NoNewline -Encoding ASCII

$git = 'C:\Program Files\Git\cmd\git.exe'
& $git config --global credential.helper store
```

Alternatif yang lebih aman (Windows Credential Manager) ganti helper:

```powershell
& $git config --global credential.helper manager
```

## 4. Uji akses

```powershell
$git = 'C:\Program Files\Git\cmd\git.exe'
$repo = 'C:\Users\Dunia Imajinasiku\Documents\Default Project\bbnews-git'
& $git -C $repo push --dry-run origin vercel
```

Hasil yang benar: `Everything up-to-date` dan exit code 0.

Clone repo bila belum ada:

```powershell
& $git clone --branch vercel --single-branch https://github.com/ozysparda/BBNEWS.git $repo
```

## 5. Token untuk API GitHub (opsional)

Kalau perlu memanggil REST API (mis. membuat repo lewat API), pakai token yang
sama:

```powershell
$token = ((Get-Content "$env:TEMP\opencode\github-token.txt") | Select-String 'ghp_').ToString().Trim()
$headers = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
Invoke-RestMethod -Uri 'https://api.github.com/user' -Headers $headers
```

Catatan: `api.github.com` **tidak** bisa dipanggil dengan cookie sesi browser;
harus pakai token.

## 6. Membuat repo baru lewat API (dipakai untuk repo skill)

```powershell
$token = ((Get-Content "$env:TEMP\opencode\github-token.txt") | Select-String 'ghp_').ToString().Trim()
$headers = @{ Authorization = "Bearer $token"; Accept = 'application/vnd.github+json' }
$body = @{
  name        = 'skill-opencode-faroyzi'
  description = 'Kumpulan skill OpenCode pribadi'
  private     = $true
  auto_init   = $false
} | ConvertTo-Json

Invoke-RestMethod -Uri 'https://api.github.com/user/repos' -Method Post `
  -Headers $headers -ContentType 'application/json' -Body $body
```

## 7. Rotasi

1. Buat token baru (langkah 2).
2. Ganti isi `%USERPROFILE%\.git-credentials`.
3. Uji ulang (langkah 4).
4. Hapus token lama di `https://github.com/settings/tokens`.

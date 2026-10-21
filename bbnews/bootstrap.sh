#!/usr/bin/env bash
# Bootstrap skill-opencode-faroyzi untuk macOS/Linux.
#
#   git clone https://github.com/ozysparda/skill-opencode-faroyzi.git
#   cd skill-opencode-faroyzi
#   ./bootstrap.sh
#
# Melakukan: pasang skill ke ~/.config/opencode/skills, pasang memory global
# di ~/.config/opencode/AGENTS.md, clone/update repo BBNEWS, dan menyiapkan
# credential git bila file token tersedia.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skip_clone=0
skip_memory=0
token_file="${GITHUB_TOKEN_FILE:-${TMPDIR:-/tmp}/opencode/github-token.txt}"
bbnews_path="${BBNEWS_PATH:-$(dirname "$(dirname "$repo_root")")/bbnews-git}"

while [ $# -gt 0 ]; do
  case "$1" in
    --skip-clone) skip_clone=1 ;;
    --skip-memory) skip_memory=1 ;;
    --token-file) token_file="$2"; shift ;;
    --bbnews-path) bbnews_path="$2"; shift ;;
    *) echo "Argumen tidak dikenal: $1" >&2; exit 1 ;;
  esac
  shift
done

echo "=============================================="
echo " Bootstrap skill-opencode-faroyzi"
echo "=============================================="

# ------------------------------------------------------------------ git ---
echo ">> Memeriksa Git"
if ! command -v git >/dev/null 2>&1; then
  echo "   [!] Git belum terpasang. Pasang manual:"
  echo "       macOS : brew install git"
  echo "       Debian: sudo apt install git"
  exit 1
fi
echo "   [OK] Git: $(git --version)"

# --------------------------------------------------------------- skills ---
echo ">> Menginstal skill"
./install.sh

# --------------------------------------------------------------- memory ---
if [ "$skip_memory" -eq 0 ]; then
  echo ">> Memasang memory global"
  oc_dir="${XDG_CONFIG_HOME:-$HOME/.config}/opencode"
  agents="$oc_dir/AGENTS.md"
  mkdir -p "$oc_dir"
  begin='<!-- BEGIN: skill-opencode-faroyzi -->'
  end='<!-- END: skill-opencode-faroyzi -->'

  if [ -f "$agents" ] && grep -qF "$begin" "$agents"; then
    echo "   [OK] AGENTS.md sudah punya blok memory."
  else
    {
      echo "$begin"
      echo "## Memory: bundle BBNEWS (skill-opencode-faroyzi)"
      echo
      echo "Bundle ini di subfolder \`bbnews/\` repo \`ozysparda/skill-opencode-faroyzi\`."
      echo "Memory indeks: bbnews/MEMORY.md | bbnews/docs/memory/01..07"
      echo "Skill terpasang: bbnews-deploy, github-commit-terminal."
      echo
      echo "Aturan global: jangan menaruh token/password di repo; verifikasi byte"
      echo "remote-vs-lokal setelah commit (normalisasi CRLF/LF); jaga data artikel"
      echo "(baseline terbaru: 3 artikel = 3 terbit + 0 draft)."
      echo "Standar skill: SKILL.md (bukan skill.json); skills di config = array;"
      echo "presedensi project > global; .ps1 untuk PS 5.1 = UTF-8 + BOM."
      echo "$end"
    } >> "$agents"
    echo "   [OK] AGENTS.md diperbarui: $agents"
  fi
fi

# ---------------------------------------------------------------- clone ---
if [ "$skip_clone" -eq 0 ]; then
  echo ">> Menyiapkan repo kerja BBNEWS"
  if [ -d "$bbnews_path/.git" ]; then
    git -C "$bbnews_path" pull --ff-only origin vercel
  else
    git clone --branch vercel --single-branch https://github.com/ozysparda/BBNEWS.git "$bbnews_path"
  fi
  echo "   [OK] Repo siap di $bbnews_path"
fi

# ---------------------------------------------------------- kredensial ---
echo ">> Menyiapkan kredensial git"
if [ -f "$token_file" ]; then
  token="$(grep -o 'ghp_[A-Za-z0-9]*' "$token_file" | head -n1)"
  if [ -n "$token" ]; then
    printf 'https://ozysparda:%s@github.com' "$token" > "$HOME/.git-credentials"
    chmod 600 "$HOME/.git-credentials"
    git config --global credential.helper store
    echo "   [OK] Credential store diperbarui."
  fi
else
  echo "   [!] File token GitHub tidak ditemukan ($token_file)."
  echo "       Buat PAT: https://github.com/settings/tokens/new (scope repo)"
fi

echo
echo "Selesai. Buka sesi OpenCode baru untuk memakai skill & memory."

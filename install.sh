#!/usr/bin/env bash
# Install skill dari repo ini ke folder skill global OpenCode (macOS/Linux).
#
#   ./install.sh
#   ./install.sh /path/tujuan
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source_dir="$repo_root/skills"

if [ ! -d "$source_dir" ]; then
  echo "Folder skills tidak ditemukan: $source_dir" >&2
  exit 1
fi

if [ $# -ge 1 ]; then
  dest="$1"
elif [ -n "${XDG_CONFIG_HOME:-}" ]; then
  dest="$XDG_CONFIG_HOME/opencode/skills"
else
  dest="$HOME/.config/opencode/skills"
fi

mkdir -p "$dest"

count=0
for skill in "$source_dir"/*/; do
  [ -d "$skill" ] || continue
  name="$(basename "$skill")"
  rm -rf "${dest:?}/${name}"
  cp -R "$skill" "$dest/$name"
  echo "  + $name"
  count=$((count + 1))
done

echo ""
echo "$count skill terinstall ke $dest"
echo "Buka sesi OpenCode baru supaya skill terdeteksi."

#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
theme_dir="${repo_dir}/theme"

regular_font="${REGULAR_FONT:-/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf}"
bold_font="${BOLD_FONT:-/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Bold.ttf}"

if ! command -v grub-mkfont >/dev/null 2>&1; then
  echo "error: grub-mkfont is required" >&2
  exit 1
fi

if [[ ! -f "$regular_font" ]]; then
  echo "error: regular font not found: $regular_font" >&2
  exit 1
fi

if [[ ! -f "$bold_font" ]]; then
  echo "error: bold font not found: $bold_font" >&2
  exit 1
fi

mkdir -p "$theme_dir"
grub-mkfont -o "$theme_dir/JetBrainsMonoNFM-Regular-16.pf2" --size=16 "$regular_font"
grub-mkfont -o "$theme_dir/JetBrainsMonoNFM-Regular-20.pf2" --size=20 "$regular_font"
grub-mkfont -o "$theme_dir/JetBrainsMonoNFM-Bold-20.pf2" --size=20 "$bold_font"

echo "generated GRUB fonts in $theme_dir"


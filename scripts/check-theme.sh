#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
theme_dir="${repo_dir}/theme"
theme_file="${theme_dir}/theme.txt"

if [[ ! -f "$theme_file" ]]; then
  echo "error: missing $theme_file" >&2
  exit 1
fi

required_fonts=(
  "JetBrainsMonoNFM-Regular-16.pf2"
  "JetBrainsMonoNFM-Regular-20.pf2"
  "JetBrainsMonoNFM-Bold-20.pf2"
)

for font in "${required_fonts[@]}"; do
  if [[ ! -f "${theme_dir}/${font}" ]]; then
    echo "error: missing theme font ${font}" >&2
    exit 1
  fi
done

non_printable_report="$(mktemp)"
trap 'rm -f "$non_printable_report"' EXIT

if LC_ALL=C grep -n '[^[:print:][:space:]]' "$theme_file" >"$non_printable_report"; then
  echo "error: theme.txt contains non-printable characters" >&2
  cat "$non_printable_report" >&2
  exit 1
fi

while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  if [[ ! -f "${theme_dir}/${ref}" ]]; then
    echo "error: theme references missing asset: ${ref}" >&2
    exit 1
  fi
done < <(
  sed -nE 's/^[[:space:]]*(file|desktop-image)[[:space:]]*[:=][[:space:]]*"([^"]+)".*/\2/p' "$theme_file"
)

echo "theme assets ok"

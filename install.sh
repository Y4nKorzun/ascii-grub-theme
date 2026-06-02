#!/usr/bin/env bash
set -euo pipefail

theme_name="ascii-grub-theme"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
theme_source="${script_dir}/theme"
theme_dest="/boot/grub/themes/${theme_name}"
grub_default="/etc/default/grub"
grub_cfg="/boot/grub/grub.cfg"
backup_root="/var/backups/${theme_name}"
state_dir="/var/lib/${theme_name}"
state_file="${state_dir}/last-backup"
dry_run=false
assume_yes=false
rollback=false
backup_dir=""

usage() {
  cat <<EOF
Usage:
  ./install.sh --dry-run
  ./install.sh --yes
  ./install.sh --rollback [--backup-dir PATH]

Options:
  --theme-dir PATH      Theme install directory. Default: ${theme_dest}
  --grub-default PATH   GRUB defaults file. Default: ${grub_default}
  --grub-cfg PATH       Generated GRUB config. Default: ${grub_cfg}
  --backup-dir PATH     Backup directory to restore with --rollback.
  --help                Show this help.
EOF
}

log() {
  printf '[%s] %s\n' "$theme_name" "$*"
}

die() {
  printf '[%s] error: %s\n' "$theme_name" "$*" >&2
  exit 1
}

as_root() {
  if [[ ${EUID} -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

read_root_file() {
  local source=$1
  local target=$2

  if [[ -r "$source" ]]; then
    cp -- "$source" "$target"
  else
    as_root cat "$source" >"$target"
  fi
}

write_root_file() {
  local source=$1
  local target=$2

  if [[ -f "$target" ]]; then
    as_root cp -- "$source" "$target"
  else
    as_root install -m 0644 "$source" "$target"
  fi
}

root_file_exists() {
  if [[ ${EUID} -eq 0 ]]; then
    [[ -f "$1" ]]
  else
    sudo test -f "$1"
  fi
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required"
}

print_plan() {
  cat <<EOF
${theme_name} dry run

Would install:
  ${theme_source}
to:
  ${theme_dest}

Would update:
  ${grub_default}
with:
  GRUB_THEME="${theme_dest}/theme.txt"

Would regenerate:
  ${grub_cfg}

No files were changed.
EOF
}

update_grub_default_file() {
  local input=$1
  local output=$2
  local theme_line="GRUB_THEME=\"${theme_dest}/theme.txt\""

  awk -v theme_line="$theme_line" '
    BEGIN { done = 0 }
    /^[[:space:]]*GRUB_THEME=/ {
      if (done == 0) {
        print theme_line
        done = 1
      }
      next
    }
    { print }
    END {
      if (done == 0) {
        print theme_line
      }
    }
  ' "$input" >"$output"
}

restore_backup() {
  local restore_dir=$1

  [[ -d "$restore_dir" ]] || die "backup directory not found: $restore_dir"
  [[ -f "${restore_dir}/grub.default" ]] || die "missing backup: ${restore_dir}/grub.default"

  log "restoring ${grub_default}"
  write_root_file "${restore_dir}/grub.default" "$grub_default"

  if [[ -f "${restore_dir}/grub.cfg" ]]; then
    log "restoring ${grub_cfg}"
    write_root_file "${restore_dir}/grub.cfg" "$grub_cfg"
  fi
}

rollback_install() {
  local restore_dir=$backup_dir

  if [[ -z "$restore_dir" ]]; then
    if root_file_exists "$state_file"; then
      restore_dir="$(as_root cat "$state_file")"
    else
      die "no backup state found; pass --backup-dir PATH"
    fi
  fi

  restore_backup "$restore_dir"
  log "rollback complete"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=true
      ;;
    --yes)
      assume_yes=true
      ;;
    --rollback)
      rollback=true
      ;;
    --theme-dir)
      [[ $# -ge 2 ]] || die "--theme-dir needs a value"
      theme_dest=$2
      shift
      ;;
    --grub-default)
      [[ $# -ge 2 ]] || die "--grub-default needs a value"
      grub_default=$2
      shift
      ;;
    --grub-cfg)
      [[ $# -ge 2 ]] || die "--grub-cfg needs a value"
      grub_cfg=$2
      shift
      ;;
    --backup-dir)
      [[ $# -ge 2 ]] || die "--backup-dir needs a value"
      backup_dir=$2
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

require_command cp
require_command awk

if [[ "$rollback" == true ]]; then
  rollback_install
  exit 0
fi

[[ "$dry_run" == true && "$assume_yes" == true ]] && die "use either --dry-run or --yes"

[[ -d "$theme_source" ]] || die "theme source not found: $theme_source"
[[ -f "${theme_source}/theme.txt" ]] || die "theme source missing theme.txt"
[[ -f "${theme_source}/JetBrainsMonoNFM-Regular-16.pf2" ]] || die "missing regular 16px font"
[[ -f "${theme_source}/JetBrainsMonoNFM-Regular-20.pf2" ]] || die "missing regular 20px font"
[[ -f "${theme_source}/JetBrainsMonoNFM-Bold-20.pf2" ]] || die "missing bold 20px font"

if [[ "$dry_run" == true ]]; then
  print_plan
  exit 0
fi

[[ "$assume_yes" == true ]] || die "refusing to modify system files without --yes; run --dry-run first"

require_command grub-mkconfig
require_command grub-script-check
if [[ ${EUID} -ne 0 ]]; then
  require_command sudo
fi

timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup_dir="${backup_root}/${timestamp}"
tmp_dir="$(mktemp -d)"
default_current="${tmp_dir}/grub.default.current"
default_next="${tmp_dir}/grub.default.next"
generated_cfg="${tmp_dir}/grub.cfg"
state_tmp="${tmp_dir}/last-backup"
changed_system=false

cleanup() {
  rm -rf "$tmp_dir"
}

restore_on_error() {
  if [[ "$changed_system" == true && -d "$backup_dir" ]]; then
    log "failure detected; restoring GRUB backups from ${backup_dir}"
    restore_backup "$backup_dir" || true
  fi
}

on_exit() {
  local status=$?
  if [[ $status -ne 0 ]]; then
    restore_on_error
  fi
  cleanup
  exit "$status"
}
trap on_exit EXIT

log "installing theme to ${theme_dest}"
as_root install -d "$theme_dest"
as_root cp -a "${theme_source}/." "$theme_dest/"

log "creating backup in ${backup_dir}"
as_root install -d "$backup_dir"
as_root cp -a "$grub_default" "${backup_dir}/grub.default"
if root_file_exists "$grub_cfg"; then
  as_root cp -a "$grub_cfg" "${backup_dir}/grub.cfg"
fi

read_root_file "$grub_default" "$default_current"
update_grub_default_file "$default_current" "$default_next"

log "updating ${grub_default}"
write_root_file "$default_next" "$grub_default"
changed_system=true

log "generating test config"
as_root grub-mkconfig -o "$generated_cfg"

log "checking generated config"
as_root grub-script-check "$generated_cfg"

log "writing ${grub_cfg}"
write_root_file "$generated_cfg" "$grub_cfg"

printf '%s\n' "$backup_dir" >"$state_tmp"
as_root install -d "$state_dir"
write_root_file "$state_tmp" "$state_file"

trap - EXIT
cleanup

log "install complete"
log "rollback: sudo ${script_dir}/install.sh --rollback"

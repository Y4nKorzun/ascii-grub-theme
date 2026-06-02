# Repository Guidelines

## Project Structure & Module Organization

This repository contains a monochrome GRUB theme and the scripts needed to install
or validate it.

- `theme/` holds GRUB theme assets: `theme.txt` and vendored `.pf2` fonts.
- `install.sh` is the installer, rollback entrypoint, and dry-run checker.
- `scripts/` contains developer utilities: font generation and theme validation.
- `chezmoi/` contains an optional `run_onchange_` template for chezmoi-managed
  installs.
- `licenses/`, `LICENSE`, and `THIRD_PARTY_NOTICES.md` document project and font
  licensing.

There is no separate application source tree or test fixture directory.

## Build, Test, and Development Commands

- `bash -n install.sh scripts/*.sh` checks shell syntax without running scripts.
- `scripts/check-theme.sh` verifies required fonts exist and `theme/theme.txt`
  references only present assets.
- `./install.sh --dry-run` previews install actions without changing system
  files.
- `scripts/build-fonts.sh` regenerates vendored GRUB fonts from local JetBrains
  Mono Nerd Font files. Override defaults with `REGULAR_FONT=/path/font.ttf` and
  `BOLD_FONT=/path/font.ttf`.

Only run `./install.sh --yes` when you intend to modify GRUB files under
`/boot/grub`, `/etc/default/grub`, `/var/backups`, and `/var/lib`.

## Coding Style & Naming Conventions

Shell scripts use Bash with `#!/usr/bin/env bash` and `set -euo pipefail`.
Keep indentation at two spaces, prefer lowercase `snake_case` variables and
functions, and quote variable expansions unless Bash syntax requires otherwise.
Match existing helper style: small functions such as `die`, `log`, and
`require_command`, with direct checks instead of broad abstractions.

Theme asset names should remain descriptive and stable, for example
`JetBrainsMonoNFM-Regular-20.pf2`.

## Testing Guidelines

There is no formal unit test framework. Treat the development checks as the test
suite and run them before submitting script or theme changes:

```sh
bash -n install.sh scripts/*.sh
scripts/check-theme.sh
./install.sh --dry-run
```

For installer behavior, prefer temporary paths with `--theme-dir`,
`--grub-default`, `--grub-cfg`, and `--backup-dir` instead of touching real GRUB
state during local experiments.

## Commit & Pull Request Guidelines

The current history uses Conventional Commit-style subjects, such as
`feat: add ascii grub theme` and `docs: clarify rollback output`. Continue that
pattern with short, imperative subjects.

Pull requests should describe the change, list the validation commands run, and
call out any GRUB-impacting behavior. Include screenshots or boot-menu photos
only when visual theme output changes.

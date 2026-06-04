# ascii-grub-theme

Monochrome ASCII-inspired GRUB theme for Arch/CachyOS systems.

The design is inspired by minimal terminal UI: black background, gray labels,
white selection text, and no external brand assets.

## Install

Preview the actions first:

```sh
git clone --depth 1 --branch v0.2.0 https://github.com/Y4nKorzun/ascii-grub-theme.git /tmp/ascii-grub-theme
/tmp/ascii-grub-theme/install.sh --dry-run
```

Install and regenerate GRUB:

```sh
git clone --depth 1 --branch v0.2.0 https://github.com/Y4nKorzun/ascii-grub-theme.git /tmp/ascii-grub-theme
/tmp/ascii-grub-theme/install.sh --yes
```

The installer copies the theme to `/boot/grub/themes/ascii-grub-theme`, backs
up `/etc/default/grub` and `/boot/grub/grub.cfg`, updates only `GRUB_THEME`,
generates a test config, validates it with `grub-script-check`, then writes the
real `/boot/grub/grub.cfg`.

On success it prints a rollback command for later use. That command is not run
automatically.

## Rollback

After install, rollback restores the latest saved `/etc/default/grub` and
`/boot/grub/grub.cfg`:

```sh
sudo /tmp/ascii-grub-theme/install.sh --rollback
```

If the temp clone is gone, clone the repo again and run the same rollback
command from the fresh checkout.

## chezmoi

Copy `chezmoi/run_onchange_after_20-ascii-grub-theme.sh.tmpl` into the root of
your chezmoi source directory.

Chezmoi runs `run_onchange_` scripts when their contents change, so bumping the
`version` value in that script makes `chezmoi apply` clone the new release,
install the theme, and regenerate GRUB.

## Development

Build vendored GRUB fonts from local JetBrains Mono Nerd Font files:

```sh
scripts/build-fonts.sh
```

Run local checks:

```sh
bash -n install.sh scripts/*.sh
scripts/check-theme.sh
./install.sh --dry-run
```

## Notes

- Current GRUB settings such as kernel args, timeout, `GRUB_GFXMODE`, and
  os-prober settings are preserved.
- The existing theme directory is not removed.
- The project vendors `.pf2` font files generated from JetBrains Mono Nerd
  Font Mono. See `THIRD_PARTY_NOTICES.md` and `licenses/OFL.txt`.

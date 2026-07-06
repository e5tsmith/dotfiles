# Copilot instructions — dotfiles

Personal config for a **WSL Ubuntu** setup (bash, tmux, Neovim, readline) plus the
**Windows Terminal** `settings.json`. There is no application to build here — the repo is a
collection of config files plus two bash scripts that put them in place.

## The core model: `home/` mirrors `$HOME`

Every file under [`home/`](../home/) is stored at its **home-relative path** and symlinked to the
matching location in `$HOME` by [`install.sh`](../install.sh). Example: `home/.config/nvim/init.lua`
→ `~/.config/nvim/init.lua`.

- **To add a dotfile**: drop it under `home/` at the path it should have relative to `$HOME`, then
  run `./install.sh`. The script links *every regular file* it finds under `home/` (`find -type f`),
  so no per-file registration is needed.
- **`install.sh` is idempotent and non-destructive**: an existing real file (or a symlink pointing
  elsewhere) at a target is moved to `<target>.bak` first (never clobbering an existing `.bak`;
  it falls back to `.bak.1`, `.bak.2`, …). Re-running once linked is a no-op.

## The Windows Terminal exception

`settings.json` lives on the Windows/NTFS side of the WSL boundary and **cannot be symlinked**, so it
is kept as a tracked *copy* under [`windows-terminal/`](../windows-terminal/) and synced explicitly
with [`sync-wt.sh`](../sync-wt.sh):

```bash
./sync-wt.sh          # diff repo copy vs. live file
./sync-wt.sh pull     # live Windows-side changes  -> repo (the usual commit flow)
./sync-wt.sh push     # repo copy -> live file (fresh-machine setup; backs up live file first)
```

`sync-wt.sh` auto-detects the live file by resolving `%USERPROFILE%` via `cmd.exe` and probing the
unpackaged, Store, and Preview install locations — do not hardcode a path.

## Conventions

- **`install.sh` only symlinks; it never installs software.** Prerequisite tools (neovim, tmux,
  `wslu`, `nvm`) are installed separately — see the README's Prerequisites section. Keep configs
  degrading gracefully when a tool is absent (e.g. `.bashrc` only sources `nvm` if present).
- **Neovim uses `lazy.nvim`**, bootstrapped inside `init.lua` on first launch. `home/.config/nvim/lazy-lock.json`
  is the tracked plugin lockfile — regenerate it with `:Lazy update`, don't hand-edit it.
- **WSL↔Windows clipboard bridge**: nvim's `+`/`*` registers are wired to `clip.exe` / `powershell.exe`
  (see `init.lua` `vim.g.clipboard`); tmux and readline configs assume the same bridge. Preserve this
  when touching clipboard behavior.
- **No secrets, ever.** `.gitignore` excludes `*.bak*`, editor/OS cruft, and Windows Terminal runtime
  state (`state.json`, `*.lock`). The tracked `settings.json` holds only profile GUIDs and color
  schemes — keep it that way.
- `home/.local/bin/wslview` is a personal `explorer.exe` shim; it's symlinked like any other dotfile
  and is superseded by the real `wslu` `wslview` on `PATH` if that package is installed.

## Verifying a change

There is no test suite. After editing scripts, validate with `bash -n install.sh` / `bash -n sync-wt.sh`
(both use `set -euo pipefail`), then dry-check `./sync-wt.sh` (diff mode is read-only) or re-run
`./install.sh` (safe/idempotent) to confirm linking still works.

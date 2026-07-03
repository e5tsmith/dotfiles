# dotfiles

Personal configuration for a **WSL Ubuntu** setup (shell, tmux, Neovim,
readline) plus my **Windows Terminal** settings.

The repo mirrors home-relative paths under [`home/`](home/): each file is
symlinked back to its real location by [`install.sh`](install.sh). The
Windows Terminal `settings.json` lives on the Windows side of the WSL
boundary and can't be symlinked, so it's kept as a tracked copy under
[`windows-terminal/`](windows-terminal/) and synced with
[`sync-wt.sh`](sync-wt.sh).

## Layout

```
home/
  .tmux.conf               -> ~/.tmux.conf
  .bashrc                  -> ~/.bashrc
  .bash_aliases            -> ~/.bash_aliases
  .inputrc                 -> ~/.inputrc
  .config/nvim/init.lua    -> ~/.config/nvim/init.lua
windows-terminal/
  settings.json            (copy of the live Windows Terminal config)
install.sh                 symlink the home/ files into place
sync-wt.sh                 diff / pull / push the Windows Terminal config
```

## What each file configures

| File | Purpose |
| --- | --- |
| `home/.tmux.conf` | tmux: `C-a` prefix (screen-style), vi copy-mode with `v`/`y`/`C-v` rectangle select, system-clipboard integration, `\|`/`-` splits and new windows that inherit the current pane's path, true-color + cursor-shape terminal overrides. |
| `home/.bashrc` | Ubuntu default bash config plus: large timestamped history, `nvm` loading, `nvim` as `$VISUAL`/`$EDITOR`, `set -o vi`, and an `edit_command_line` helper bound to `v` (vi-command mode) and `C-x C-e` to edit the current command line in the editor. |
| `home/.bash_aliases` | Aliases `vi`/`vim` → `nvim`. |
| `home/.inputrc` | readline: shows vi mode in the prompt and switches the cursor shape between insert/command mode; short `keyseq-timeout`. |
| `home/.config/nvim/init.lua` | Neovim: space leader, WSL clipboard bridge to the Windows clipboard via `clip.exe`/`powershell.exe`, and `<leader>y` / `<leader>p` to yank/replace the whole buffer against the Windows clipboard. |
| `windows-terminal/settings.json` | Windows Terminal: One Half Dark scheme, `copyOnSelect`, custom keybindings (duplicate pane, swap pane, send input, `ctrl+c` copy), and profile list. |

## Install (fresh machine)

```bash
git clone <this-repo-url> ~/github/dotfiles
cd ~/github/dotfiles
./install.sh
```

`install.sh` is idempotent:

- Symlinks every file under `home/` to the matching path in `$HOME`.
- Any pre-existing **real** file (or a symlink pointing elsewhere) at a
  target is moved to `<file>.bak` first — existing `.bak` files are never
  overwritten.
- Re-running once links are in place is a no-op.

To also apply the Windows Terminal config on a fresh machine:

```bash
./sync-wt.sh push        # writes windows-terminal/settings.json to the live file
```

## Keeping Windows Terminal in sync

`settings.json` can't be symlinked across the WSL/Windows boundary, so
sync it explicitly. The script auto-detects the live file (portable/
unpackaged **and** Store/packaged install locations are probed):

```bash
./sync-wt.sh             # show a diff between the repo copy and the live file
./sync-wt.sh pull        # bring live Windows-side changes INTO the repo
./sync-wt.sh push        # write the repo copy OUT to Windows (backs up first)
```

Typical flow: tweak Windows Terminal in the GUI → `./sync-wt.sh pull` →
review with `git diff` → commit.

## Notes

- **`~/.local/bin/wslview`** was requested but does not exist on this
  machine (no `wslview` on `PATH`, and the `wslu` package isn't
  installed), so it is not tracked. `wslview` normally ships with
  [`wslu`](https://github.com/wslutilities/wslu) at `/usr/bin/wslview`;
  install that package rather than vendoring the script here. If you do
  end up with a personal `~/.local/bin/wslview`, drop it at
  `home/.local/bin/wslview` and `install.sh` will pick it up
  automatically.
- The tracked Windows Terminal `settings.json` contains only profile
  GUIDs and color schemes — no secrets.

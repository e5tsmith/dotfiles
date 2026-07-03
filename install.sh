#!/usr/bin/env bash
#
# install.sh — symlink dotfiles from this repo into $HOME.
#
# Every file under home/ is linked to the matching path under $HOME,
# preserving the relative layout:
#
#     home/.bashrc                -> ~/.bashrc
#     home/.config/nvim/init.lua  -> ~/.config/nvim/init.lua
#
# Idempotent: re-running is a no-op once links are in place. Any
# pre-existing *real* file (or wrongly-pointed symlink) at a target is
# backed up to <target>.bak before the symlink is created.
#
# The Windows Terminal settings.json is NOT handled here — it can't be
# symlinked across the WSL/Windows boundary. Use ./sync-wt.sh for that.

set -euo pipefail

# Resolve the directory this script lives in, following symlinks.
SCRIPT_SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SCRIPT_SOURCE" ]; do
  dir="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
  SCRIPT_SOURCE="$(readlink "$SCRIPT_SOURCE")"
  [[ $SCRIPT_SOURCE != /* ]] && SCRIPT_SOURCE="$dir/$SCRIPT_SOURCE"
done
REPO_DIR="$(cd -P "$(dirname "$SCRIPT_SOURCE")" && pwd)"
SRC_DIR="$REPO_DIR/home"

if [ ! -d "$SRC_DIR" ]; then
  echo "error: $SRC_DIR not found — run this from the dotfiles repo." >&2
  exit 1
fi

backup() {
  # Move an existing path out of the way to <path>.bak, without ever
  # clobbering a previous backup.
  local target="$1" bak="$1.bak" n=1
  while [ -e "$bak" ] || [ -L "$bak" ]; do
    bak="$1.bak.$n"; n=$((n + 1))
  done
  mv -- "$target" "$bak"
  echo "  backed up existing $target -> $bak"
}

link_count=0 skip_count=0 backup_count=0

# Walk every regular file under home/ and link it into $HOME.
while IFS= read -r -d '' src; do
  rel="${src#"$SRC_DIR"/}"
  target="$HOME/$rel"

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
    echo "  ok      $rel (already linked)"
    skip_count=$((skip_count + 1))
    continue
  fi

  mkdir -p "$(dirname "$target")"

  if [ -e "$target" ] || [ -L "$target" ]; then
    backup "$target"
    backup_count=$((backup_count + 1))
  fi

  ln -s "$src" "$target"
  echo "  linked  $rel"
  link_count=$((link_count + 1))
done < <(find "$SRC_DIR" -type f -print0)

echo
echo "Done: $link_count linked, $skip_count already ok, $backup_count backed up."
echo "Windows Terminal settings are managed separately — see ./sync-wt.sh"

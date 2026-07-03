#!/usr/bin/env bash
#
# sync-wt.sh — keep the repo's copy of the Windows Terminal settings.json
# in sync with the live file on the Windows side.
#
# Windows Terminal's settings.json lives on an NTFS mount and cannot be
# symlinked across the WSL/Windows boundary, so instead we keep a copy in
# the repo (windows-terminal/settings.json) and sync it explicitly.
#
# Usage:
#   ./sync-wt.sh            Show a diff between the live file and the repo copy.
#   ./sync-wt.sh pull       Copy the live file INTO the repo (default sync).
#   ./sync-wt.sh push       Copy the repo copy OUT to the live file (fresh setup).
#                           The live file is backed up to *.bak first.
#
# Direction mnemonic: "pull" pulls your latest Windows-side tweaks into git;
# "push" pushes the tracked config onto a new machine.

set -euo pipefail

REPO_DIR="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_COPY="$REPO_DIR/windows-terminal/settings.json"

# Locate the live settings.json. Windows Terminal stores it in one of two
# places depending on whether it's the Store (packaged) or portable
# (unpackaged) build. We resolve the Windows user profile via cmd.exe and
# probe both known locations.
find_live() {
  local profile winpath
  profile="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')" || true
  if [ -z "${profile:-}" ]; then
    echo "error: could not determine Windows %USERPROFILE% (is cmd.exe on PATH?)" >&2
    return 1
  fi
  winpath="$(wslpath "$profile")"

  local candidates=(
    # Unpackaged / portable build (this machine):
    "$winpath/AppData/Local/Microsoft/Windows Terminal/settings.json"
    # Store (packaged) build:
    "$winpath/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    # Preview channel:
    "$winpath/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
  )
  local c
  for c in "${candidates[@]}"; do
    if [ -f "$c" ]; then printf '%s\n' "$c"; return 0; fi
  done
  echo "error: could not find a live Windows Terminal settings.json under $winpath" >&2
  return 1
}

LIVE="$(find_live)"
action="${1:-diff}"

case "$action" in
  diff)
    if diff -u "$REPO_COPY" "$LIVE" >/tmp/wt.diff 2>&1; then
      echo "In sync: repo copy matches live file."
      echo "  live: $LIVE"
    else
      echo "Differences (< repo copy, > live file):"
      echo "  live: $LIVE"
      echo
      diff -u \
        --label "repo/windows-terminal/settings.json" "$REPO_COPY" \
        --label "live: $LIVE" "$LIVE" || true
      echo
      echo "Run './sync-wt.sh pull' to bring these changes into the repo,"
      echo "or   './sync-wt.sh push' to write the repo copy out to Windows."
    fi
    rm -f /tmp/wt.diff
    ;;
  pull)
    cp -- "$LIVE" "$REPO_COPY"
    echo "Pulled live settings into repo:"
    echo "  $LIVE"
    echo "  -> $REPO_COPY"
    echo "Review with 'git diff' and commit if it looks right."
    ;;
  push)
    if [ -f "$LIVE" ]; then
      bak="$LIVE.bak"; n=1
      while [ -e "$bak" ]; do bak="$LIVE.bak.$n"; n=$((n + 1)); done
      cp -- "$LIVE" "$bak"
      echo "Backed up live file -> $bak"
    fi
    cp -- "$REPO_COPY" "$LIVE"
    echo "Pushed repo copy out to live file:"
    echo "  $REPO_COPY"
    echo "  -> $LIVE"
    ;;
  *)
    echo "usage: $0 [diff|pull|push]" >&2
    exit 2
    ;;
esac

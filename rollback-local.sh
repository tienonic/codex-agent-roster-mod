#!/usr/bin/env bash

set -euo pipefail

root=${CODEX_SUBAGENT_ROSTER_HOME:-"$HOME/.local/share/codex-subagent-roster"}
root=$(cd -- "$root" && pwd -P)
packages="$root/packages"
bin_dir="$root/bin"
launcher="$bin_dir/codex"
previous="$bin_dir/codex.previous"

[[ -L $launcher && -L $previous ]] || {
  echo 'No installed roster launcher and rollback symlink were both found.' >&2
  exit 1
}
current_target=$(readlink -- "$launcher")
previous_target=$(readlink -- "$previous")
current=$(readlink -f -- "$launcher")
prior=$(readlink -f -- "$previous")
case "$current" in
  "$packages"/*/bin/codex) ;;
  *) echo "Current launcher points outside the versioned roster package store: $launcher" >&2; exit 1 ;;
esac
case "$prior" in
  "$packages"/*/bin/codex) ;;
  *) echo "Rollback launcher points outside the versioned roster package store: $previous" >&2; exit 1 ;;
esac

tmp_current="$bin_dir/.codex.rollback.new.$$"
tmp_previous="$bin_dir/.codex.previous.rollback.new.$$"
cleanup() { rm -f -- "$tmp_current" "$tmp_previous"; }
trap cleanup EXIT
ln -s "$previous_target" "$tmp_current"
ln -s "$current_target" "$tmp_previous"
mv -Tf -- "$tmp_previous" "$previous"
mv -Tf -- "$tmp_current" "$launcher"
trap - EXIT
printf 'Rolled back custom Codex launcher to %s\n' "$prior"
"$launcher" --version

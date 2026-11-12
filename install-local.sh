#!/usr/bin/env bash

set -euo pipefail

usage() {
  printf 'Usage: %s BUILT_PACKAGE_DIR\n' "$0" >&2
  printf 'Optional: CODEX_SUBAGENT_ROSTER_HOME (default: ~/.local/share/codex-subagent-roster)\n' >&2
}

if [[ $# != 1 ]]; then
  usage
  exit 2
fi

source_package=$(cd -- "$1" && pwd -P)
metadata="$source_package/codex-package.json"
binary="$source_package/bin/codex"
[[ -f $metadata && -x $binary ]] || { echo 'Built Codex package must contain codex-package.json and executable bin/codex.' >&2; exit 1; }

readarray -t fields < <(python3 - "$metadata" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for key in ("version", "target", "variant", "entrypoint"):
    print(data.get(key, ""))
PY
)
[[ ${#fields[@]} == 4 ]] || { echo 'Could not read Codex package metadata.' >&2; exit 1; }
version=${fields[0]}
[[ $version =~ ^0\.167\.[12]$ ]] || { echo "Unsupported version: $version" >&2; exit 1; }
[[ ${fields[1]} == x86_64-unknown-linux-musl && ${fields[2]} == codex && ${fields[3]} == bin/codex ]] || {
  echo 'Package must be the x86_64-unknown-linux-musl Codex CLI package.' >&2
  exit 1
}
version_output=$("$binary" --version)
[[ $version_output == "codex-cli $version" ]] || {
  echo "Binary version does not match package metadata: $version_output" >&2
  exit 1
}

root=${CODEX_SUBAGENT_ROSTER_HOME:-"$HOME/.local/share/codex-subagent-roster"}
root=$(mkdir -p -- "$root" && cd -- "$root" && pwd -P)
packages="$root/packages"
bin_dir="$root/bin"
mkdir -p -- "$packages" "$bin_dir"
package="$packages/$version"
launcher="$bin_dir/codex"
previous="$bin_dir/codex.previous"

if [[ -e $package || -L $package ]]; then
  [[ -f $package/codex-package.json && -x $package/bin/codex ]] || {
    echo "Existing version directory is not a Codex package: $package" >&2
    exit 1
  }
  cmp -s -- "$source_package/bin/codex" "$package/bin/codex" || {
    echo "Version $version already exists with a different binary; refusing to replace it." >&2
    exit 1
  }
else
  staged=$(mktemp -d "$packages/.${version}.staging.XXXXXX")
  cleanup() { rm -rf -- "$staged"; }
  trap cleanup EXIT
  cp -a -- "$source_package/." "$staged/"
  [[ $("$staged/bin/codex" --version) == "codex-cli $version" ]] || {
    echo 'Staged binary version check failed.' >&2
    exit 1
  }
  mv -- "$staged" "$package"
  trap - EXIT
fi

old_target=''
if [[ -e $launcher || -L $launcher ]]; then
  [[ -L $launcher ]] || { echo "Refusing to replace a non-symlink launcher: $launcher" >&2; exit 1; }
  old_target=$(readlink -- "$launcher")
  resolved_old=$(readlink -f -- "$launcher")
  case "$resolved_old" in
    "$packages"/*/bin/codex) ;;
    *) echo "Refusing to replace a launcher outside this package store: $launcher" >&2; exit 1 ;;
  esac
  if [[ $resolved_old == "$package/bin/codex" ]]; then
    echo "Already routed to Codex $version: $launcher"
    exit 0
  fi
fi
if [[ -e $previous || -L $previous ]] && [[ ! -L $previous ]]; then
  echo "Refusing to replace a non-symlink rollback record: $previous" >&2
  exit 1
fi

tmp_link="$bin_dir/.codex.new.$$"
ln -s "../packages/$version/bin/codex" "$tmp_link"
if [[ -n $old_target ]]; then
  tmp_previous="$bin_dir/.codex.previous.new.$$"
  ln -s "$old_target" "$tmp_previous"
  mv -Tf -- "$tmp_previous" "$previous"
fi
mv -Tf -- "$tmp_link" "$launcher"
printf 'Installed Codex %s at %s\n' "$version" "$package"
printf 'Custom launcher: %s\n' "$launcher"
printf 'Add its bin directory before ~/.local/bin in the terminal PATH to route new CLI sessions.\n'

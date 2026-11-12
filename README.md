# Codex subagent roster mod

This repository contains a version-pinned patch for the Codex CLI. It adds a persistent roster of the current conversation's child agents to the chat footer and keeps the existing subagent picker. Apply a patch only to the exact upstream commit named below.

## Supported source versions

| Codex CLI | Upstream tag | Required base commit | Patch |
| --- | --- | --- | --- |
| 0.167.1 | `rust-v0.167.1` | `0a94398fa60c4fac0e7659e4213a0a36e613dd46` | `subagent-roster-0.167.1.patch` |
| 0.167.2 | `rust-v0.167.2` | `ce21072c90d32c40af7a55b60b2fb35c84a43a6a` | `subagent-roster-0.167.2.patch` |

Both patches carry the same persistent roster implementation ported to their exact upstream commits. The 0.167.2 port adds `codex-rs/tui/src/agent_roster.rs` and changes 16 TUI files. Its raw diff contains no Cargo.lock refresh.

Upstream repository: <https://github.com/openai/codex>

## Build Codex 0.167.2 on Linux x86_64

The verified target is `x86_64-unknown-linux-musl`, using the upstream `dev-small` profile and `RUST_MIN_STACK=8388608` for focused tests. Rust and Cargo must be available, with the musl Rust target installed. The build uses same-version helper executables from the official 0.167.2 Linux package and compiles the patched CLI entrypoint from source.

```bash
set -euo pipefail
git clone --branch rust-v0.167.2 --depth 1 https://github.com/openai/codex.git codex-0.167.2-agent-view
cd codex-0.167.2-agent-view
test "$(git rev-parse HEAD)" = ce21072c90d32c40af7a55b60b2fb35c84a43a6a

release=https://github.com/openai/codex/releases/download/rust-v0.167.2
helper_dir="$HOME/.cache/codex-agent-roster-0.167.2/upstream-package"
mkdir -p "$helper_dir/verified"
curl -fsSL "$release/codex-package_SHA256SUMS" -o "$helper_dir/codex-package_SHA256SUMS"
curl -fL "$release/codex-package-x86_64-unknown-linux-musl.tar.gz" \
  -o "$helper_dir/codex-package-x86_64-unknown-linux-musl.tar.gz"
(
  cd "$helper_dir"
  grep '  codex-package-x86_64-unknown-linux-musl.tar.gz$' codex-package_SHA256SUMS | sha256sum -c -
)
tar -xzf "$helper_dir/codex-package-x86_64-unknown-linux-musl.tar.gz" -C "$helper_dir/verified"
git apply --check /path/to/codex-agent-roster-mod/subagent-roster-0.167.2.patch
git apply /path/to/codex-agent-roster-mod/subagent-roster-0.167.2.patch

cd codex-rs
RUST_MIN_STACK=8388608 cargo test --target x86_64-unknown-linux-musl --profile dev-small -p codex-tui roster
RUST_MIN_STACK=8388608 cargo test --target x86_64-unknown-linux-musl --profile dev-small -p codex-tui selected_and_resumed_threads_use_server_capability_for_v1_and_v2_children
RUST_MIN_STACK=8388608 cargo test --target x86_64-unknown-linux-musl --profile dev-small -p codex-tui refresh_pending_thread_approvals_only_lists_inactive_threads
RUST_MIN_STACK=8388608 cargo test --target x86_64-unknown-linux-musl --profile dev-small -p codex-tui existing_primary_attach_restores_main_liveness_from_turns

cd ..
CODEX_REPO_ROOT="$PWD" python3 scripts/build_codex_package.py \
  --variant codex \
  --package-version 0.167.2 \
  --cargo-profile dev-small \
  --code-mode-host-bin "$helper_dir/verified/bin/codex-code-mode-host" \
  --exec-server-bin "$helper_dir/verified/bin/codex-exec-server" \
  --bwrap-bin "$helper_dir/verified/codex-resources/bwrap" \
  --rg-bin "$helper_dir/verified/codex-path/rg" \
  --package-dir "$HOME/.cache/codex-agent-roster-0.167.2/package"
"$HOME/.cache/codex-agent-roster-0.167.2/package/bin/codex" --version
sha256sum "$HOME/.cache/codex-agent-roster-0.167.2/package/bin/codex"
```

The 0.167.2 source port passed ten focused tests across the four filters below: seven roster checks plus the selected/resumed worker, inactive-approval, and primary-attach liveness checks. See [SOURCE-VALIDATION.md](SOURCE-VALIDATION.md). The full TUI suite was not run. A native preview of the built CLI is still needed to confirm the rendered footer. The CLI patch leaves the official app-server package unchanged.

## Custom local install and rollback

`install-local.sh` copies a matching built package into a versioned directory under `~/.local/share/codex-subagent-roster/packages/` and creates or updates the custom launcher at `~/.local/share/codex-subagent-roster/bin/codex`. It does not change `~/.local/bin/codex`, Codex configuration, or the official app-server. It supports only versions 0.167.1 and 0.167.2 and refuses to overwrite a different binary already stored under the same version.

```bash
./install-local.sh /path/to/codex-package
```

The installer does not edit PATH. If you put `~/.local/share/codex-subagent-roster/bin` before `~/.local/bin`, route `codex app-server ...` and daemon commands back to the official managed `~/.local/bin/codex`; this package's launcher is intended for the patched CLI frontend. The current launcher target is saved as `bin/codex.previous` on an upgrade. Run `rollback-local.sh` to swap back to that version; both versioned packages remain available.

```bash
./rollback-local.sh
```

This is a Linux/WSL CLI package. It does not install the native Windows Codex application. Each future Codex release needs its own source review, patch port, focused checks, and package build before the installer will accept it.

## Patch check and build receipts

Patch SHA-256 values are in `SHA256SUMS`. The 0.167.2 port applies cleanly to its pristine tag checkout. Record the package metadata and binary hash with each build.

## License and provenance

The patch is distributed under Apache License 2.0, matching the upstream Codex source. See `LICENSE` and upstream `NOTICE`. The patch is derived from the public Codex repository and retains upstream file notices where present. No individual author attribution is asserted by this package. OpenAI and upstream contributors retain their names, marks, and notices; this package does not imply endorsement by OpenAI.

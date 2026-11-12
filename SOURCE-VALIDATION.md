# Codex 0.167.1 and 0.167.2 source validation

Validated on November 12, 2026 against the public upstream Codex repository.

Both version-pinned patches include the active-first worker ordering fix. Main remains first; Running and Waiting workers precede Idle and Closed workers before the five-worker display cap. Order within each state is stable, and a selected child remains visible in the capped rows.

| Codex CLI | Upstream tag | Required base commit | Patch SHA-256 |
| --- | --- | --- | --- |
| 0.167.1 | `rust-v0.167.1` | `0a94398fa60c4fac0e7659e4213a0a36e613dd46` | `8b95bf11e6466dee09695907f26854f1266f79eb4b0e7bea4fe719ae8c37a2eb` |
| 0.167.2 | `rust-v0.167.2` | `ce21072c90d32c40af7a55b60b2fb35c84a43a6a` | `7d55972172131d812d4b4275b36ec82794236e1e91cdea0eb9ddae321f9eab7f` |

| Item | Result |
| --- | --- |
| Upstream tag | `rust-v0.167.2` |
| Required base commit | `ce21072c90d32c40af7a55b60b2fb35c84a43a6a` |
| Source patch | `subagent-roster-0.167.2.patch` |
| Patch SHA-256 | `7d55972172131d812d4b4275b36ec82794236e1e91cdea0eb9ddae321f9eab7f` |
| Patch scope | 16 TUI files; 918 insertions and 16 deletions |
| Apply check | Passed on a clean checkout at the required base commit |

The four focused `codex-tui` test filters passed, covering eleven tests. The full TUI test suite was not run.

| Filter | Passed | Failed |
| --- | ---: | ---: |
| `roster` | 8 | 0 |
| `selected_and_resumed_threads_use_server_capability_for_v1_and_v2_children` | 1 | 0 |
| `refresh_pending_thread_approvals_only_lists_inactive_threads` | 1 | 0 |
| `existing_primary_attach_restores_main_liveness_from_turns` | 1 | 0 |

The active-first overflow regression verifies that running and waiting workers stay within the five visible worker slots despite earlier closed descendants; the selected child remains visible. Both 0.167.1 and 0.167.2 patches passed `git apply --check` on clean source checkouts. The local launcher and rollback scripts pass `bash -n`.

The 0.167.2 Linux x86_64 `x86_64-unknown-linux-musl` package built successfully with the upstream `dev-small` profile and `RUST_MIN_STACK=8388608`. Its `codex-cli --version` is `0.167.2`; the binary SHA-256 is `daddc9304862c6387ba8e61e0d445a1345515b0e1500cd9157196758c13209ad`. The native preview used plain `codex resume` without an explicit remote endpoint. The custom frontend connected to the existing official managed app-server; the server process stayed at PID 1304766 and was not restarted. An active worker was visible within the five worker rows at both standard terminal size and 55x18. No prompt or new model turn was sent, and no user pane was changed.

The retained local captures are `subagent-roster-preview-0.167.2-active-first-v2-normal.txt` (SHA-256 `f5f6a94857f1d2463adcaea63999059415a25b58374bb59d2b750f02f4e075d3`) and `subagent-roster-preview-0.167.2-active-first-v2-narrow.txt` (SHA-256 `986bc478e2b9bb9f56be6058d9b527ca371c075d8df38070dc178391a1652291`). The corrected build supersedes the earlier preview, which found that active workers could fall beyond the five-row cap.

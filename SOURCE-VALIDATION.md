# Codex 0.167.2 source validation

Validated on November 11, 2026 against the public upstream Codex repository.

| Item | Result |
| --- | --- |
| Upstream tag | `rust-v0.167.2` |
| Required base commit | `ce21072c90d32c40af7a55b60b2fb35c84a43a6a` |
| Source patch | `subagent-roster-0.167.2.patch` |
| Patch SHA-256 | `5b81daadefb907fb22bb76d67aed9820938755b7a4036356eb115da6a6fa0136` |
| Patch scope | 16 TUI files; 838 insertions and 16 deletions |
| Apply check | Passed on a clean checkout at the required base commit |

The four focused `codex-tui` test filters passed, covering ten tests. The full TUI test suite was not run.

| Filter | Passed | Failed |
| --- | ---: | ---: |
| `roster` | 7 | 0 |
| `selected_and_resumed_threads_use_server_capability_for_v1_and_v2_children` | 1 | 0 |
| `refresh_pending_thread_approvals_only_lists_inactive_threads` | 1 | 0 |
| `existing_primary_attach_restores_main_liveness_from_turns` | 1 | 0 |

The local launcher and rollback scripts pass `bash -n`. This source receipt does not establish a built binary or a rendered terminal preview.

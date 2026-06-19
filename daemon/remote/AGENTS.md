# daemon/remote — agent guide

Component-specific rules for `daemon/remote/`. Cross-cutting repo rules: [`/AGENTS.md`](../../AGENTS.md). Deeper detail: [`daemon/remote/README.md`](README.md), [`docs/remote-daemon-spec.md`](../../docs/remote-daemon-spec.md).

## Overview
`cmuxd-remote`: the Go daemon that backs `cmux ssh` remote-tmux sessions. It runs on the remote host (over stdio or a WebSocket) and provides a tmux-compatibility shim so cmux can mirror/control remote terminals.

## Tech Stack
Go 1.22 (module `daemon/remote/go.mod`). Standard library + Go test framework; no external service required to test.

## Commands
```bash
cd daemon/remote
go test ./...        # unit tests (matches the remote-daemon-tests CI job)
go vet ./...
go build ./...
go run ./cmd/cmuxd-remote version
go run ./cmd/cmuxd-remote serve --stdio
```
Release-asset packaging is validated by `tests/test_remote_daemon_release_assets.sh` (run from repo root).

## Project Layout
- `cmd/cmuxd-remote/` — entrypoint and CLI: `main.go`, `cli.go`, `tmux_compat.go`, `agent_launch.go`, with `*_test.go` alongside.
- `TMUX_CORPUS.md` — tmux-compat reference corpus (see `.github/workflows/tmux-corpus.yml`).

## Code Style & Patterns
- Standard Go layout; tests live next to the code as `*_test.go`.
- The tmux-compat shim must report tmux format codes/state correctly — guard changes with the corpus tests.

## Guardrails
- **Always** run `go test ./...` after changes here; keep the daemon dependency-free unless justified.
- **Use caution:** changes to release-asset paths must keep `tests/test_remote_daemon_release_assets.sh` green.

## Agent Notes
Symlinked to `CLAUDE.md` and `GEMINI.md`; keep guidance tool-neutral.

# Contributing to cmux

> **New here?** Read [`docs/repository.md`](docs/repository.md) for the whole-monorepo map (macOS/iOS apps, `web/` backend, `daemon/remote`, workers, packages), the tech stack, and where things live. Agent build notes and pitfalls live in [`CLAUDE.md`](CLAUDE.md) (`AGENTS.md` is a symlink to it); area-specific rules live in [`skills/`](skills/).

This page covers macOS-app development. For the web/cloud backend see [`web/README.md`](web/README.md); for other components see their READMEs (`ios/`, `webviews/`, `workers/presence/`, `daemon/remote/`).

## Prerequisites

- macOS (CI and releases build on macOS 15; macOS 26+ "Tahoe" is supported for development — see [Building on macOS 26+](#building-on-macos-26-tahoe))
- Xcode 26.x — the toolchain is pinned in [`.xcode-version`](.xcode-version) (`26.0`)
- [Zig](https://ziglang.org/) (install via `brew install zig`) — used to build `GhosttyKit.xcframework` and the Ghostty CLI helper

## Getting Started

1. Clone the repository with submodules:
   ```bash
   git clone --recursive https://github.com/manaflow-ai/cmux.git
   cd cmux
   ```

2. Run the setup script:
   ```bash
   ./scripts/setup.sh
   ```

   This will:
   - Initialize git submodules (`ghostty`, `homebrew-cmux`, `vendor/bonsplit`)
   - Build or reuse the cached `GhosttyKit.xcframework`
   - Install the pbxproj-normalization pre-commit hook

3. Build the debug app:
   ```bash
   ./scripts/reload.sh --tag my-feature
   ```
   The script prints the `App path:` line. Cmd-click to open, or pass `--launch` to open automatically. Always build through `reload.sh --tag <tag>`; never run a bare `xcodebuild` or open an untagged `cmux DEV.app` (untagged builds share the default debug socket/bundle ID and steal focus). See [`CLAUDE.md`](CLAUDE.md) for the tagged-build rationale and the `cmux-debug-cli.sh` dogfood helper.

## Building on macOS 26+ (Tahoe)

The pinned compiler **zig 0.15.2 cannot link the Ghostty CLI helper against the macOS 26 SDK**. `reload.sh` and `scripts/build-ghostty-cli-helper.sh` auto-detect macOS 26+ and skip that one zig build, emitting a Mach-O stub so the app still builds, signs, and runs (only the standalone `ghostty +<command>` passthrough is disabled). No env var is needed; force the real build with `CMUX_SKIP_ZIG_BUILD=0`. Detection lives in `scripts/lib/ghostty-cli-helper-skip.sh`. Background: [issue #3047](https://github.com/manaflow-ai/cmux/issues/3047).

## Development Scripts

| Script | Description |
|--------|-------------|
| `./scripts/setup.sh` | One-time setup (submodules + GhosttyKit + git hooks) |
| `./scripts/reload.sh --tag <tag>` | Build Debug app (pass `--launch` to also open it) |
| `./scripts/reloadp.sh` | Build and launch the Release app |
| `./scripts/reloads.sh` | Build and launch an isolated "cmux STAGING" Release app |
| `./scripts/reload2.sh --tag <tag>` | Reload both Debug and Release |
| `./scripts/cleanup-dev-builds.sh` | Remove old tagged dev builds and sockets |
| `CMUX_TAG=<tag> ./scripts/cmux-debug-cli.sh <cmd>` | Drive a tagged Debug build over its socket |

## Team dogfood setup

DEBUG builds can auto-sign-in as you and auto-attach an iOS build to your Mac with no manual steps. Each developer does a one-time setup with their own Stack account.

Run this once:

```bash
scripts/setup-team-dev.sh
```

It prompts for your Stack email and password (the password is never echoed), verifies them against Stack, and writes `~/.secrets/cmuxterm-dev.env` with `chmod 600`. Re-running it is safe; if you are already configured it prints the account and exits. To reset, delete `~/.secrets/cmuxterm-dev.env` and run it again.

After that, every dev build signs you in automatically:

```bash
scripts/dev-setup.sh --tag <your-initials>
```

That builds the tagged macOS DEBUG app auto-signed-in as you, enables the iOS pairing host, mints an attach ticket, and launches the iOS dev build auto-attached to your Mac. Use `--surface mac` for macOS only. See `scripts/dev-setup.sh --help` for all flags.

This is DEBUG-only and per-user. The credentials file lives outside the repo and is never committed; `scripts/cmuxterm-dev.env.example` is the in-repo template. Release builds never read these credentials (the auto-sign-in path is compiled out of release).

## Web and JS Tooling

Run Biome from the repository root with:

```bash
bun run biome:check
```

The root `biome.json` intentionally scopes `biome check .` to maintained web and JS/TS sources.
It excludes generated bundles, build outputs, vendored trees, and review-tool metadata such as
`.greptile/`.
Biome formatting and import sorting are disabled for now; do not wire this into required CI until
the remaining source lint diagnostics are paid down.

## Rebuilding GhosttyKit

If you make changes to the ghostty submodule, rebuild the xcframework:

```bash
cd ghostty
zig build -Demit-xcframework=true -Doptimize=ReleaseFast
```

## Running Tests

### Basic tests (run on VM)

```bash
ssh cmux-vm 'cd /Users/cmux/cmux && xcodebuild -project cmux.xcodeproj -scheme cmux -configuration Debug -destination "platform=macOS" build && pkill -x "cmux DEV" || true && APP=$(find /Users/cmux/Library/Developer/Xcode/DerivedData -path "*/Build/Products/Debug/cmux DEV.app" -print -quit) && open "$APP" && for i in {1..20}; do [ -S /tmp/cmux.sock ] && break; sleep 0.5; done && python3 tests/test_update_timing.py && python3 tests/test_signals_auto.py && python3 tests/test_ctrl_socket.py && python3 tests/test_notifications.py'
```

### UI tests (run on VM)

```bash
ssh cmux-vm 'cd /Users/cmux/cmux && xcodebuild -project cmux.xcodeproj -scheme cmux -configuration Debug -destination "platform=macOS" -only-testing:cmuxUITests test'
```

## Ghostty Submodule

The `ghostty` submodule points to [manaflow-ai/ghostty](https://github.com/manaflow-ai/ghostty), a fork of the upstream Ghostty project.

### Making changes to ghostty

```bash
cd ghostty
git checkout -b my-feature
# make changes
git add .
git commit -m "Description of changes"
git push manaflow my-feature
```

### Keeping the fork updated

```bash
cd ghostty
git fetch origin
git checkout main
git merge origin/main
git push manaflow main
```

Then update the parent repo:

```bash
cd ..
git add ghostty
git commit -m "Update ghostty submodule"
```

See `docs/ghostty-fork.md` for details on fork changes and conflict notes.

## License

By contributing to this repository, you agree that:

1. Your contributions are licensed under the project's GNU General Public License v3.0 or later (`GPL-3.0-or-later`).
2. You grant Manaflow, Inc. a perpetual, worldwide, non-exclusive, royalty-free, irrevocable license to use, reproduce, modify, sublicense, and distribute your contributions under any license, including a commercial license offered to third parties.

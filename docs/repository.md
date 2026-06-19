# cmux repository guide

Developer- and agent-facing map of the cmux monorepo: what the repository contains, the product surfaces it ships, where the important pieces live, and the verified commands to build, run, test, and change it.

For end-user product docs (install, features, keyboard shortcuts, session restore), see the root [`README.md`](../README.md) and <https://cmux.com/docs>. For the day-to-day local build loop, see [`CONTRIBUTING.md`](../CONTRIBUTING.md) and the agent build notes in [`CLAUDE.md`](../CLAUDE.md) (`AGENTS.md` is a symlink to it).

## What this repository is

cmux is a native macOS terminal-and-browser app for running AI coding agents, plus the supporting CLI, iOS app, cloud/web backend, and services. The macOS app renders terminals with [libghostty](https://github.com/manaflow-ai/ghostty) (a fork vendored as the `ghostty` submodule) and adds vertical/horizontal tabs, split panes, a notification system, an in-app scriptable browser, workspaces, and a CLI + local socket API to control all of it.

It is a polyglot monorepo. The macOS and iOS apps are the primary product; the other trees support them.

## Product surfaces

| Surface | Lives in | Notes / deep docs |
| ------- | -------- | ----------------- |
| **macOS app** | `Sources/`, `Packages/macOS/*`, `Native/`, `Resources/` | The main product. Swift + AppKit/SwiftUI, terminal via libghostty. |
| **`cmux` CLI** | `CLI/*.swift` | Built as a helper bundled into the app at `Contents/Resources/bin/cmux`. Subcommands like `notify`, `ssh`, `claude-teams`, `hooks setup`, `surface resume`, `restore-session`, `list-workspaces`, `send`. Contract: [`docs/cli-contract.md`](cli-contract.md). |
| **Local socket / control API** | `Packages/macOS/CmuxControlSocket`, `CLI/` | Unix-socket IPC the CLI and automations use to create workspaces, split panes, send keystrokes, drive the browser. See [`docs/cli-contract.md`](cli-contract.md), [`docs/events.md`](events.md), [`docs/v2-api-migration.md`](v2-api-migration.md). |
| **In-app browser automation** | `Packages/macOS/CmuxBrowser`, `webviews/` | Scriptable browser API ported from agent-browser (snapshot a11y tree, click, fill, eval). Spec: [`docs/agent-browser-port-spec.md`](agent-browser-port-spec.md). |
| **Agent hooks / notifications** | `CLI/`, `Packages/macOS/CmuxNotifications` | `cmux notify` + OSC 9/99/777 parsing wired into agent hooks. See [`docs/agent-hooks.md`](agent-hooks.md), [`docs/notifications.md`](notifications.md). |
| **iOS app** | `ios/` | Separate Xcode project; terminals synced with the Mac. See [`ios/README.md`](../ios/README.md). |
| **Web / cloud backend + docs site** | `web/` | Next.js app on Vercel: website + `cmux.com/docs`, Stack Auth handlers, feedback, Stripe, device push, and the Cloud VM control plane (`web/app/api/vm`). See [`web/README.md`](../web/README.md). |
| **Remote SSH daemon** | `daemon/remote/` | Go daemon backing `cmux ssh` remote-tmux sessions. Spec: [`docs/remote-daemon-spec.md`](remote-daemon-spec.md). |
| **Presence service** | `workers/presence/` | Cloudflare Worker (`cmux-presence-worker`) for device presence. See [`workers/presence/README.md`](../workers/presence/README.md), [`docs/presence-service.md`](presence-service.md). |
| **Sidebar extensions (ExtensionKit)** | `Examples/`, `Packages/macOS/CmuxExtensionKit` | Custom/vibe-coded sidebars. See [`docs/custom-sidebars.md`](custom-sidebars.md). |

## Repository map

| Path | Purpose |
| ---- | ------- |
| `Sources/` | macOS app sources (AppDelegate, windowing, terminal hosting, agent session plumbing). ~560 Swift files. |
| `Packages/` | Swift packages, grouped by consumer: `Shared/` (both apps), `macOS/` (Mac only, ~35 packages), `iOS/` (iOS only). The folder is the source of truth for workspace grouping. |
| `CLI/` | `cmux` CLI sources (Swift). |
| `Native/CommandPaletteNucleoFFI/` | Rust FFI (nucleo fuzzy matcher) for the command palette. |
| `ghostty/` | Submodule: `manaflow-ai/ghostty` fork (Zig). Source for `GhosttyKit.xcframework`. |
| `GhosttyKit.xcframework/` | Prebuilt/cached libghostty xcframework consumed by the app. |
| `daemon/remote/` | Go remote SSH daemon. |
| `web/` | Next.js + bun web app, docs site, Postgres (Drizzle), Cloud VM backend. |
| `webviews/` | Vite/TypeScript webview UIs (browser surfaces, agent-session views). |
| `workers/presence/` | Cloudflare Worker for device presence. |
| `ios/` | iOS app (separate Xcode project + SPM packages). |
| `Resources/` | App resources: `Localizable.xcstrings`, Info.plist, shell integration, terminfo, feed-tui. |
| `Examples/` | Sample ExtensionKit sidebars and stub agent extensions. |
| `cmuxTests/`, `cmuxUITests/` | Swift unit tests and AppKit UI tests for the macOS app. |
| `tests/`, `tests_v2/` | Python socket-driven integration tests (`tests_v2/` is the newer V2 API suite). |
| `scripts/` | Build/dev/release/CI helpers (`setup.sh`, `reload.sh`, `cmux-debug-cli.sh`, `bump-version.sh`, `lib/`, `ci/`). |
| `skills/` | Contributor "skills" — task-specific rules for changing each area (architecture, backend, testing, localization, ghostty, release, …). |
| `docs/` | Design specs and durable references (see [Additional documentation](#additional-documentation)). |
| `vendor/bonsplit/` | Submodule: split/tab layout engine. |
| `homebrew-cmux/` | Submodule: Homebrew cask tap. |
| `cmux.xcodeproj`, `cmux.xcworkspace` | macOS app Xcode project/workspace. |
| `dogfood/`, `experiments/`, `Prototypes/`, `plans/`, `design/` | Internal dogfood actions, spikes, prototypes, and planning notes (not shipped product). |

## Tech stack

| Area | Technology |
| ---- | ---------- |
| macOS / iOS apps | Swift 6, AppKit + SwiftUI, ~55 local SPM packages |
| Terminal core | libghostty (Zig), vendored as the `ghostty` submodule → `GhosttyKit.xcframework` |
| Command palette matching | Rust (`nucleo`) via FFI |
| Remote SSH daemon | Go (`daemon/remote`) |
| Web backend / docs | Next.js (TypeScript), bun, deployed on Vercel |
| Database | PostgreSQL via Drizzle ORM (`drizzle-kit`), local Postgres in Docker |
| Presence | Cloudflare Workers (`wrangler`) |
| Auth | Stack Auth (web), Stack-account dev sign-in for DEBUG builds |
| Billing | Stripe (`web/app/api/stripe`) |
| Auto-update | Sparkle (macOS) |
| Lint/format (web/JS) | Biome (`biome.json`) and ESLint (`web/`) |
| Build toolchain | Xcode 26.x (`.xcode-version` = `26.0`), Zig 0.15.2 (pinned), bun |

## Prerequisites

**To use the product:** macOS. Install the app from the DMG or Homebrew cask (see the root [`README.md`](../README.md)).

**For macOS-app development:**
- macOS (CI/release build on macOS 15; macOS 26+ is supported for dev — see [Building on macOS 26+](#building-on-macos-26-tahoe))
- Xcode 26.x (`.xcode-version` pins `26.0`)
- Zig (`brew install zig`) — used to build `GhosttyKit.xcframework` and the Ghostty CLI helper
- Git submodules initialized (`./scripts/setup.sh` handles this)

**For the web backend (`web/`):** bun, Docker (local Postgres), and provider/Stack secrets in `~/.secrets/` — see [`web/README.md`](../web/README.md).

**Only for specific components:** Go (`daemon/remote`), Rust/Cargo (`Native/CommandPaletteNucleoFFI`), `wrangler` (`workers/presence`).

## Quick start (build the macOS app from source)

```bash
git clone --recursive https://github.com/manaflow-ai/cmux.git
cd cmux

# One-time: init submodules, build/cache GhosttyKit, install the pbxproj pre-commit hook
./scripts/setup.sh

# Build the Debug app under an isolated tag (prints an "App path:" line; cmd-click to open)
./scripts/reload.sh --tag my-feature

# Build and launch automatically:
./scripts/reload.sh --tag my-feature --launch
```

Always build through `./scripts/reload.sh --tag <tag>`. Never run a bare `xcodebuild` or open an untagged `cmux DEV.app` — untagged builds share the default debug socket and bundle ID with other instances and steal focus. Full rationale and the tagged-socket dogfood helper (`CMUX_TAG=<tag> scripts/cmux-debug-cli.sh …`) are in [`CLAUDE.md`](../CLAUDE.md).

### Building on macOS 26+ (Tahoe)

The pinned compiler **zig 0.15.2 cannot link the Ghostty CLI helper against the macOS 26 SDK**. `reload.sh` and `scripts/build-ghostty-cli-helper.sh` auto-detect macOS 26+ and skip that one zig build, emitting a Mach-O stub so the app still builds, signs, and runs (the stub only disables the standalone `ghostty +<command>` passthrough). No env var is needed. Force the real build with `CMUX_SKIP_ZIG_BUILD=0`; the detection lives in `scripts/lib/ghostty-cli-helper-skip.sh`. Background: [issue #3047](https://github.com/manaflow-ai/cmux/issues/3047).

## Common commands

| Task | Command | Notes |
| ---- | ------- | ----- |
| One-time setup | `./scripts/setup.sh` | Submodules + GhosttyKit + git hooks |
| Build Debug app | `./scripts/reload.sh --tag <tag>` | Add `--launch` to open it |
| Build + launch Release | `./scripts/reloadp.sh` | |
| Build Debug + Release | `./scripts/reload2.sh --tag <tag>` | |
| Staging Release build | `./scripts/reloads.sh` | Isolated "cmux STAGING" |
| Compile-check only | `xcodebuild -project cmux.xcodeproj -scheme cmux -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/cmux-<tag> build` | Use a tagged derivedDataPath |
| Clean up old dev builds | `./scripts/cleanup-dev-builds.sh` | |
| Rebuild GhosttyKit | `cd ghostty && zig build -Demit-xcframework=true -Dxcframework-target=universal -Doptimize=ReleaseFast` | After ghostty submodule changes |
| Web: dev server | `cd web && bun install && bun dev` | Starts Docker Postgres + Drizzle migrations + Next.js |
| Web: tests | `cd web && bun test` | `bun run test:db:behavior` for DB tests |
| Web: typecheck / lint | `cd web && bun tsc --noEmit` / `bun run lint` | Source: `web-typecheck` CI job |
| Web: DB migrate / generate | `cd web && bun run db:migrate` / `bun run db:generate` | Drizzle |
| Web/JS lint (root) | `bun run biome:check` | Scoped via root `biome.json` |
| Presence worker tests | `cd workers/presence && bun run check` | |
| Remote daemon tests | `cd daemon/remote && go test ./...` | Go (verify against `daemon/remote/README.md`) |
| Release prep | `/release` skill → `./scripts/bump-version.sh` + tag | See [`docs` release flow](../CLAUDE.md) |

## Architecture (high level)

```
┌─────────────────────── macOS app (Swift / AppKit / SwiftUI) ───────────────────────┐
│  Sources/ + Packages/macOS/*                                                        │
│   • Terminal panes  ── GhosttyKit.xcframework (libghostty, Zig)                      │
│   • Browser panes   ── CmuxBrowser + webviews/ (WebKit, agent-browser API)           │
│   • Command palette ── Native/CommandPaletteNucleoFFI (Rust)                         │
│   • Notifications, sidebar, workspaces, splits (vendor/bonsplit)                     │
│   • Control socket (CmuxControlSocket) ◄────────── cmux CLI (CLI/, bundled binary)   │
└───────────────┬──────────────────────────────┬───────────────────────┬─────────────┘
                │ cmux ssh                       │ device sync            │ accounts/VMs
        ┌───────▼────────┐            ┌──────────▼─────────┐    ┌─────────▼──────────┐
        │ daemon/remote  │            │ workers/presence    │    │ web/ (Next.js,      │
        │ (Go, remote    │            │ (Cloudflare Worker) │    │ Postgres/Drizzle,   │
        │  tmux)         │            │                     │    │ Stack Auth, Stripe, │
        └────────────────┘            └─────────────────────┘    │ Cloud VM API)       │
                                                                  └─────────────────────┘
        iOS app (ios/) ── pairs with the Mac; shares Packages/Shared + Packages/iOS
```

The CLI and automations talk to the running app over a Unix socket (`CmuxControlSocket`); the app owns all workspace/pane state and session restore. See [`docs/state-engine-design.md`](state-engine-design.md) and [`docs/cli-contract.md`](cli-contract.md).

Package layering, dependency-inversion rules, and Swift 6 concurrency conventions are enforced via the `cmux-architecture` skill and CI checks (`scripts/check-workspace-package-groups.py`, `scripts/check-pbxproj.sh`).

## Testing

| Suite | Location | Run |
| ----- | -------- | --- |
| Swift unit tests | `cmuxTests/` | `xcodebuild ... -only-testing:cmuxTests test` (Swift Testing) |
| Swift UI tests | `cmuxUITests/` | `xcodebuild ... -only-testing:cmuxUITests test` |
| Python integration (V1) | `tests/` | Socket-driven; launch the app, then `python3 tests/test_*.py` |
| Python integration (V2) | `tests_v2/` | Newer V2 socket API; see [`docs/v2-api-migration.md`](v2-api-migration.md) |
| CI script guards | `tests/test_ci_*.sh` | Wired into the `workflow-guard-tests` job in `.github/workflows/ci.yml` |
| Web | `web/` | `bun test`, `bun run test:db:behavior` |
| Presence worker | `workers/presence/` | `bun run test` / `bun run check` |
| Remote daemon | `daemon/remote/` | `go test ./...` |

CI (`.github/workflows/ci.yml`) is the source of truth: jobs include `workflow-guard-tests`, `remote-daemon-tests`, `web-typecheck`, `react-apps-check`, `web-db-migrations`, `tests`, `tests-build-and-lag`, `release-ghostty-cli-helper`, `release-build`, and `ui-regressions`. The release helper is built on a macOS 15 runner and installed into the macOS-26-built app (see [`tests/test_ci_release_sdk_lane.sh`](../tests/test_ci_release_sdk_lane.sh)).

**Test wiring caveat:** a `.swift` file added to `cmuxTests/` must also be wired into `cmux.xcodeproj/project.pbxproj`, or Xcode silently skips it. `scripts/lint-pbxproj-test-wiring.sh` (the `workflow-guard-tests` job) catches this.

## Build, release, and deployment

- **macOS release:** use the `/release` skill (or `scripts/bump-version.sh` → `scripts/release-pretag-guard.sh` → tag `vX.Y.Z` → push). The tagged build runs `.github/workflows/release.yml`, producing `cmux-macos.dmg`. Requires Apple signing/notarization secrets. See the Release section of [`CLAUDE.md`](../CLAUDE.md) and the `cmux-release` skill.
- **Nightly:** `.github/workflows/nightly.yml` builds `cmux-nightly-macos.dmg` from `main`.
- **Web:** deployed as the Vercel `manaflow/cmux` project (`next build`); DB migrations via Drizzle. See [`web/README.md`](../web/README.md).
- **Presence worker:** `wrangler deploy` (`workers/presence`, `.github/workflows/presence.yml`).
- **iOS:** TestFlight via `.github/workflows/ios-testflight.yml`.
- **Homebrew cask:** updated via `.github/workflows/update-homebrew.yml` against the `homebrew-cmux` tap.

## Coding conventions and safe changes

- **Use the matching `skills/` skill before changing an area.** Skills encode the real rules: `cmux-architecture`, `cmux-backend`, `cmux-debugging`, `cmux-localization`, `cmux-testing`, `cmux-socket-policy`, `cmux-shared-behavior`, `cmux-ghostty`, `cmux-release`, `cmux-dev-workflow`. The pitfalls list in [`CLAUDE.md`](../CLAUDE.md) is required reading for typing-latency paths, SwiftUI list snapshot boundaries, drag-and-drop UTTypes, and submodule safety.
- **Generated / do-not-hand-edit:** `cmux.xcodeproj/project.pbxproj` is normalized by `scripts/normalize-pbxproj.py` (pre-commit hook from `setup.sh`); the root workspace is regenerated by `scripts/check-workspace-package-groups.py --write`; `GhosttyKit.xcframework/` is built, not edited.
- **Localization is mandatory for user-facing strings.** Swift strings go in `Resources/Localizable.xcstrings`; web strings in every `web/messages/*.json`. See the `cmux-localization` skill.
- **Shared behavior:** when a behavior is exposed through multiple entrypoints (shortcut, palette, menu, CLI, settings), implement one shared path. See the `cmux-shared-behavior` skill.
- **After code changes**, always rebuild with `./scripts/reload.sh --tag <tag>` and add/adjust behavior-level tests when behavior changes.
- **Submodule safety:** push submodule commits to their remote `main` before committing the updated pointer in the parent repo.

## Additional documentation

| Document | Purpose |
| -------- | ------- |
| [`CONTRIBUTING.md`](../CONTRIBUTING.md) | Local dev setup, scripts, team dogfood, ghostty workflow |
| [`CLAUDE.md`](../CLAUDE.md) (`AGENTS.md`) | Agent build notes, tagged-build rules, pitfalls, release flow |
| [`docs/cli-contract.md`](cli-contract.md) | Full `cmux` CLI + socket command contract |
| [`docs/configuration.md`](configuration.md) | `~/.config/cmux/cmux.json` settings |
| [`docs/agent-hooks.md`](agent-hooks.md) | Agent hook integrations (Claude Code, Codex, OpenCode, …) |
| [`docs/agent-browser-port-spec.md`](agent-browser-port-spec.md) | Scriptable browser API spec |
| [`docs/events.md`](events.md) | cmux event/telemetry contract |
| [`docs/notifications.md`](notifications.md) | OSC 9/99/777 notification handling |
| [`docs/remote-daemon-spec.md`](remote-daemon-spec.md) | Remote SSH/tmux daemon spec |
| [`docs/presence-service.md`](presence-service.md) | Device presence service |
| [`docs/custom-sidebars.md`](custom-sidebars.md) | Custom/vibe-coded ExtensionKit sidebars |
| [`docs/ghostty-fork.md`](ghostty-fork.md) | Ghostty fork changes & conflict notes |
| [`docs/ci-runners.md`](ci-runners.md) | CI runner topology |
| [`web/README.md`](../web/README.md), [`webviews/README.md`](../webviews/README.md), [`ios/README.md`](../ios/README.md), [`workers/presence/README.md`](../workers/presence/README.md), [`daemon/remote/README.md`](../daemon/remote/README.md) | Component READMEs |

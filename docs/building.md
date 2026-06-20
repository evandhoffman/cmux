# Building cmux (macOS quick start)

The shortest path from a fresh clone to a running cmux app.

## Prerequisites

- macOS (macOS 26 "Tahoe" is supported — see the note below)
- Xcode 26.x (pinned in [`.xcode-version`](../.xcode-version))
- Zig: `brew install zig`

## Build it (one command)

```bash
git clone --recursive https://github.com/evanwtf/cmux.git
cd cmux
./scripts/build-macos.sh
```

`build-macos.sh` takes no flags. It runs first-time setup (submodules, `GhosttyKit.xcframework`, git hooks) and builds an isolated Debug app, then prints an `App path:` line. Re-run it any time to rebuild — subsequent runs are incremental. Cloned without `--recursive`? It initializes submodules for you.

## Run it

The build prints something like:

```text
App path:
  ~/Library/Developer/Xcode/DerivedData/cmux-local/Build/Products/Debug/cmux DEV local.app
```

Cmd-click that path (or `open "<path>"`) to launch. The build is tagged `local`, so it gets its own app name, bundle id, and socket and won't collide with a release cmux. Set `CMUX_TAG=<name>` for a second isolated build.

## macOS 26 (Tahoe) note

The pinned Zig 0.15.2 can't link the Ghostty CLI helper against the macOS 26 SDK, so `build-macos.sh` auto-detects macOS 26+ and skips that one step, shipping a stub helper. The app still builds, signs, and runs normally — only the standalone `ghostty +<command>` passthrough is disabled. Nothing to configure. Force the real build with `CMUX_SKIP_ZIG_BUILD=0`. Background: [issue #3047](https://github.com/manaflow-ai/cmux/issues/3047).

## Iterative development

For ongoing work, build per branch so each gets its own isolated app:

```bash
./scripts/setup.sh                        # one-time
./scripts/reload.sh --tag <your-branch>   # build (add --launch to open)
```

Always build through `build-macos.sh` or `reload.sh --tag <tag>` — never a bare `xcodebuild` or an untagged `cmux DEV.app` (untagged builds share the default debug socket/bundle id and steal focus).

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `error: zig is not installed` | `brew install zig` |
| `error: zig 0.15.2 is required …` on macOS 26 | Expected; `build-macos.sh`/`reload.sh` auto-skip it. Building the helper directly also auto-skips. Force the real build with `CMUX_SKIP_ZIG_BUILD=0`. |
| `ghostty` submodule is empty / submodule errors | `git submodule update --init --recursive` (or just re-run `build-macos.sh`) |
| Stale or too many dev builds | `./scripts/cleanup-dev-builds.sh` |

## See also

- [`CONTRIBUTING.md`](../CONTRIBUTING.md) — full contributor setup and dev scripts
- [`docs/repository.md`](repository.md) — monorepo map, tech stack, architecture, all components

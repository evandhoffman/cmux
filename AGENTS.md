# cmux agent notes

## Initial setup

Run the setup script to initialize submodules, build GhosttyKit, and install the pbxproj normalization pre-commit hook:

```bash
./scripts/setup.sh
```

## Repository & component map

cmux is a polyglot monorepo. This file holds cross-cutting rules and covers the **macOS app** — the primary product (`Sources/`, `Packages/macOS/*`, `CLI/`, `Native/`). Each component below has its own `AGENTS.md` with component-specific commands; read it before working there.

| Area | Path | Component guide |
| ---- | ---- | --------------- |
| macOS app (primary) | `Sources/`, `Packages/macOS/*`, `CLI/`, `Native/` | this file |
| Web / cloud backend + docs site | `web/` | [`web/AGENTS.md`](web/AGENTS.md) |
| iOS app | `ios/` | [`ios/AGENTS.md`](ios/AGENTS.md) |
| Remote SSH daemon (Go) | `daemon/remote/` | [`daemon/remote/AGENTS.md`](daemon/remote/AGENTS.md) |
| Presence worker (Cloudflare) | `workers/presence/` | [`workers/presence/AGENTS.md`](workers/presence/AGENTS.md) |
| Browser / webview UIs | `webviews/` | [`webviews/AGENTS.md`](webviews/AGENTS.md) |

Full repository map, tech stack, and architecture: [`docs/repository.md`](docs/repository.md).

## Local dev

After making code changes, always run the reload script with a tag to build the Debug app:

```bash
./scripts/reload.sh --tag fix-zsh-autosuggestions
```

By default, `reload.sh` builds but does **not** launch the app. The script prints the `.app` path so the user can cmd-click to open it. After a successful build, it always terminates any running app with the same tag (so cmd-clicking launches the freshly-built binary instead of foregrounding the stale instance). Pass `--launch` to open the app automatically after the build:

```bash
./scripts/reload.sh --tag fix-zsh-autosuggestions --launch
```

### Building on macOS 26+ (Tahoe)

The pinned compiler **zig 0.15.2 cannot link the Ghostty CLI helper against the macOS 26 SDK** — its self-hosted Mach-O linker leaves every `libSystem` symbol undefined (`_abort`, `_getenv`, `_isatty`, `__availability_version_check`, …). CI and release builders run macOS 15, so this only trips on macOS 26+ dev machines (https://github.com/manaflow-ai/cmux/issues/3047).

`reload.sh` and `build-ghostty-cli-helper.sh` **auto-detect macOS 26+ and skip the helper zig build**, emitting a non-functional Mach-O stub so the app still builds, signs, and runs. The detection lives in `scripts/lib/ghostty-cli-helper-skip.sh` (shared by both scripts and the Xcode "Run Script" build phase, so a bare `xcodebuild` also works). No env var is needed on a fresh checkout. The stub only disables the standalone `ghostty +<command>` CLI passthrough; the terminal itself uses GhosttyKit, not this helper. To force the real zig build anyway (e.g. once a macOS-26-capable zig is pinned), set `CMUX_SKIP_ZIG_BUILD=0`.

`reload.sh` prints an `App path:` line with the absolute path to the built `.app`. Use that path to build a cmd-clickable `file://` URL. Steps:

1. Grab the path from the `App path:` line in `reload.sh` output.
2. Prepend `file://` and URL-encode spaces as `%20`. Do not hardcode any part of the path.
3. Format it as a markdown `file://` link.

Example. If `reload.sh` output contains:

```text
App path:
  /Users/someone/Library/Developer/Xcode/DerivedData/cmux-my-tag/Build/Products/Debug/cmux DEV my-tag.app
```

output a markdown link such as:

```markdown
[cmux DEV my-tag.app](file:///Users/someone/Library/Developer/Xcode/DerivedData/cmux-my-tag/Build/Products/Debug/cmux%20DEV%20my-tag.app)
```

If your agent UI renders only the link text and not the target, repeat the full `file://` URL inside the link text as well. Never use `/tmp/cmux-<tag>/...` app links in chat output.

For CLI or socket dogfood against a tagged Debug app, use the tag-bound helper and set `CMUX_TAG`.
Do not use `/tmp/cmux-cli` for tagged dogfood, since that symlink points at the most recently reloaded build and can target the user's main app socket.

```bash
CMUX_TAG=<tag> scripts/cmux-debug-cli.sh list-workspaces
CMUX_TAG=<tag> scripts/cmux-debug-cli.sh send --workspace workspace:1 --surface surface:1 "echo ok"
```

The helper refuses to run without `CMUX_TAG`, targets `/tmp/cmux-debug-<tag>.sock`, and uses the matching tagged CLI from `~/Library/Developer/Xcode/DerivedData/cmux-<tag>/...`. It also scrubs ambient cmux terminal context (`CMUX_SOCKET`, `CMUX_SOCKET_PASSWORD`, workspace/surface/tab/panel IDs, cmuxd socket, and debug log), then sets `CMUX_SOCKET_PATH`, `CMUX_BUNDLE_ID`, and `CMUX_BUNDLED_CLI_PATH` for the selected tag.

After making code changes, always use `reload.sh --tag` to build. **Never run bare `xcodebuild` or `open` an untagged `cmux DEV.app`.** Untagged builds share the default debug socket and bundle ID with other agents, causing conflicts and stealing focus.

```bash
./scripts/reload.sh --tag <your-branch-slug>
```

If you only need to verify the build compiles (no launch), use a tagged derivedDataPath:

```bash
xcodebuild -project cmux.xcodeproj -scheme cmux -configuration Debug -destination 'platform=macOS' -derivedDataPath /tmp/cmux-<your-tag> build
```

When rebuilding GhosttyKit.xcframework, always use Release optimizations:

```bash
cd ghostty && zig build -Demit-xcframework=true -Dxcframework-target=universal -Doptimize=ReleaseFast
```

When rebuilding cmuxd for release/bundling, always use ReleaseFast:

```bash
cd cmuxd && zig build -Doptimize=ReleaseFast
```

`reload` = build the Debug app (tag required) and terminate any running app with the same tag. Pass `--launch` to also open the freshly-built app:

```bash
./scripts/reload.sh --tag <tag>
./scripts/reload.sh --tag <tag> --launch
```

`reloadp` = kill and launch the Release app:

```bash
./scripts/reloadp.sh
```

`reloads` = kill and launch the Release app as "cmux STAGING" (isolated from production cmux):

```bash
./scripts/reloads.sh
```

`reload2` = reload both Debug and Release (tag required for Debug reload):

```bash
./scripts/reload2.sh --tag <tag>
```

For parallel/isolated builds (e.g., testing a feature alongside the main app), use `--tag` with a short descriptive name:

```bash
./scripts/reload.sh --tag fix-blur-effect
```

This creates an isolated app with its own name, bundle ID, socket, and derived data path so it runs side-by-side with the main app. Important: use a non-`/tmp` derived data path if you need xcframework resolution (the script handles this automatically).

Before launching a new tagged run, clean up any older tags you started in this session (quit old tagged app + remove its `/tmp` socket/derived data).

## Regression test commit policy

When adding a regression test for a bug fix, use a two-commit structure so CI proves the test catches the bug:

1. **Commit 1:** Add the failing test only (no fix). CI should go red.
2. **Commit 2:** Add the fix. CI should go green.

This makes it visible in the GitHub PR UI (Commits tab, check statuses) that the test genuinely fails without the fix.

## Shared behavior policy

- When a behavior is exposed through multiple entrypoints (keyboard shortcut, command palette, context menu, CLI, settings, debug menu), implement one shared action/model path and verify every entrypoint that should invoke it. Do not patch one surface while leaving the others with duplicated logic.
- For optimistic UI or CLI updates, keep one mutation path, record pending state with a request id or previous snapshot, reconcile from the authoritative result, and handle failure with an explicit rollback or error state. Do not let each entrypoint maintain its own optimistic copy.
- When a user says tests missed a bug, add or adjust behavior-level coverage around the exact repro path before claiming the fix is complete.

## Pitfalls

- **Custom UTTypes** for drag-and-drop must be declared in `Resources/Info.plist` under `UTExportedTypeDeclarations` (e.g. `com.splittabbar.tabtransfer`, `com.cmux.sidebar-tab-reorder`).
- Do not add an app-level display link or manual `ghostty_surface_draw` loop; rely on Ghostty wakeups/renderer to avoid typing lag.
- **Typing-latency-sensitive paths** (read carefully before touching these areas):
  - `WindowTerminalHostView.hitTest()` in `TerminalWindowPortal.swift`: called on every event including keyboard. All divider/sidebar/drag routing is gated to pointer events only. Do not add work outside the `isPointerEvent` guard.
  - `TabItemView` in `ContentView.swift`: uses `Equatable` conformance + `.equatable()` to skip body re-evaluation during typing. Do not add `@EnvironmentObject`, `@ObservedObject` (besides `tab`), or `@Binding` properties without updating the `==` function. Do not remove `.equatable()` from the ForEach call site. Do not read `tabManager` or `notificationStore` in the body; use the precomputed `let` parameters instead.
  - `TerminalSurface.forceRefresh()` in `GhosttyTerminalView.swift`: called on every keystroke. Do not add allocations, file I/O, or formatting here.
- **Terminal find layering contract:** `SurfaceSearchOverlay` must be mounted from `GhosttySurfaceScrollView` in `Sources/GhosttyTerminalView.swift` (AppKit portal layer), not from SwiftUI panel containers such as `Sources/Panels/TerminalPanelView.swift`. Portal-hosted terminal views can sit above SwiftUI during split/workspace churn.
- **Submodule safety:** When modifying a submodule (ghostty, vendor/bonsplit, etc.), always push the submodule commit to its remote `main` branch BEFORE committing the updated pointer in the parent repo. Never commit on a detached HEAD or temporary branch — the commit will be orphaned and lost. Verify with: `cd <submodule> && git merge-base --is-ancestor HEAD origin/main`.
- **All user-facing strings must be localized.** Use `String(localized: "key.name", defaultValue: "English text")` for every string shown in the UI (labels, buttons, menus, dialogs, tooltips, error messages). Keys go in `Resources/Localizable.xcstrings` with translations for all supported languages (currently English and Japanese). Never use bare string literals in SwiftUI `Text()`, `Button()`, alert titles, etc.
- **Localization audit is required for every user-facing change.** Before finishing a task that changes UI, Settings rows, menus, shortcut metadata, schema/config text, docs, command/help text, alerts, or tooltips, enumerate the changed user-facing surfaces and verify each one has entries for every supported locale. `defaultValue`, English fallback text, schema descriptions, or copied English strings do not count as localization. For Swift/AppKit strings, update `Resources/Localizable.xcstrings`; for localized web/docs content, update every supported message catalog (currently `web/messages/en.json` and `web/messages/ja.json`) and any localized data structures that carry inline translations. Parse touched localization files, compare changed message keys across locales, and use `rg` over changed Swift/TS/TSX/docs files for newly introduced bare English. The final handoff must state what localization audit was performed or explicitly say what could not be verified.
- **Shortcut policy:** Every new cmux-owned keyboard shortcut must be added to `KeyboardShortcutSettings`, visible/editable in Settings, supported in `~/.config/cmux/cmux.json`, and documented in the keyboard shortcut and configuration docs.
- **Snapshot boundary for list subtrees.** In any SwiftUI panel whose `body` contains a `LazyVStack` / `LazyHStack` / `List` / `ForEach` of rows, no view below that boundary may hold a reference to an `ObservableObject` / `@Observable` store (no `@ObservedObject`, `@EnvironmentObject`, `@StateObject`, `@Bindable`, or even a plain `let store: SomeStore` property). Rows and drop-gaps receive immutable value snapshots plus closure action bundles only. Violating this reintroduces the "orthogonal @Published change invalidates every row and thrashes `LazyLayoutViewCache`" class of 100% CPU spin loop that hit the Sessions panel and the workspace sidebar (https://github.com/manaflow-ai/cmux/issues/2586). Reference pattern: `IndexSectionActions` / `SectionGapActions` / `SessionSearchFn` in `Sources/SessionIndexView.swift`.
- **No state mutation inside view-body computations.** A function called from `body` (directly or through a helper) must not write `@Published` state, schedule a `Task { @MainActor in store.x = … }`, or `DispatchQueue.main.async` a store write. That creates a re-render feedback loop and pegs the main thread (same root-cause family as the snapshot-boundary rule). State-changing work triggered by "new data appeared" belongs in a `reload()` completion, a `didSet`, or a property-observer — never in the projection that feeds `ForEach`.
- **Foundation, SwiftUI, AttributeGraph, and WebKit semantics change silently between macOS major versions.** A function that "obviously" returns the same value on every macOS is not a reliable assumption. Concrete case from https://github.com/manaflow-ai/cmux/issues/4529: `URL(fileURLWithPath: "/").deletingLastPathComponent().path` returns `"/.."` on macOS 14 and 15 but `"/"` on macOS 26 — Apple silently fixed the underlying CFURL normalization. The repo's `macos-26` CI and every maintainer's dev machine were on the fixed-behavior side; every reporter on the issue was on the broken side. Always test on the reporter's macOS before declaring a user-reported repro disproven. AWS M4 Pro builders (`cmux-aws-mac`, `cmux-aws-m4pro`, `aws-m4pro-1..6`) are pre-provisioned on macOS 15.7.4 and the preferred empirical-repro path; see the `regression-hunt` skill in the cmuxterm-hq sibling repo for the full playbook.
- **Test files in `cmuxTests/` must be wired into `cmux.xcodeproj/project.pbxproj`.** A `.swift` file added to the worktree without a matching `PBXFileReference` + `PBXSourcesBuildPhase` entry is silently ignored by Xcode and never compiles or runs on CI. Both `xcodebuild test -only-testing:cmuxTests/<TestClass>` and bot reviews pass with "Executed 0 tests" — so the missing wiring is indistinguishable from a clean two-commit red/green regression test until a real user hits the bug. The `workflow-guard-tests` job runs `./scripts/lint-pbxproj-test-wiring.sh` to catch this at PR time; surfaced during the https://github.com/manaflow-ai/cmux/issues/4529 investigation against https://github.com/manaflow-ai/cmux/pull/4536. Add via Xcode (drag the file into the cmuxTests target) or hand-edit the four pbxproj entries; reference any wired sibling like `TabManagerUnitTests.swift` as a template.
- **SPM packages live in group folders, and the root workspace mirrors that folder shape exactly.** Every Swift package lives physically under exactly one group directory — `Packages/Shared/<pkg>` (used by both apps), `Packages/iOS/<pkg>` (iOS app only), or `Packages/macOS/<pkg>` (macOS app only) — and `cmux.xcworkspace/contents.xcworkspacedata` has three groups whose container locations are those folders, with every package directory appearing as a FileRef under its folder's group. So opening the workspace shows all packages grouped exactly like the directory tree. The folder is the source of truth: to move a package between groups, `git mv` its directory, then run `python3 scripts/check-workspace-package-groups.py --write` to regenerate the workspace. A new package goes in the group folder matching its consumers (both apps → Shared, iOS only → iOS, macOS only → macOS). Cross-group `.package(path:)` deps use `../../<Group>/<Name>`; never hand-edit the workspace group membership. CI's `python3 scripts/check-workspace-package-groups.py --check` fails on drift.
- **Do not ignore cmux-owned `Package.resolved` files.** SwiftPM resolution changes must be visible in PR diffs. Track the root Xcode lockfile and every cmux-owned package-local `Package.resolved` generated by standalone `swift package resolve`, `swift build`, or `swift test`; a package-local lockfile is the source of truth for that package's standalone resolution and is not replaced by `cmux.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`. Vendored third-party directories may preserve their upstream ignore policy, but cmux-owned package `.gitignore` files must not ignore `Package.resolved`. CI's `python3 scripts/check-package-resolved-policy.py` fails if this drifts.

## Ghostty submodule workflow

Ghostty changes must be committed in the `ghostty` submodule and pushed to the `manaflow-ai/ghostty` fork.
Keep `docs/ghostty-fork.md` up to date with any fork changes and conflict notes.

```bash
cd ghostty
git remote -v  # origin = upstream, manaflow = fork
git checkout -b <branch>
git add <files>
git commit -m "..."
git push manaflow <branch>
```

To keep the fork up to date with upstream:

```bash
cd ghostty
git fetch origin
git checkout main
git merge origin/main
git push manaflow main
```

Then update the parent repo with the new submodule SHA:

```bash
cd ..
git add ghostty
git commit -m "Update ghostty submodule"
```

## Release

Use the `/release` command to prepare a new release. This will:
1. Determine the new version (bumps minor by default)
2. Gather commits since the last tag and update the changelog
3. Update `CHANGELOG.md` (the docs changelog page at `web/app/docs/changelog/page.tsx` reads from it)
4. Run `./scripts/bump-version.sh` to update both versions
5. Commit, run `./scripts/release-pretag-guard.sh`, tag, and push

Version bumping:

```bash
./scripts/bump-version.sh          # bump minor (0.15.0 → 0.16.0)
./scripts/bump-version.sh patch    # bump patch (0.15.0 → 0.15.1)
./scripts/bump-version.sh major    # bump major (0.15.0 → 1.0.0)
./scripts/bump-version.sh 1.0.0    # set specific version
```

This updates both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` (build number). The build number is auto-incremented and is required for Sparkle auto-update to work.

Before creating a release tag, run:

```bash
./scripts/release-pretag-guard.sh
```

If it fails, run `./scripts/bump-version.sh`, commit the build-number bump, then retry tagging.

Manual release steps (if not using the command):

```bash
./scripts/release-pretag-guard.sh
git tag vX.Y.Z
git push origin vX.Y.Z
gh run watch --repo manaflow-ai/cmux
```

Notes:
- Requires GitHub secrets: `APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`,
  `APPLE_SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`, `APPLE_TEAM_ID`.
- The release asset is `cmux-macos.dmg` attached to the tag.
- README download button points to `releases/latest/download/cmux-macos.dmg`.
- Versioning: bump the minor version for updates unless explicitly asked otherwise.
- Changelog: update `CHANGELOG.md`; docs changelog is rendered from it.

## Skills

Detailed cmux contributor rules live in repo skills under `skills/`; use the task-specific skill before changing that area.

Core skill map:

- `cmux-dev-workflow`: setup, tagged reloads, Xcode project normalization, sidebar extension tagging, local dev build isolation.
- `cmux-architecture`: package boundaries, refactor architecture, file/API discipline, testability, Swift concurrency rules.
- `cmux-backend`: backend TypeScript, Effect, Cloud VM control plane, provider secrets, Postgres and migrations.
- `cmux-debugging`: debug event log, Debug menu, runtime pitfalls, typing-sensitive paths, SwiftUI list boundaries.
- `cmux-localization`: user-facing strings, localization files, shortcut text, and localization audit.
- `cmux-testing`: regression policy, Swift Testing, test quality, test wiring, local vs CI validation.
- `cmux-socket-policy`: socket command threading and focus preservation.
- `cmux-shared-behavior`: shared action paths for multi-entrypoint behavior and optimistic updates.
- `cmux-ghostty`: Ghostty submodule and GhosttyKit workflow.
- `cmux-release`: release, version bump, changelog, pretag guard, and release asset workflow.

## Agent Notes

This is the canonical agent guide; `CLAUDE.md` and `GEMINI.md` are symlinks to it. Keep all guidance tool-neutral so it applies to any AI coding agent — do not add tool-specific phrasing. Component `AGENTS.md` files (see [Repository & component map](#repository--component-map)) follow the same symlink convention and contain only that component's commands and conventions; cross-cutting rules stay here.

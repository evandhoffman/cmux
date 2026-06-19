# ios — agent guide

Component-specific rules for `ios/`. Cross-cutting repo rules: [`/AGENTS.md`](../AGENTS.md). Deeper detail: [`ios/README.md`](README.md), [`docs/ios-swift-mobile-plan.md`](../docs/ios-swift-mobile-plan.md).

## Overview
SwiftUI iOS/iPadOS shell for the `CMUXMobileCore` production path. Pairs with the Mac (QR/manual pairing, attach tickets) and renders workspaces/terminals synced from the desktop. Separate Xcode project (`ios/cmux-ios.xcodeproj`) and SPM package (`ios/cmuxPackage`); consumes `Packages/iOS/*` and `Packages/Shared/*`.

## Tech Stack
Swift, SwiftUI, SwiftPM, Stack Auth. No Rust/Iroh/Zig is linked into the shell.

## Commands
```bash
ios/scripts/reload.sh --tag <tag>          # build + reload the simulator (tag required)
swift test --package-path ios/cmuxPackage  # run package tests
ios/scripts/bump-ios-version.sh            # bump version/build
ios/scripts/cloud-testflight.sh            # turnkey TestFlight beta lane (cloud)
```

## Project Layout
- `cmux/` — app target; `cmuxPackage/` — SPM modules; `Config/` — build config; `scripts/` — reload/TestFlight tooling; `cmuxUITests/`.

## Code Style & Patterns
- Concrete route implementations enter through `CMUXMobileRuntime`; the byte transport is injected via `CmxByteTransportFactory` (preview host data is used when no transport is installed).
- iOS-only packages live under `Packages/iOS/`; shared logic under `Packages/Shared/` (see the `cmux-architecture` skill for package-group rules).

## Guardrails
- **Always** build through `ios/scripts/reload.sh --tag <tag>`; **never** add Rust/Iroh/Zig deps to the shell.
- **Use caution:** TestFlight/version scripts (`cloud-testflight.sh`, `bump-ios-version.sh`) affect external release state.

## Agent Notes
Symlinked to `CLAUDE.md` and `GEMINI.md`; keep guidance tool-neutral.

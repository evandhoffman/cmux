#!/usr/bin/env bash
#
# Build the cmux macOS app with a single command and no flags.
#
#   ./scripts/build-macos.sh
#
# Runs first-time setup (submodules, GhosttyKit, git hooks) and then builds an
# isolated Debug app. Safe to re-run any time to rebuild — subsequent runs are
# incremental. When the build finishes it prints an `App path:` line you can
# cmd-click to open the app.
#
# The build is tagged (default tag: `local`) so it gets its own app name,
# bundle id, socket, and derived-data path and never collides with another
# cmux instance. Override the tag with the CMUX_TAG environment variable if you
# want a second isolated build, e.g. `CMUX_TAG=experiment ./scripts/build-macos.sh`.
#
# Contributors and AI agents doing iterative work should call
# `./scripts/reload.sh --tag <tag>` directly (one tag per branch/agent) — this
# wrapper is the zero-config "just build it" entry point.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# Preflight: verify every build prerequisite is in place before doing any work,
# and report all problems at once (not just the first) with the exact fix.
preflight() {
  local problems=0

  # macOS — cmux is a native macOS app; it only builds on Darwin.
  if [ "$(uname -s)" != "Darwin" ]; then
    printf '  - cmux builds only on macOS (detected: %s)\n' "$(uname -s)" >&2
    problems=$((problems + 1))
  fi

  # Full Xcode — xcodebuild requires Xcode, not just the Command Line Tools.
  if ! /usr/bin/xcodebuild -version >/dev/null 2>&1; then
    local active_dir
    active_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    printf '  - full Xcode required; xcodebuild is unusable (active dir: %s)\n' "${active_dir:-<unset>}" >&2
    if [ -d /Applications/Xcode.app ]; then
      printf '      Xcode is installed but not selected:\n        sudo xcode-select -s /Applications/Xcode.app/Contents/Developer\n' >&2
    else
      printf '      Install Xcode 26.x (Mac App Store or https://xcodes.app), open it once to\n      accept the license, then:  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer\n' >&2
    fi
    problems=$((problems + 1))
  fi

  # Zig — used to build/cache GhosttyKit and the Ghostty CLI helper.
  if ! command -v zig >/dev/null 2>&1; then
    printf '  - zig not found:  brew install zig\n' >&2
    problems=$((problems + 1))
  fi

  # Git — required to fetch the submodules (ghostty, bonsplit, homebrew-cmux).
  if ! command -v git >/dev/null 2>&1; then
    printf '  - git not found (install the Xcode Command Line Tools, or: brew install git)\n' >&2
    problems=$((problems + 1))
  fi

  if [ "$problems" -gt 0 ]; then
    printf 'error: %d build prerequisite(s) missing — aborting before any work.\n' "$problems" >&2
    exit 1
  fi

  printf '==> Preflight OK (%s, zig %s, git present)\n' \
    "$(/usr/bin/xcodebuild -version 2>/dev/null | head -1 || true)" \
    "$(zig version 2>/dev/null || true)"
}

preflight

# One-time setup (idempotent): initialize submodules, build/cache
# GhosttyKit.xcframework, and install the pbxproj pre-commit hook. Re-running is
# cheap — initialized submodules and a warm GhosttyKit cache are no-ops.
"$SCRIPT_DIR/setup.sh"

# Build the Debug app under a stable tag. reload.sh handles the macOS 26+ zig
# auto-skip and prints the App path on success.
exec "$SCRIPT_DIR/reload.sh" --tag "${CMUX_TAG:-local}"

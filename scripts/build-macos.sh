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

# Building needs a full Xcode, not just the Command Line Tools. Without it the
# build fails deep inside reload.sh with a cryptic xcode-select error, so check
# up front and tell the user exactly what to do.
if ! /usr/bin/xcodebuild -version >/dev/null 2>&1; then
  active_dir="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
  {
    echo "error: building cmux requires a full Xcode, but 'xcodebuild' is not usable."
    echo "  active developer directory: ${active_dir:-<unset>}"
    if [ -d /Applications/Xcode.app ]; then
      echo "  Xcode is installed but not selected. Point the toolchain at it:"
      echo "    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    else
      echo "  Install Xcode 26.x (Mac App Store or https://xcodes.app), open it once"
      echo "  to accept the license, then select it:"
      echo "    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    fi
    echo "  (The Command Line Tools alone cannot run xcodebuild.)"
  } >&2
  exit 1
fi

# One-time setup (idempotent): initialize submodules, build/cache
# GhosttyKit.xcframework, and install the pbxproj pre-commit hook. Re-running is
# cheap — initialized submodules and a warm GhosttyKit cache are no-ops.
"$SCRIPT_DIR/setup.sh"

# Build the Debug app under a stable tag. reload.sh handles the macOS 26+ zig
# auto-skip and prints the App path on success.
exec "$SCRIPT_DIR/reload.sh" --tag "${CMUX_TAG:-local}"

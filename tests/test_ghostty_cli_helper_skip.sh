#!/usr/bin/env bash
# Regression test for https://github.com/manaflow-ai/cmux/issues/3047.
# The pinned zig 0.15.2 cannot link the Ghostty CLI helper against the macOS 26+
# SDK, so reload.sh and build-ghostty-cli-helper.sh must auto-skip the zig build
# (emit a Mach-O stub) on macOS 26+ while still building normally on macOS 15 and
# Linux CI. This exercises the shared decision function with explicit inputs so it
# runs anywhere, including the Linux workflow-guard-tests runner.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=scripts/lib/ghostty-cli-helper-skip.sh
source "$ROOT_DIR/scripts/lib/ghostty-cli-helper-skip.sh"

fail() {
  echo "FAIL: $1"
  exit 1
}

# Returns "skip" or "build" for a given (os, macos_major, zig) tuple.
decide() {
  if cmux_zig_cli_helper_link_unsupported "$1" "$2" "$3"; then
    echo "skip"
  else
    echo "build"
  fi
}

assert() {
  local desc="$1" expected="$2" actual="$3"
  [[ "$actual" == "$expected" ]] || fail "$desc: expected '$expected', got '$actual'"
}

# macOS 26+ with the pinned 0.15.2 toolchain must skip (the failing case).
assert "macOS 26 + zig 0.15.2 skips"      skip  "$(decide Darwin 26 0.15.2)"
assert "macOS 27 + zig 0.15.2 skips"      skip  "$(decide Darwin 27 0.15.2)"
assert "macOS 100 + zig 0.15.2 skips"     skip  "$(decide Darwin 100 0.15.2)"

# macOS 15 (CI / release lane) and older must still build the real helper.
assert "macOS 15 + zig 0.15.2 builds"     build "$(decide Darwin 15 0.15.2)"
assert "macOS 14 + zig 0.15.2 builds"     build "$(decide Darwin 14 0.15.2)"

# A future pin that links on macOS 26 should build, not silently stub.
assert "macOS 26 + zig 0.16.0 builds"     build "$(decide Darwin 26 0.16.0)"

# Non-macOS hosts (Linux CI) never auto-skip.
assert "Linux + zig 0.15.2 builds"        build "$(decide Linux 26 0.15.2)"

# Malformed / empty version inputs fall back to building rather than skipping.
assert "empty major builds"               build "$(decide Darwin '' 0.15.2)"
assert "non-numeric major builds"         build "$(decide Darwin '26.5' 0.15.2)"

# The host wrapper must not throw and must agree with the host's real OS:
# on Linux CI it should report build; on macOS its result must match the host
# major version decision. cmux_host_macos_major must never error under set -e.
host_major="$(cmux_host_macos_major)"
if cmux_should_auto_skip_ghostty_zig_build; then host_decision="skip"; else host_decision="build"; fi
assert "host wrapper matches pure decision" \
  "$(decide "$(uname -s)" "${host_major:-none}" 0.15.2)" "$host_decision"

echo "PASS: Ghostty CLI helper zig-build auto-skip honors macOS 26+ (#3047)"

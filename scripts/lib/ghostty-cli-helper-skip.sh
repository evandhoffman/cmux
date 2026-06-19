#!/usr/bin/env bash
# Shared detection for whether the Ghostty CLI helper zig build must be skipped.
#
# The pinned compiler (zig 0.15.2) cannot link the helper against the macOS 26+
# SDK: its self-hosted Mach-O linker leaves every libSystem symbol undefined
# (_abort, _getenv, _isatty, __availability_version_check, ...). zig 0.16.0 links
# fine but is not the pinned source-compatible toolchain. macOS 15 dev machines
# and CI/release builders are unaffected, so this only trips on macOS 26+ hosts.
# When it trips, callers fall back to the Mach-O stub that
# build-ghostty-cli-helper.sh already emits for CMUX_SKIP_ZIG_BUILD=1.
#
# See https://github.com/manaflow-ai/cmux/issues/3047.
#
# This file is meant to be sourced; it defines functions only.

# Pure decision: given an OS kernel name (uname -s), a macOS major version, and
# the required zig version, return 0 (true) when that combination cannot link the
# Ghostty CLI helper. Kept fully argument-driven so it is unit-testable on any
# host, including Linux CI runners.
cmux_zig_cli_helper_link_unsupported() {
  local os_kernel="$1"
  local macos_major="$2"
  local zig_required="$3"
  [[ "$os_kernel" == "Darwin" ]] || return 1
  # Only the pinned 0.15.2 toolchain is affected; a future pin that links on
  # macOS 26 should build normally.
  [[ "$zig_required" == "0.15.2" ]] || return 1
  [[ "$macos_major" =~ ^[0-9]+$ ]] || return 1
  (( macos_major >= 26 ))
}

# Host macOS major version (e.g. "26"), or empty when not on macOS / unknown.
cmux_host_macos_major() {
  [[ "$(uname -s)" == "Darwin" ]] || return 0
  local product
  product="$(sw_vers -productVersion 2>/dev/null || true)"
  [[ -n "$product" ]] || return 0
  printf '%s\n' "${product%%.*}"
}

# Convenience wrapper that inspects the real host. Pass the required zig version
# (defaults to 0.15.2). Returns 0 when the helper zig build should auto-skip.
cmux_should_auto_skip_ghostty_zig_build() {
  local zig_required="${1:-0.15.2}"
  cmux_zig_cli_helper_link_unsupported "$(uname -s)" "$(cmux_host_macos_major)" "$zig_required"
}

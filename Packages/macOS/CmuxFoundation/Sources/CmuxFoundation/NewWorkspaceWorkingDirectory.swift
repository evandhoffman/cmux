import Foundation

/// Resolves the working directory used to seed a new workspace, honoring the
/// optional `app.defaultWorkspacePath` setting.
///
/// Pure and dependency-injected (no direct filesystem / environment access) so
/// the precedence and path-expansion rules are unit-testable in isolation.
///
/// Precedence:
/// 1. `configuredDefault` (`app.defaultWorkspacePath`) — if set and it resolves
///    to an existing directory, use it (expanding `~` and `$VAR`/`${VAR}`).
/// 2. otherwise `inheritedDirectory` — the existing "inherit the current
///    workspace's working directory" behavior (already `nil` when that toggle
///    is off).
/// 3. if `configuredDefault` is set but does not resolve to an existing
///    directory, fall back to `inheritedDirectory` (else `homeDirectory`) and
///    flag the invalid path so callers can surface a non-blocking warning.
public enum NewWorkspaceWorkingDirectory {
    public struct Resolution: Equatable, Sendable {
        /// The directory to seed the new workspace with, or `nil` to leave it
        /// unset (downstream/Ghostty `working-directory` default applies).
        public let directory: String?
        /// `true` when `configuredDefault` was non-empty but did not resolve to
        /// an existing directory, so the resolver fell back.
        public let configuredPathInvalid: Bool

        public init(directory: String?, configuredPathInvalid: Bool) {
            self.directory = directory
            self.configuredPathInvalid = configuredPathInvalid
        }
    }

    public static func resolve(
        configuredDefault: String,
        inheritedDirectory: String?,
        homeDirectory: String,
        environment: [String: String],
        directoryExists: (String) -> Bool
    ) -> Resolution {
        // STUB (TDD commit 1): ignores `configuredDefault`. Replaced with the
        // real precedence/expansion logic in the follow-up commit.
        Resolution(directory: inheritedDirectory, configuredPathInvalid: false)
    }

    /// Expands a leading `~`/`~/` and `$VAR` / `${VAR}` references in `path`.
    public static func expand(
        _ path: String,
        homeDirectory: String,
        environment: [String: String]
    ) -> String {
        // STUB (TDD commit 1): real expansion added in the follow-up commit.
        path
    }
}

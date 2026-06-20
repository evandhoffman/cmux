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
        let trimmed = configuredDefault.trimmingCharacters(in: .whitespacesAndNewlines)
        // Unset: preserve the existing inherited / last-used behavior exactly.
        guard !trimmed.isEmpty else {
            return Resolution(directory: inheritedDirectory, configuredPathInvalid: false)
        }
        let expanded = expand(trimmed, homeDirectory: homeDirectory, environment: environment)
        if directoryExists(expanded) {
            return Resolution(directory: expanded, configuredPathInvalid: false)
        }
        // Configured but not an existing directory: fall back to the last-used
        // directory (else home) and flag it so callers can warn non-blockingly.
        return Resolution(
            directory: inheritedDirectory ?? homeDirectory,
            configuredPathInvalid: true
        )
    }

    /// Expands a leading `~`/`~/` and `$VAR` / `${VAR}` references in `path`.
    public static func expand(
        _ path: String,
        homeDirectory: String,
        environment: [String: String]
    ) -> String {
        var result = expandEnvironment(path, environment: environment)
        if result == "~" {
            result = homeDirectory
        } else if result.hasPrefix("~/") {
            result = homeDirectory + result.dropFirst()
        }
        return result
    }

    /// Replaces `${VAR}` and `$VAR` (where `VAR` matches `[A-Za-z_][A-Za-z0-9_]*`)
    /// with values from `environment`. Unknown variables expand to empty, and a
    /// lone `$` or `$` followed by a non-identifier is left untouched.
    private static func expandEnvironment(
        _ path: String,
        environment: [String: String]
    ) -> String {
        guard path.contains("$") else { return path }
        var result = ""
        let scalars = Array(path)
        var i = 0
        func isNameStart(_ c: Character) -> Bool { c == "_" || c.isLetter }
        func isNameBody(_ c: Character) -> Bool { c == "_" || c.isLetter || c.isNumber }
        while i < scalars.count {
            let c = scalars[i]
            guard c == "$", i + 1 < scalars.count else {
                result.append(c)
                i += 1
                continue
            }
            let next = scalars[i + 1]
            if next == "{" {
                // ${VAR}
                if let close = scalars[(i + 2)...].firstIndex(of: "}") {
                    let name = String(scalars[(i + 2)..<close])
                    result += environment[name] ?? ""
                    i = close + 1
                    continue
                }
                result.append(c)
                i += 1
            } else if isNameStart(next) {
                // $VAR
                var j = i + 1
                while j < scalars.count, isNameBody(scalars[j]) { j += 1 }
                let name = String(scalars[(i + 1)..<j])
                result += environment[name] ?? ""
                i = j
            } else {
                result.append(c)
                i += 1
            }
        }
        return result
    }
}

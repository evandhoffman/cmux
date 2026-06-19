import Testing

@testable import CmuxFoundation

/// Regression coverage for the `app.defaultWorkspacePath` setting
/// (evandhoffman/cmux#4): a configured default working directory must take
/// precedence over the inherited "last used" directory for new workspaces.
@Suite struct NewWorkspaceWorkingDirectoryTests {
    private let home = "/Users/tester"
    private let env = ["WORK": "/Users/tester/work", "EMPTY": ""]

    private func resolve(
        configured: String,
        inherited: String?,
        existing: Set<String>
    ) -> NewWorkspaceWorkingDirectory.Resolution {
        NewWorkspaceWorkingDirectory.resolve(
            configuredDefault: configured,
            inheritedDirectory: inherited,
            homeDirectory: home,
            environment: env,
            directoryExists: { existing.contains($0) }
        )
    }

    // MARK: unset → existing behavior preserved

    @Test func unsetWithInheritedReturnsInherited() {
        let r = resolve(configured: "", inherited: "/Users/tester/project-a", existing: [])
        #expect(r.directory == "/Users/tester/project-a")
        #expect(r.configuredPathInvalid == false)
    }

    @Test func unsetWithoutInheritedReturnsNil() {
        let r = resolve(configured: "", inherited: nil, existing: [])
        #expect(r.directory == nil)
        #expect(r.configuredPathInvalid == false)
    }

    @Test func whitespaceOnlyTreatedAsUnset() {
        let r = resolve(configured: "   ", inherited: "/Users/tester/project-a", existing: [])
        #expect(r.directory == "/Users/tester/project-a")
        #expect(r.configuredPathInvalid == false)
    }

    // MARK: configured & valid → wins over inherited

    @Test func validConfiguredOverridesInherited() {
        let r = resolve(
            configured: "/Users/tester/workspace",
            inherited: "/Users/tester/project-a",
            existing: ["/Users/tester/workspace"]
        )
        #expect(r.directory == "/Users/tester/workspace")
        #expect(r.configuredPathInvalid == false)
    }

    @Test func tildeIsExpanded() {
        let r = resolve(
            configured: "~/workspace",
            inherited: nil,
            existing: ["/Users/tester/workspace"]
        )
        #expect(r.directory == "/Users/tester/workspace")
        #expect(r.configuredPathInvalid == false)
    }

    @Test func bareTildeExpandsToHome() {
        let r = resolve(configured: "~", inherited: nil, existing: [home])
        #expect(r.directory == home)
    }

    @Test func dollarVarIsExpanded() {
        let r = resolve(
            configured: "$WORK",
            inherited: nil,
            existing: ["/Users/tester/work"]
        )
        #expect(r.directory == "/Users/tester/work")
    }

    @Test func bracedVarIsExpanded() {
        let r = resolve(
            configured: "${WORK}/sub",
            inherited: nil,
            existing: ["/Users/tester/work/sub"]
        )
        #expect(r.directory == "/Users/tester/work/sub")
    }

    // MARK: configured but invalid → fall back + flag

    @Test func invalidConfiguredFallsBackToInherited() {
        let r = resolve(
            configured: "/does/not/exist",
            inherited: "/Users/tester/project-a",
            existing: ["/Users/tester/project-a"]
        )
        #expect(r.directory == "/Users/tester/project-a")
        #expect(r.configuredPathInvalid == true)
    }

    @Test func invalidConfiguredWithoutInheritedFallsBackToHome() {
        let r = resolve(configured: "/does/not/exist", inherited: nil, existing: [])
        #expect(r.directory == home)
        #expect(r.configuredPathInvalid == true)
    }

    // MARK: expand() direct

    @Test func expandLeavesPlainPathUnchanged() {
        #expect(
            NewWorkspaceWorkingDirectory.expand("/abs/path", homeDirectory: home, environment: env)
                == "/abs/path"
        )
    }

    @Test func expandResolvesNestedTildeAndVar() {
        #expect(
            NewWorkspaceWorkingDirectory.expand("~/code", homeDirectory: home, environment: env)
                == "/Users/tester/code"
        )
        #expect(
            NewWorkspaceWorkingDirectory.expand("${WORK}", homeDirectory: home, environment: env)
                == "/Users/tester/work"
        )
    }
}

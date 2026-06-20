# Session restore

Quitting cmux saves the current session. On relaunch, cmux restores app-owned
state:
- Window/workspace/pane layout
- Working directories
- Terminal scrollback (best effort)
- Browser URL and navigation history

cmux does not checkpoint arbitrary live process state. tmux, vim, shells, and
unsupported terminal apps reopen as normal terminals.

Supported agent sessions can resume when hooks have saved a native session ID.
Install hooks after installing the agent CLI so its binary is on `PATH`:

```bash
cmux hooks setup
cmux hooks setup codex
cmux hooks setup --agent opencode
```

`cmux hooks setup` installs supported agents it can find and prints a summary
for skipped agents. Supported resume integrations include Claude Code, Codex,
Grok, OpenCode, Pi, Amp, Cursor CLI, Gemini, Rovo Dev, Copilot, CodeBuddy,
Factory, and Qoder. Claude Code is handled by the cmux Claude wrapper when Claude
integration is enabled in Settings.

Advanced users and integrations can attach a custom resume command to the
current terminal surface. This is useful for tools with their own durable state,
such as tmux sessions or custom agent CLIs:

```bash
cmux surface resume set --kind tmux --checkpoint work --shell "tmux attach -t work"
cmux surface resume show --json
cmux surface resume clear --checkpoint work
```

The binding stays attached to the cmux surface. Public CLI or socket-created
bindings are stored for inspection and manual restore unless you approve a
signed command prefix for automatic restore. Approved prefixes are also bound to
the working directory and exact environment values, when present. Review or edit
approvals in **Settings > Terminal > Resume Commands**. cmux only auto-runs
resume bindings it marks trusted, such as live process-detected tmux bindings or
user-approved prefixes. Sensitive environment keys such as tokens, passwords,
secrets, and API keys are dropped before a resume binding is stored.

To keep restored agent terminals idle instead of automatically running their resume commands,
turn off **Settings > Terminal > Resume Agent Sessions on Reopen** or set this in
`~/.config/cmux/cmux.json`:

```json
{
  "terminal": {
    "autoResumeAgentSessions": false
  }
}
```

This only disables automatic agent resume commands. cmux still restores the saved layout,
working directories, scrollback, and browser history.

If you need to reapply the last saved snapshot manually, use:
- `File > Reopen Previous Session`
- `⌘ ⇧ O`
- `cmux restore-session`

Under the hood, cmux writes a versioned snapshot under
`~/Library/Application Support/cmux/` and agent hooks write session mappings
under `~/.cmuxterm/`. On restore, cmux rebuilds the layout first, then runs the
supported agent's native resume command when automatic agent resume is enabled.

Read the full guide at <https://cmux.com/docs/session-restore>.

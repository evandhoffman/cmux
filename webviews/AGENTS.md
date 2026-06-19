# webviews — agent guide

Component-specific rules for `webviews/`. Cross-cutting repo rules: [`/AGENTS.md`](../AGENTS.md). Deeper detail: [`webviews/README.md`](README.md), [`docs/agent-browser-port-spec.md`](../docs/agent-browser-port-spec.md).

## Overview
`@cmux/webviews`: TypeScript/React web UIs bundled into the macOS app and served in WebKit surfaces (browser panes, agent-session views). The agent-session bundle is built from `webviews/src/agent-session`.

## Tech Stack
TypeScript, React, Vite, bun, TanStack Router, oxlint.

## Commands
```bash
bun install
bun run build        # verify:tanstack-router → typecheck → vite build
bun test             # bun test
bun run typecheck    # tsc --noEmit
bun run lint         # oxlint (react / jsx-a11y / import plugins)
```
From the repo root: `bun run agent-session-web:build` (→ `scripts/build-agent-session-web.sh`) and `bun run agent-session-web:test`.

## Project Layout
- `src/` — UIs (incl. `src/agent-session/`); `test/`; `scripts/verify-tanstack-router-security.mjs`; `vite.config.mjs`; lockfile `bun.lock`.

## Code Style & Patterns
- Lint with oxlint (not ESLint/Biome here).
- `bun run build` gates on `verify:tanstack-router` (a security check) and `typecheck`; keep both passing.
- React surfaces are also checked by the `react-apps-check` CI job; some run the React Compiler (`scripts/check-webviews-react-compiler.mjs`).

## Agent Notes
Symlinked to `CLAUDE.md` and `GEMINI.md`; keep guidance tool-neutral.

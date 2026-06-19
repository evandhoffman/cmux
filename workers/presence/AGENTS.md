# workers/presence — agent guide

Component-specific rules for `workers/presence/`. Cross-cutting repo rules: [`/AGENTS.md`](../../AGENTS.md). Deeper detail: [`workers/presence/README.md`](README.md), [`docs/presence-service.md`](../../docs/presence-service.md).

## Overview
`cmux-presence-worker`: a Cloudflare Worker that tracks device presence (which of a user's devices are online) for cross-device features.

## Tech Stack
TypeScript, bun, Cloudflare Workers (`wrangler`). Config in `wrangler.toml`.

## Commands
```bash
bun install
bun run dev          # wrangler dev (local)
bun test             # bun test
bun run typecheck    # tsc --noEmit (app + test tsconfig)
bun run check        # typecheck + test + `wrangler deploy --dry-run` (run before deploy)
bun run deploy       # wrangler deploy — PRODUCTION
```

## Project Layout
- `src/` — worker source; `test/` — tests; `wrangler.toml` — Worker config; lockfile `bun.lock`.

## Guardrails
- **Always** run `bun run check` before deploying.
- **Use caution / destructive:** `bun run deploy` ships to production Cloudflare. CI deploy is `.github/workflows/presence.yml`.

## Agent Notes
Symlinked to `CLAUDE.md` and `GEMINI.md`; keep guidance tool-neutral.

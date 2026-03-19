# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**PureSimple** is a lightweight web framework for PureBasic 6.x, inspired by Go's Gin and Chi frameworks. It compiles into a single native binary with zero external runtime dependencies. The framework sits between PureSimpleHTTPServer (HTTP engine) and the application layer, providing routing, middleware, request binding, and response rendering.

## Three-Repository Ecosystem

| Repo | Role | Status |
|------|------|--------|
| `PureSimpleHTTPServer` | HTTP/1.1 listener, TLS, compression, static files | Production v1.x |
| `PureJinja` | Jinja2-compatible template engine (35 filters, 599 tests) | Production v1.4.0 |
| `PureSimple` | Router, middleware, context, binding, rendering | **This repo** v0.x |

Integration pattern: `main.pb` includes PureSimpleHTTPServer and registers PureSimple's dispatch callback as the request handler. PureSimple calls PureJinja's `CreateEnvironment/RenderString/FreeEnvironment` API for HTML rendering. All three compile into one binary.

## Build Commands

```bash
# Compile the framework test suite (console binary required for test output)
$PUREBASIC_HOME/compilers/pbcompiler tests/run_all.pb -cl -o run_all

# Run tests
./run_all

# Compile an example app
$PUREBASIC_HOME/compilers/pbcompiler examples/hello_world/main.pb -o hello_world

# Syntax check only (no output binary)
$PUREBASIC_HOME/compilers/pbcompiler -k src/PureSimple.pb

# Release build (with optimizer)
$PUREBASIC_HOME/compilers/pbcompiler src/main.pb -z -o app

# macOS compiler path
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"
```

## Project Structure

```
PureSimple/
  src/               # Framework source (.pb entry point, .pbi modules)
  tests/             # Test files; run_all.pb is the test runner entry point
  examples/          # Runnable example apps (hello_world, todo, blog)
  docs/              # Design docs and API reference
  resources/         # common-pitfalls.md, purebasic help references
  scripts/
    deploy.sh        # Local → server deploy pipeline (SSH, compile, swap, health check)
    rollback.sh      # Emergency rollback (swap app.bak, restart)
  deploy/
    Caddyfile        # Caddy reverse proxy config (→ /etc/caddy/Caddyfile)
    puresimple.service  # systemd unit file
    setup-server.sh  # One-time server provisioning
  templates/         # Default Jinja2 HTML templates (404.html, 500.html)
  CHANGELOG.md
  CLAUDE.md
  README.md
```

## Architecture

### Request Lifecycle

```
PureSimpleHTTPServer → dispatch callback
  → Router.Match(method, path) → handler chain + params
  → combineHandlers(global middleware + group middleware + route handler)
  → Context.Next() iterates handler chain
  → Renderers write response (JSON/HTML/File/Redirect)
  → PureSimpleHTTPServer sends response
```

### Core Abstractions

- **HandlerFunc**: `Procedure(*ctx.RequestContext)` — universal handler and middleware signature
- **RequestContext**: Per-request struct — holds raw request/response data, params map, query map, KV store, handlers array, handlerIndex, aborted flag. Pre-allocated per thread slot and reset (not reallocated) per request.
- **Router**: One route table per HTTP method. Radix trie with `:param` named segments and `*wildcard` support.
- **Middleware chain**: `Ctx::Advance()` increments handlerIndex and calls the next handler (note: `Next` is a reserved PureBasic keyword); `Ctx::Abort()` sets the aborted flag. `combineHandlers()` merges group + route handlers into one flat array.
- **RouterGroup**: Sub-router with shared path prefix and middleware. Groups nest: `app.Group('/api').Group('/v1').GET('/users', handler)`.

### Include File Pattern

All modules are `.pbi` files included via `XIncludeFile` (never `IncludeFile`). Include order in `src/PureSimple.pb`:
1. `Types.pbi` — `DeclareModule Types` wrapping `RequestContext`, `PS_HandlerFunc`, `RouterEngine`
2. `UseModule Types` — at program level so test files and main code see types without `Types::` prefix
3. `Router.pbi` — segment trie + route table (`Router::Insert`, `Router::Match`)
4. `Context.pbi` — RequestContext lifecycle (`Ctx::Init`, `Ctx::Advance`, `Ctx::Abort`, `Ctx::Param`, `Ctx::Set`/`Get`)
5. `Middleware/*.pbi` — Logger, Recovery, Auth, CSRF, Session
6. `Binding.pbi` — Param, Query, BindJSON, PostForm, FormFile
7. `Rendering.pbi` — JSON, HTML, File, Redirect
8. `DB/SQLite.pbi` — DB adapter + query helpers + migration runner
9. `Engine.pbi` — NewApp(), Run(), Use(), Group(), Static()

## PureBasic Conventions

- **Always use `EnableExplicit`** at the top of every file — no exceptions.
- **Always use `Protected`** for procedure-local variables.
- **Prefer `XIncludeFile`** over `IncludeFile` to prevent duplicate definition errors.
- **Use `#PB_Any`** for dynamic IDs and always capture the return value: `id = CreateThing(#PB_Any, ...)`.
- **Use Modules** (`DeclareModule` / `Module`) for all framework namespaces to avoid identifier conflicts.
- **Module bodies are isolated**: `Module` bodies cannot see main-code globals (including structures). Wrap shared types in a `DeclareModule`/`Module` (e.g., `Module Types`) and add `UseModule Types` at the top of each consuming module body.
- **`Next` is a reserved keyword**: PureBasic uses `Next` to close `For…Next` loops. The handler-chain "advance" method is named `Ctx::Advance` in this framework.
- **File existence**: use `FileSize(path) >= 0` — there is no `FileExists()`.
- **`Dim a(N)`** creates N+1 elements (indices 0 to N inclusive).
- **`.i` type** is pointer-sized (4 bytes x86, 8 bytes x64) — use for IDs, handles, loop counters.
- **Strings use `~"..."` prefix** for escape sequences (`\n`, `\t`).
- **Thread safety** requires `pbcompiler -t` flag when using threads.

## Git & Phase Workflow

Every phase follows this workflow:
```bash
git checkout -b feature/P{N}-{short-name}
# implement + tests
git add src/ tests/ docs/ *.md
git commit -m "P{N}: description"
git push origin feature/P{N}-{short-name}
# PR → self-review → merge → delete branch
git tag v0.{N}.0 && git push --tags
./scripts/deploy.sh
```

Commit message prefix convention: `P0:`, `P1:`, ..., `P10:` matching the phase.

## Deployment

**Production server**: `129.212.236.80` — Ubuntu 24, SSH `root@` port 22, ed25519 key at `~/.ssh/id_ed25519`

```bash
./scripts/deploy.sh   # full pipeline: pull → compile → stop → swap → migrate → start → health check
./scripts/rollback.sh # emergency: stop → swap app.bak → start → health check
```

The app runs as `www-data` under systemd (`/opt/puresimple/app`). Caddy handles HTTPS and proxies to `localhost:8080`. Health check endpoint: `GET /health` → 200 OK.

## Phase Roadmap (current status: P0)

| Phase | Deliverable | Branch pattern |
|-------|-------------|----------------|
| P0 | Project foundation, test harness, deploy scripts | `feature/P0-*` |
| P1 | Core router + Context | `feature/P1-*` |
| P2 | Middleware engine (Next, Abort, Logger, Recovery) | `feature/P2-*` |
| P3 | Request binding (Param, Query, JSON, Form, File) | `feature/P3-*` |
| P4 | Response rendering + PureJinja integration | `feature/P4-*` |
| P5 | Route groups + structured error handling | `feature/P5-*` |
| P6 | SQLite3 integration + migrations | `feature/P6-*` |
| P7 | Sessions, cookies, BasicAuth, CSRF | `feature/P7-*` |
| P8 | Logging, .env config, run modes, scaffold | `feature/P8-*` |
| P9 | Documentation + example apps + book outline | `feature/P9-*` |
| P10 | Multi-DB abstraction (PostgreSQL, MySQL) | `feature/P10-*` |

## Test Harness

The test runner (`tests/run_all.pb`) uses macro-based assertions:
```purebasic
Check(expr)            ; fails if expr is #False
CheckEqual(a, b)       ; fails if a <> b (numeric)
CheckStr(a, b)         ; fails if a <> b (string comparison)
```
Note: PureBasic 6.x pre-defines `Assert()` and `AssertString()` as built-in halt-on-fail macros
(from `pureunit.res`). The harness uses `Check`/`CheckEqual`/`CheckStr` to avoid those conflicts
and to support count-and-continue reporting (all failures shown, not just the first).

Every phase's tests must all pass before merging. All previously passing tests must continue to pass (no regressions).

## End-of-Phase Documentation Updates

After every phase, update:
- `README.md` — add newly implemented features to the feature list
- `CHANGELOG.md` — add entry for the new version tag
- `CLAUDE.md` — update this file if architecture or conventions changed
- `resources/common-pitfalls.md` — add any new PureBasic gotchas discovered

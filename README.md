# PureSimple

A lightweight web framework for **PureBasic 6.x**, inspired by Go's Gin and Chi. Compiles to a single native binary with zero external runtime dependencies.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Status: P1 Router + Context](https://img.shields.io/badge/status-P1%20Router%20%2B%20Context-yellow)

---

## Architecture

```
┌──────────────────────────────────────────────────┐
│                  Your Application                │
│          routes, handlers, templates             │
└────────────────────┬─────────────────────────────┘
                     │
┌────────────────────▼─────────────────────────────┐
│                  PureSimple                      │
│  Router · Middleware · Context · Binding         │
│  Rendering · Groups · Sessions · DB              │
└─────────┬────────────────────┬───────────────────┘
          │                    │
┌─────────▼──────┐  ┌──────────▼───────────────────┐
│PureSimple      │  │PureJinja                      │
│HTTPServer      │  │Jinja2-compatible templates    │
│HTTP/1.1, TLS,  │  │35 filters · 599 tests         │
│compression,    │  │v1.4.0                         │
│static files    │  └──────────────────────────────┘
│v1.x            │
└────────────────┘
        │
        ▼
  Single native binary (no runtime deps)
```

All three repos compile into **one binary**. No interpreter, no VM, no shared libraries required at runtime.

---

## Three-Repo Ecosystem

| Repo | Role |
|------|------|
| [`PureSimpleHTTPServer`](https://github.com/your-org/PureSimpleHTTPServer) | HTTP/1.1 listener, TLS, compression, static files |
| [`PureJinja`](https://github.com/your-org/PureJinja) | Jinja2-compatible template engine |
| **`PureSimple`** ← you are here | Router, middleware, context, binding, rendering |

---

## Build Instructions

```bash
# Set PureBasic home (macOS example)
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"

# Compile and run the test suite
$PUREBASIC_HOME/compilers/pbcompiler tests/run_all.pb -cl -o run_all
./run_all

# Syntax-check the framework without producing a binary
$PUREBASIC_HOME/compilers/pbcompiler -k src/PureSimple.pb

# Compile and run the hello_world example
$PUREBASIC_HOME/compilers/pbcompiler examples/hello_world/main.pb -cl -o hello_world
./hello_world

# Release build (with optimizer)
$PUREBASIC_HOME/compilers/pbcompiler src/main.pb -z -o app
```

---

## Request Lifecycle

```
PureSimpleHTTPServer → dispatch callback
  → Router.Match(method, path)  →  handler chain + params
  → combineHandlers(global middleware + group middleware + route handler)
  → Context.Advance() iterates handler chain (Gin-style)
  → Renderers write response (JSON / HTML / File / Redirect)
  → PureSimpleHTTPServer sends response
```

---

## Project Structure

```
PureSimple/
  src/               # Framework source (.pb entry point, .pbi modules)
  tests/             # Test harness + per-phase test files
  examples/          # Runnable example apps (hello_world, todo, blog)
  docs/              # Design docs and API reference
  resources/         # common-pitfalls.md, PureBasic references
  scripts/
    deploy.sh        # Local → server deploy pipeline
    rollback.sh      # Emergency rollback
  deploy/
    Caddyfile        # Caddy reverse proxy config
    puresimple.service  # systemd unit
    setup-server.sh  # One-time server provisioning
  templates/         # Default Jinja2 HTML templates (404.html, 500.html)
```

---

## Features (P1)

### Router
- Segment-level trie with `:param` named capture and `*wildcard` catch-all segments
- Per-method route tables (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, and `Any`)
- Priority order: exact match > `:param` > `*wildcard`
- Route registration: `Engine::GET(pattern, @handler())`

### Context
- `RequestContext` — per-request struct with method, path, params, query, KV store, handler chain
- `Ctx::Init` / `Ctx::Dispatch` — initialise and start a request
- `Ctx::Advance(*C)` — Gin-style handler chain advance (passes control downstream)
- `Ctx::Abort(*C)` — stop the handler chain; subsequent handlers are skipped
- `Ctx::Param(*C, "name")` — extract named route params set by the router
- `Ctx::Set` / `Ctx::Get` — arbitrary KV store for middleware communication

---

## Phase Roadmap

| Phase | Deliverable | Status |
|-------|-------------|--------|
| P0 | Project foundation, test harness, deploy scripts | **done** |
| P1 | Core router + Context | **done** |
| P2 | Middleware engine (Next, Abort, Logger, Recovery) | planned |
| P3 | Request binding (Param, Query, JSON, Form, File) | planned |
| P4 | Response rendering + PureJinja integration | planned |
| P5 | Route groups + structured error handling | planned |
| P6 | SQLite3 integration + migrations | planned |
| P7 | Sessions, cookies, BasicAuth, CSRF | planned |
| P8 | Logging, .env config, run modes, scaffold | planned |
| P9 | Documentation + example apps | planned |
| P10 | Multi-DB abstraction (PostgreSQL, MySQL) | planned |

---

## Deployment

**Production server**: `129.212.236.80` (Ubuntu 24 · systemd · Caddy)

```bash
./scripts/deploy.sh   # pull → compile → test → swap → start → health check
./scripts/rollback.sh # stop → swap app.bak → start → health check
```

---

## Contributing

PureSimple follows a phased development workflow. Each phase:
1. Lives on a `feature/P{N}-{short-name}` branch
2. Must pass all existing tests before merging
3. Merges to `main` and is tagged `v0.{N}.0`

See `CLAUDE.md` for full conventions.

---

## License

MIT — see [LICENSE](LICENSE).

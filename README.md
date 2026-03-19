# PureSimple

A lightweight web framework for **PureBasic 6.x**, inspired by Go's Gin and Chi. Compiles to a single native binary with zero external runtime dependencies.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Status: P5 Route Groups](https://img.shields.io/badge/status-P5%20Route%20Groups-yellow)

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

## Features (P5)

### Route Groups
- `Group::Init(@g, "/api")` — create a group with a path prefix
- `Group::Use(@g, @AuthMW())` — attach group-level middleware
- `Group::GET/POST/PUT/PATCH/DELETE/Any(@g, "/users", @handler)` — register routes as `prefix + pattern`
- `Group::SubGroup(@parent, @child, "/v1")` — nested groups; child inherits parent prefix and middleware
- `Group::CombineHandlers(@g, @ctx, @routeHandler)` — full chain: global MW + group MW + route

### Structured Error Handling
- `Ctx::AbortWithStatus(@ctx, 403)` — abort the chain and set the status code
- `Ctx::AbortWithError(@ctx, 422, "message")` — abort with status + plain-text body
- `Engine::SetNotFoundHandler(@handler)` — register a custom 404 handler
- `Engine::HandleNotFound(@ctx)` — invoke custom handler or default "404 Not Found"
- `Engine::SetMethodNotAllowedHandler(@handler)` — register a custom 405 handler
- `Engine::HandleMethodNotAllowed(@ctx)` — invoke custom handler or default "405 Method Not Allowed"

---

## Features (P4)

### Response Rendering
- `Rendering::JSON(*C, body, [status])` — write JSON response (`application/json`)
- `Rendering::HTML(*C, body, [status])` — write HTML response (`text/html`)
- `Rendering::Text(*C, body, [status])` — write plain-text response
- `Rendering::Status(*C, status)` — set status code only (body unchanged)
- `Rendering::Redirect(*C, url, [status])` — HTTP redirect; sets `*C\Location` (default 302)
- `Rendering::File(*C, path)` — send a file from disk; 404 if not found
- `Rendering::Render(*C, templateName, [dir])` — render a Jinja2 template via PureJinja;
  variables come from the request KV store (`Ctx::Set`)

---

## Features (P3)

### Request Binding
- `Binding::Param(*C, "name")` — route parameter (set by router)
- `Binding::Query(*C, "name")` — query string (`?key=value`); lazy-parsed and cached; URL-decoded (`+`, `%XX`)
- `Binding::PostForm(*C, "field")` — URL-encoded form body field; URL-decoded
- `Binding::BindJSON(*C)` — parse JSON body; store handle in context
- `Binding::JSONString` / `JSONInteger` / `JSONBool` — typed top-level JSON field accessors
- `Binding::ReleaseJSON(*C)` — free JSON handle

---

## Features (P2)

### Middleware Engine
- `Engine::Use(handler)` — register global middleware applied to every request
- `Engine::CombineHandlers(*C, routeHandler)` — prepend global middleware then append route handler before dispatch
- Execution order: middleware wraps the chain (onion model — A→B→route→B→A)

### Bundled Middleware
- `Logger::Middleware` — logs `[LOG] METHOD /path -> STATUS (Xms)` after the request completes
- `Recovery::Middleware` — wraps the handler chain with `OnErrorGoto`; converts PB runtime errors into `500 Internal Server Error` (Linux/Windows; OS-level signals on macOS arm64 bypass PB's error checkpoint)

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
| P2 | Middleware engine (Next, Abort, Logger, Recovery) | **done** |
| P3 | Request binding (Param, Query, JSON, Form, File) | **done** |
| P4 | Response rendering + PureJinja integration | **done** |
| P5 | Route groups + structured error handling | **done** |
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

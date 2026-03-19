# Book Outline: Building Web Applications with PureBasic

**Working title**: *Native Web: Building Fast, Dependency-Free Web Applications with PureBasic*

**Audience**: Intermediate PureBasic developers; experienced developers from other
languages (Go, Python, C) who are new to PureBasic.

**Goal**: Walk the reader from zero to a production-ready web application — a
blog or API — compiled to a single native binary with no runtime dependencies.

---

## Part I — Foundations

### Chapter 1: Why PureBasic for the Web?
- The case for native binaries: no interpreter, no VM, no deployment surprises
- Memory model: manual allocation, no GC pauses
- Cross-platform: one codebase for macOS, Linux, Windows
- The three-repo ecosystem: PureSimpleHTTPServer, PureSimple, PureJinja
- Setting up the development environment (IDE, compiler paths, PUREBASIC_HOME)
- Hello World: your first PureSimple app in 10 lines

### Chapter 2: PureBasic Fundamentals for Web Developers
- Types and the `.i` integer gotcha (pointer-sized: 4 vs 8 bytes)
- `EnableExplicit` — non-negotiable for production code
- Strings: concatenation, `StringField`, `CountString`, `Mid`, `FindString`
- `NewMap`, `NewList`, and `Dim` — when to use each
- Modules: `DeclareModule`/`Module`/`UseModule` — why module bodies are black boxes
- Common pitfalls: `FileSize` vs FileExists, `Default` keyword, `Next` keyword
- Error handling: return-code pattern vs `OnErrorGoto`

### Chapter 3: HTTP Fundamentals
- Request/response model: method, path, headers, body, status
- URL structure: path segments, query string, percent encoding
- Content negotiation: JSON vs HTML vs plain text
- Stateless HTTP and the role of cookies/sessions
- What PureSimpleHTTPServer provides (and what PureSimple adds on top)

---

## Part II — The PureSimple Framework

### Chapter 4: Routing
- Registering routes with `Engine::GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `Any`
- Named parameters (`:id`) and wildcards (`*path`)
- Route priority: exact > param > wildcard
- The radix trie data structure (conceptual, not implementation detail)
- Custom 404 and 405 handlers

### Chapter 5: The Request Context
- `RequestContext` — what lives on it and why
- `Ctx::Advance` — the "Next" pattern (and why it can't be called Next)
- `Ctx::Abort` and `Ctx::AbortWithError` — stopping the chain early
- The KV store: `Ctx::Set`/`Ctx::Get` for passing data between middleware
- Route parameters with `Binding::Param`

### Chapter 6: Middleware
- What middleware is and when to use it
- The chain pattern: call `Ctx::Advance` to continue, return to stop
- Logger middleware: timing and structured output
- Recovery middleware: turning runtime errors into 500 responses
- Writing your own middleware: rate limiting, request IDs, CORS headers
- Middleware ordering and why it matters

### Chapter 7: Request Binding
- Query strings: `Binding::Query` and URL decoding
- Form data: `Binding::PostForm`
- JSON body: `Binding::BindJSON`, field accessors, `ReleaseJSON`
- File uploads (coming in a later phase)
- Validation patterns: checking required fields, returning 400 errors

### Chapter 8: Response Rendering
- `Rendering::JSON` — building JSON strings manually vs with PureBasic's JSON API
- `Rendering::HTML` and `Rendering::Text`
- `Rendering::Redirect` — 302 vs 301
- `Rendering::File` — serving static content
- `Rendering::Render` — Jinja2 templates with PureJinja

### Chapter 9: Route Groups
- Why groups exist: shared prefixes, shared middleware
- `Group::Init`, `Group::Use`, route registration
- Nested groups with `Group::SubGroup`
- API versioning pattern: `/api/v1/...` vs `/api/v2/...`
- Admin-only routes with group-scoped authentication middleware

---

## Part III — Templates

### Chapter 10: PureJinja — Jinja2 Templates in PureBasic
- Template syntax: `{{ variable }}`, `{% if %}`, `{% for %}`, filters
- `Rendering::Render` and the KV store as template context
- Template inheritance with `{% extends %}` and `{% block %}`
- The 35 built-in filters (upper, lower, default, join, length, …)
- Custom template directories and `SetTemplatePath`
- Escaping HTML and the `safe` filter

### Chapter 11: Building an HTML Application
- Project structure: `main.pb`, `templates/`, `static/`
- Base template with navigation and footer
- Index page: iterating a list of items
- Detail page: displaying a single item
- Error pages: 404.html and 500.html
- Flash messages via sessions

---

## Part IV — Data

### Chapter 12: SQLite Integration
- Opening databases (file-based and in-memory)
- DDL with `DB::Exec`: creating tables and indexes
- DML: `INSERT`, `UPDATE`, `DELETE`
- Queries: `DB::Query`, `DB::NextRow`, `DB::GetStr`/`GetInt`/`GetFloat`
- Parameterised queries: `DB::BindStr`/`BindInt` (preventing injection)
- `DB::Error` — handling failures gracefully
- The migration runner: `AddMigration`, `Migrate`, and idempotency

### Chapter 13: Database Patterns
- Repository pattern: isolating DB code behind a module
- Pagination: LIMIT/OFFSET queries
- Transactions: `BEGIN`/`COMMIT`/`ROLLBACK` via `DB::Exec`
- Seeding test data and resetting state between tests
- Connection pooling considerations (single-threaded vs multi-threaded)

---

## Part V — Security and Auth

### Chapter 14: Cookies and Sessions
- `Cookie::Get` / `Cookie::Set` — reading and writing cookies
- Session lifecycle: create, load, update, persist
- `Session::Middleware` — the auto-save pattern
- Session storage: in-memory (current) vs persistent (SQLite-backed)
- Session security: `HttpOnly`, `Secure`, `SameSite` attributes (future)

### Chapter 15: Authentication
- HTTP Basic Auth with `BasicAuth::SetCredentials` / `BasicAuth::Middleware`
- Token-based auth: storing tokens in the KV store
- Password hashing: PureBasic's `Fingerprint` with SHA-256
- Login/logout flow: session-based auth walkthrough
- Role-based access control with group middleware

### Chapter 16: CSRF Protection
- What CSRF is and why it matters for form-based apps
- `CSRF::GenerateToken` — 128-bit random tokens
- `CSRF::SetToken` and embedding tokens in HTML forms
- `CSRF::Middleware` — validation for POST/PUT/PATCH/DELETE
- JSON API exemption: when CSRF is not needed

---

## Part VI — Configuration and Operations

### Chapter 17: Configuration and Logging
- `Config::Load` — `.env` files for twelve-factor apps
- `Config::Get`/`GetInt`/`Has` — reading config with fallbacks
- `Engine::SetMode` — debug vs release vs test
- `Log::SetLevel` / `Log::SetOutput` — structured log output
- Log levels in practice: what to log at each level
- Log rotation and file management

### Chapter 18: Deployment
- Compiling for production: `-z` optimizer flag, stripping debug info
- The systemd service file (`deploy/puresimple.service`)
- Caddy as a reverse proxy: TLS termination, HTTP/2, compression
- The deploy script: pull → compile → test → swap → health check
- The rollback script: keeping `app.bak`
- Zero-downtime deployments (conceptual)
- Monitoring: health check endpoint pattern

### Chapter 19: Testing
- The PureSimple test harness: `Check`, `CheckEqual`, `CheckStr`
- Unit testing request handlers without an HTTP server
- Testing middleware chains: constructing `RequestContext` manually
- Integration testing with SQLite in-memory databases
- Regression testing: the `run_all.pb` pattern
- Test isolation: `ResetMiddleware`, `ClearStore`, `Config::Reset`

---

## Part VII — Complete Projects

### Chapter 20: Building a REST API (To-Do List)
- Project scaffold with `scripts/new-project.sh`
- JSON CRUD: Create, Read, Update, Delete
- In-memory storage vs SQLite persistence
- Input validation and error responses
- Testing with `curl`
- Adding authentication to the API

### Chapter 21: Building a Blog
- Route design: `/`, `/post/:slug`, `/admin/...`
- Database schema: posts, authors, tags
- Migrations from day one
- HTML templates with base layout and blocks
- Session-based login for the admin panel
- CSRF protection on the create/edit forms
- Deploying to the production server

### Chapter 22: Multi-Database Support (Preview — P10)
- Why abstract over the database layer
- The `DB` module interface pattern
- Swapping SQLite for PostgreSQL
- Connection string configuration via `.env`

---

## Appendices

### Appendix A: PureBasic Quick Reference for Web Developers
- Key differences from C, Go, Python
- Standard library cheat sheet (strings, files, JSON, HTTP)
- Common gotchas table (the condensed version of `resources/common-pitfalls.md`)

### Appendix B: PureSimple API Reference
- All modules and procedures (mirrors `docs/api/`)
- `RequestContext` field reference

### Appendix C: PureJinja Filter Reference
- All 35 built-in filters with examples

### Appendix D: Compiler Flags Reference
- Key `pbcompiler` flags for development and production builds

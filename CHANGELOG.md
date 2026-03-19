# Changelog

All notable changes to PureSimple are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows `v0.{phase}.0` during the pre-1.0 development phases.

---

## [Unreleased]

### Added
- `examples/massively/` — "Wild & Still" production-quality nature photography blog:
  - SQLite with 10 migrations (schema + 5 seed posts + site settings + contacts)
  - Public routes: post list, single post, contact form (PRG pattern), health check
  - Admin group: BasicAuth + full post CRUD + contact inbox
  - PureJinja templates: Massively theme (public) + Tabler CDN (admin)
  - Config via `.env`, leveled logging, custom 404 handler
  - `examples/massively/walk-through/` — 10-step guide (introduction through Ubuntu deploy)
  - `examples/massively/db/blog.db` — pre-seeded SQLite database committed to repo

### Changed
- `README.md` — added `examples/massively/` to Example Apps table; corrected P8/P9/P10
  roadmap status from "planned" to "done"; added Third-Party Credits section documenting
  Massively (CCA 3.0), Tabler (MIT), and five Pexels photographs with per-photo attribution
- `docs/api/index.md` — updated DB module entry to reflect both SQLite and DBConnect modules

### Dependencies
- `pure_jinja` — added `split` filter (unblocks all Massively templates that use
  `split('\n')`, `split('|')`, `split('\n\n')`); replaced silent unknown-filter pass-through
  with `JinjaError::SetError` so missing filters surface immediately

---

## [0.10.0] — 2026-03-20 · P10: Multi-DB Abstraction (PostgreSQL, MySQL)

### Added
- `src/DB/Connect.pbi` — `DBConnect` module: DSN-based connection factory for
  SQLite, PostgreSQL, and MySQL/MariaDB:
  - `DBConnect::Driver(DSN.s)` — detect driver from DSN prefix;
    returns `#Driver_SQLite`, `#Driver_Postgres`, `#Driver_MySQL`, or
    `#Driver_Unknown`
  - `DBConnect::Open(DSN.s)` — parse DSN, activate the correct PureBasic
    database plugin (`#PB_Database_SQLite` / `_PostgreSQL` / `_MySQL`),
    and return a handle usable with all `DB::*` procedures
  - `DBConnect::OpenFromConfig()` — read `DB_DSN` from the Config store
    (default: `"sqlite::memory:"`) and call `Open()`
  - `DBConnect::ConnStr(DSN.s)` — parse a URL-style DSN into PureBasic's
    `"host=H [port=P] [dbname=D]"` key=value format (used internally;
    exposed for testing)
- Supported DSN schemes:
  - `sqlite::memory:` / `sqlite:path/to/db.sqlite`
  - `postgres://user:pass@host:5432/dbname`
  - `postgresql://user:pass@host:5432/dbname` (alias)
  - `mysql://user:pass@host:3306/dbname`
- `tests/P10_MultiDB_Test.pbi` — 35 assertions: driver detection for all
  three drivers, ConnStr parsing (with and without port/dbname), SQLite
  Open + full DB pipeline, migration runner via Connect handle,
  OpenFromConfig with explicit and default DSN

### Changed
- `src/PureSimple.pb` — added `DB/Connect.pbi` include (after Config and Log,
  since `OpenFromConfig` depends on `Config::Get`)
- `tests/run_all.pb` — enabled `P10_MultiDB_Test.pbi`

### Notes
- `DB/Connect.pbi` calls `UseSQLiteDatabase()`, `UsePostgreSQLDatabase()`, and
  `UseMySQLDatabase()` at the module level so all three drivers are compiled in.
  PureBasic 6.x selects the correct driver via the `#PB_Database_*` plugin
  constant passed as the 5th argument to `OpenDatabase()`.
- `DBConnect::Open` must be called before `DB::Migrate` if you want migrations
  to run against a non-SQLite database — the `DB::*` procedures are driver-
  agnostic once the handle is obtained.
- PostgreSQL and MySQL paths are not integration-tested (no server available in
  CI); the SQLite driver is used for all test assertions. DSN parsing correctness
  is verified via `ConnStr()` unit tests.
- `DB/Connect.pbi` must be included AFTER `Config.pbi` in the include order
  (it calls `Config::Get` inside `OpenFromConfig`).

---

## [0.9.0] — 2026-03-20 · P9: Documentation, Example Apps, Book Outline

### Added
- `docs/api/index.md` — API overview, quick-start snippet, request lifecycle diagram,
  handler signature reference
- `docs/api/engine.md` — Engine module: route registration, middleware, error handlers,
  run modes, lifecycle
- `docs/api/router.md` — Router module: Insert/Match, pattern syntax, priority rules
- `docs/api/context.md` — Context module: lifecycle, Abort variants, route params,
  KV store, RequestContext field reference
- `docs/api/binding.md` — Binding module: Param, Query, PostForm, JSON body
- `docs/api/rendering.md` — Rendering module: JSON, HTML, Text, Status, Redirect,
  File, template rendering
- `docs/api/group.md` — Group module: Init, Use, SubGroup, CombineHandlers, dispatch
- `docs/api/middleware.md` — All six middleware: Logger, Recovery, Cookie, Session,
  BasicAuth, CSRF
- `docs/api/db.md` — DB/SQLite module: Open/Close, Exec, Query, NextRow, column
  accessors, parameter binding, migration runner
- `docs/api/config.md` — Config module: Load, Get/GetInt, Set, Has, Reset, common
  pattern
- `docs/api/log.md` — Log module: levels, SetLevel/SetOutput, Dbg/Info/Warn/Error,
  output format, file append behaviour
- `docs/book-outline.md` — 22-chapter book outline: *Native Web: Building Fast,
  Dependency-Free Web Applications with PureBasic*; covers foundations, framework
  internals, templates, data, security/auth, config/ops, and two complete projects
- `examples/todo/main.pb` — JSON REST API example: `GET/POST /todos`,
  `GET/DELETE /todos/:id`, `GET /health`; uses Logger + Recovery middleware,
  Config for port, in-memory list store
- `examples/blog/main.pb` — HTML blog example: home, post detail, about, health
  routes; uses Logger + Recovery middleware, PureJinja templates, Config, Log
- `examples/blog/templates/index.html` — home page (iterates post list)
- `examples/blog/templates/post.html` — single post page
- `examples/blog/templates/about.html` — about page
- `tests/P9_Examples_Test.pbi` — 23 assertions: Todo CRUD lifecycle, Blog home +
  post param, health check, Config+Log integration, custom 404 pattern

### Changed
- `tests/run_all.pb` — enabled `P9_Examples_Test.pbi`
- `docs/api/context.md` — corrects `Ctx::Init` signature to `(*C, Method.s, Path.s)`
  (the summary incorrectly showed a `ContextID` parameter — actual signature sets
  `ContextID` internally via `_SlotSeq`)

### Notes
- `Ctx::Init` signature is `Init(*C.RequestContext, Method.s, Path.s)` — it auto-
  assigns `ContextID` from an internal slot counter, not as a caller parameter
- Example apps call `Engine::Run(port)` which is still a stub; a real HTTP listener
  is wired in via PureSimpleHTTPServer (future integration phase)

---

## [0.8.0] — 2026-03-20 · P8: Logging, .env Config, Run Modes, Scaffold

### Added
- `src/Config.pbi` — `Config` module for `.env` file loading + runtime key/value store:
  - `Config::Load(path)` — parse a `.env` file; skip `#` comment lines and blank lines;
    split on first `=`; overwrite existing keys on re-load; returns `#True` on success
  - `Config::Get(key, [fallback])` — return string value or fallback (default `""`)
  - `Config::GetInt(key, [fallback])` — return integer value via `Val()`; fallback default 0
  - `Config::Set(key, val)` — set or overwrite a config value at runtime
  - `Config::Has(key)` — return `#True` if key is present in the store
  - `Config::Reset()` — clear all config values (used between tests)
- `src/Log.pbi` — `Log` module with leveled structured logging:
  - Constants: `#LevelDebug=0`, `#LevelInfo=1`, `#LevelWarn=2`, `#LevelError=3`
  - `Log::SetLevel(level)` — suppress messages below this level (default `#LevelInfo`)
  - `Log::SetOutput(filename)` — `""` = stdout; any other path = append to file
  - `Log::Dbg(msg)` / `Log::Info(msg)` / `Log::Warn(msg)` / `Log::Error(msg)` —
    emit `[YYYY-MM-DD HH:MM:SS] [LEVEL] message` lines
  - File output creates the file if absent, appends if it exists (open + seek to `Lof`)
- `Engine::SetMode(mode)` / `Engine::Mode()` — get/set run mode string (`"debug"` default);
  used by middleware and application code to enable/disable verbose behaviour
- `scripts/new-project.sh` — scaffold a new PureSimple application:
  generates `main.pb`, `.env`, `.env.example`, `.gitignore`, `templates/index.html`,
  `static/` directory; resolves PureSimple path relative to the new project
- `tests/test.env` — fixture `.env` file used by the P8 test suite
- `tests/P8_Config_Test.pbi` — 25 assertions across 7 suites: Load, Get defaults,
  GetInt, Set runtime override, Has, Reset, Engine mode, and Log compile/output check

### Changed
- `src/PureSimple.pb` — added `Config.pbi` and `Log.pbi` includes (after DB/SQLite)
- `src/Engine.pbi` — added `SetMode`/`Mode` to `DeclareModule Engine` and `Module Engine`
- `examples/hello_world/main.pb` — updated to demonstrate `Config::Load`, `Log::Info`,
  `Engine::SetMode`, route registration, and the `Run()` stub
- `tests/run_all.pb` — enabled `P8_Config_Test.pbi`

### Notes
- `Default` is a reserved PureBasic keyword (used in `Select/Case/Default`); renamed
  parameter to `Fallback` in `Config::Get` and `Config::GetInt`
- `Debug` is a reserved PureBasic keyword (IDE debug output statement); renamed to
  `Log::Dbg` for the debug-level procedure
- `Config::GetInt` uses PureBasic's `Val()` which returns 0 for non-numeric strings —
  use `Config::Has()` first if you need to distinguish "missing" from "zero"

---

## [0.7.0] — 2026-03-20 · P7: Sessions, Cookies, BasicAuth, CSRF

### Added
- `src/Middleware/Cookie.pbi` — `Cookie` module:
  - `Cookie::Get(*C, name)` — parse value from `*C\Cookie` (raw Cookie header)
  - `Cookie::Set(*C, name, value, [path], [maxAge])` — append Set-Cookie directive to
    `*C\SetCookies` (Chr(10)-delimited; Max-Age omitted when 0)
- `src/Middleware/Session.pbi` — `Session` module with in-memory store:
  - `Session::Middleware(*C)` — reads `_psid` cookie; creates new session if missing;
    loads session KV into context; writes session cookie; auto-saves after chain returns
  - `Session::Get(*C, key)` / `Session::Set(*C, key, val)` — last-write-wins KV store
  - `Session::ID(*C)` — current 32-hex-char session ID
  - `Session::Save(*C)` — persist context session back to in-memory store
  - `Session::ClearStore()` — wipe all sessions (for tests)
- `src/Middleware/BasicAuth.pbi` — `BasicAuth` module:
  - `BasicAuth::SetCredentials(user, pass)` — configure expected credentials
  - `BasicAuth::Middleware(*C)` — decode Base64 credentials from `*C\Authorization`;
    abort 401 if missing, malformed, or wrong; store `_auth_user` in KV store on success
- `src/Middleware/CSRF.pbi` — `CSRF` module:
  - `CSRF::GenerateToken()` — 32-char random hex token (128-bit)
  - `CSRF::SetToken(*C)` — store token in session + Set-Cookie response
  - `CSRF::ValidateToken(*C, token)` — compare against session-stored token
  - `CSRF::Middleware(*C)` — skip GET/HEAD; validate `_csrf` form field for all other
    methods; abort 403 on mismatch
- `tests/P7_Auth_Test.pbi` — 41 assertions across 13 suites

### Changed
- `src/Types.pbi` — added `Cookie.s`, `SetCookies.s`, `Authorization.s`,
  `SessionID.s`, `SessionKeys.s`, `SessionVals.s` fields to `RequestContext`
- `src/Context.pbi` — `Ctx::Init` resets all six new fields
- `src/PureSimple.pb` — added Cookie/Session/BasicAuth/CSRF includes (after Binding,
  before PureJinja, since CSRF depends on Binding::PostForm)
- `tests/run_all.pb` — enabled `P7_Auth_Test.pbi`

### Notes
- `data` is a reserved PureBasic keyword (used in the `Data` statement); renamed to
  `sessData` in Session middleware
- `Base64Encoder(*buf, size)` returns a string; `Base64Decoder(str, *buf, size)`
  writes to a buffer and returns decoded byte count — parameters are not symmetric
- Session uses last-write-wins for duplicate keys: `Session::Set` always appends;
  `Session::Get` returns the last occurrence

---

## [0.6.0] — 2026-03-19 · P6: SQLite3 Integration + Migrations

### Added
- `src/DB/SQLite.pbi` — `DB` module wrapping PureBasic's built-in SQLite support:
  - `DB::Open(path)` — open database (`":memory:"` for in-memory); returns handle
  - `DB::Close(handle)` — close and free the database
  - `DB::Exec(handle, sql)` — execute non-SELECT SQL (INSERT/UPDATE/DELETE/CREATE);
    returns `#True` on success
  - `DB::Query(handle, sql)` — execute SELECT; returns `#True` if rows are available
  - `DB::NextRow(handle)` — advance cursor; returns `#True` while rows remain
    (named `NextRow` since `Next` is a reserved PureBasic keyword)
  - `DB::Done(handle)` — finish and free the current query result set
  - `DB::GetStr(handle, col)` / `DB::GetInt(handle, col)` / `DB::GetFloat(handle, col)` —
    0-based column accessors
  - `DB::BindStr(handle, idx, val)` / `DB::BindInt(handle, idx, val)` — 0-based
    parameter binding (call before `Exec`/`Query` with `?` placeholders)
  - `DB::Error()` — last database error message
  - `DB::AddMigration(version, sql)` — register a migration by version number
  - `DB::Migrate(handle)` — create `puresimple_migrations` tracking table if needed,
    then apply all pending migrations in registration order; idempotent
  - `DB::ResetMigrations()` — clear registered migrations (used between tests)
- `tests/P6_SQLite_Test.pbi` — 46 assertions across 11 suites: Open, Exec DDL+DML,
  Query rows, GetFloat, BindStr, BindInt, error handling, Migrate (run/idempotent/incremental),
  Close

### Changed
- `src/PureSimple.pb` — added `DB/SQLite.pbi` include
- `tests/run_all.pb` — enabled `P6_SQLite_Test.pbi`

### Notes
- `DatabaseError()` in PureBasic takes no parameters (global last-error string)
- `DB::NextRow` is used instead of `DB::Next` because `Next` is a PureBasic keyword
  (closes `For…Next` loops and cannot be redeclared as a procedure)
- Migrations are tracked by version integer in `puresimple_migrations`; running
  `DB::Migrate` twice is safe — already-applied versions are skipped

---

## [0.5.0] — 2026-03-19 · P5: Route Groups + Structured Error Handling

### Added
- `src/Group.pbi` — `Group` module implementing `PS_RouterGroup`:
  - `Group::Init(*G, prefix)` — initialise a group with a path prefix
  - `Group::Use(*G, handler)` — append group-level middleware (max 32)
  - `Group::GET/POST/PUT/PATCH/DELETE/Any(*G, pattern, handler)` — register
    routes as `prefix + pattern` (delegates to `Router::Insert`)
  - `Group::SubGroup(*parent, *child, subPrefix)` — create a nested group
    that inherits parent prefix and middleware, then extends with `subPrefix`
  - `Group::CombineHandlers(*G, *C, routeHandler)` — builds full chain:
    global engine MW + group MW + route handler
- `src/Context.pbi` — two new structured abort helpers:
  - `Ctx::AbortWithStatus(*C, statusCode)` — abort + set status in one call
  - `Ctx::AbortWithError(*C, statusCode, message)` — abort + status + plain-text body
- `src/Engine.pbi` — error handler registry:
  - `Engine::SetNotFoundHandler(handler)` — custom 404 handler
  - `Engine::HandleNotFound(*C)` — call registered handler or default 404 response
  - `Engine::SetMethodNotAllowedHandler(handler)` — custom 405 handler
  - `Engine::HandleMethodNotAllowed(*C)` — call registered handler or default 405 response
  - `Engine::AppendGlobalMiddleware(*C)` — expose global MW appending for Group module
- `tests/P5_Groups_Test.pbi` — 30 assertions across 12 suites

### Changed
- `src/Types.pbi` — added `PS_RouterGroup` structure (prefix + fixed MW[32] array + count)
- `src/Engine.pbi` — `ResetMiddleware()` now also clears custom error handlers;
  added `_NotFoundHandler` and `_MethodNotAllowed` globals
- `src/PureSimple.pb` — added `Group.pbi` include (after Engine.pbi)
- `tests/run_all.pb` — enabled `P5_Groups_Test.pbi`

### Notes
- `PS_RouterGroup.MW[32]` is a fixed inline array — `SubGroup` copies MW by index
  loop, so inherited groups are independent (adding to child does not affect parent)
- `Engine::ResetMiddleware()` clears all state (global MW + error handlers) — call
  between test suites to avoid interference

---

## [0.4.0] — 2026-03-19 · P4: Response Rendering + PureJinja Integration

### Added
- `src/Rendering.pbi` — `Rendering` module with full response-writing API:
  - `Rendering::JSON(*C, body, [status])` — sets `application/json` content type
  - `Rendering::HTML(*C, body, [status])` — sets `text/html` content type
  - `Rendering::Text(*C, body, [status])` — sets `text/plain` content type
  - `Rendering::Status(*C, status)` — sets status code only (body unchanged)
  - `Rendering::Redirect(*C, url, [status])` — sets `*C\Location` + status (default 302)
  - `Rendering::File(*C, path)` — reads file from disk; 404 if missing
  - `Rendering::Render(*C, templateName, [templatesDir])` — renders a Jinja
    template via PureJinja; exposes the request KV store as template variables
- `templates/test.html` — minimal Jinja template used by the P4 test suite
- `tests/P4_Rendering_Test.pbi` — 20 assertions across 8 suites: JSON, HTML,
  Text, Status, Redirect (302 and 301), File-missing 404, and Jinja Render

### Changed
- `src/Types.pbi` — added `Location.s` field to `RequestContext` (used by Redirect)
- `src/Context.pbi` — `Ctx::Init` resets `*C\Location = ""`
- `src/PureSimple.pb` — added `../../pure_jinja/PureJinja.pbi` and `Rendering.pbi`
  includes (PureJinja before Rendering so JinjaEnv/JinjaVariant symbols resolve)
- `tests/run_all.pb` — enabled `P4_Rendering_Test.pbi`

### Notes
- `Rendering::Render` uses `JinjaEnv::RenderTemplate` (high-level API that handles
  Tokenize → Parse → Render internally); template variables come from `Ctx::Set` KV pairs
- PureJinja lives at `../../pure_jinja/PureJinja.pbi` relative to `src/`
- `Rendering::File` reads line-by-line and appends `#LF$`; suitable for template files
  and small static assets

---

## [0.3.0] — 2026-03-19 · P3: Request Binding

### Added
- `src/Binding.pbi` — `Binding` module with full request-data extraction:
  - `Binding::Param(*C, name)` — route param (delegates to Ctx::Param)
  - `Binding::Query(*C, name)` — lazy-parsed query string (`?k=v&...`); caches
    decoded key/value pairs in `*C\QueryKeys`/`*C\QueryVals` on first access
  - `Binding::PostForm(*C, field)` — URL-encoded body field; parses on demand
  - `Binding::BindJSON(*C)` — parses `*C\Body` as JSON; stores handle in
    `*C\JSONHandle`; frees any previous handle automatically
  - `Binding::JSONString/JSONInteger/JSONBool(*C, key)` — top-level JSON field
    accessors; return safe defaults if handle is 0 or key is absent
  - `Binding::ReleaseJSON(*C)` — frees the JSON handle and resets to 0
    (named ReleaseJSON to avoid shadowing PureBasic's built-in `FreeJSON`)
- `tests/P3_Binding_Test.pbi` — 27 assertions across 9 suites: Param,
  Query, Query percent-encoding, PostForm, PostForm URL decoding, BindJSON,
  ReleaseJSON, invalid JSON body, empty body

### Changed
- `src/Types.pbi` — added `JSONHandle.i` field to `RequestContext`
- `src/Context.pbi` — `Ctx::Init` resets `*C\JSONHandle = 0`
- `src/PureSimple.pb` — added `Binding.pbi` include (before Engine.pbi)
- `tests/run_all.pb` — enabled `P3_Binding_Test.pbi`

### Notes
- `FreeJSON` is a PureBasic built-in; the module procedure is named
  `ReleaseJSON` to prevent shadowing it inside `Module Binding`
- URL decoding supports `+` → space and `%XX` hex sequences
- `Binding::Query` caches parsed results — subsequent calls on the same
  context are O(n) lookup, not O(n) parse

---

## [0.2.0] — 2026-03-19 · P2: Middleware Engine

### Added
- `src/Middleware/Logger.pbi` — `Logger::Middleware` logs `[LOG] METHOD /path -> STATUS (Xms)`
  after the downstream chain returns; uses `ElapsedMilliseconds()` for timing
- `src/Middleware/Recovery.pbi` — `Recovery::Middleware` installs `OnErrorGoto` checkpoint;
  converts PB-runtime errors into 500 responses (note: OS signals on macOS arm64 are not
  interceptable via `OnErrorGoto` — see `resources/common-pitfalls.md`)
- `src/Engine.pbi` — `Engine::Use(Handler.i)` registers global middleware;
  `Engine::CombineHandlers(*C, RouteHandler.i)` prepends global middleware then appends the
  route handler; `Engine::ResetMiddleware()` clears global middleware (used between tests)
- `tests/P2_Middleware_Test.pbi` — 12 assertions across 5 suites: Use+CombineHandlers,
  middleware ordering (ABRba sequence), Logger pass-through, Recovery normal flow,
  Recovery preserves explicit 500

### Changed
- `src/PureSimple.pb` — added `Middleware/Logger.pbi` and `Middleware/Recovery.pbi` includes;
  updated include-order comment
- `src/Engine.pbi` — added `UseModule Types` (needed for `*C.RequestContext` parameter in
  `CombineHandlers`); added `_MW` array and `_MWCount` global for middleware storage
- `tests/run_all.pb` — enabled `P2_Middleware_Test.pbi`

### Notes
- `@Module::Proc()` cannot be used in `Global` variable initialisers — it evaluates to 0;
  wrap in a plain procedure and use `@WrapperProc()` instead
- `OnErrorGoto` does not intercept OS signals (SIGHUP, SIGSEGV) on macOS arm64; the
  Recovery middleware's panic path works on Linux/Windows where PB intercepts those signals

---

## [0.1.0] — 2026-03-19 · P1: Core Router + Context

### Added
- `src/Types.pbi` — wrapped all shared types in `DeclareModule Types` / `Module Types`;
  added `PS_HandlerFunc` prototype and `ContextID.i` field to `RequestContext`
- `src/Router.pbi` — segment-level trie router (`Router::Insert`, `Router::Match`);
  supports literal segments, `:param` named params, and `*wildcard` catch-all segments;
  exact matches take priority over params, params over wildcards
- `src/Context.pbi` — `RequestContext` lifecycle module: `Ctx::Init`, `Ctx::Param`,
  `Ctx::Set`/`Get` KV store, `Ctx::AddHandler`, `Ctx::Dispatch`, `Ctx::Advance`,
  `Ctx::Abort`, `Ctx::IsAborted`
- `src/Engine.pbi` — `Engine::GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `Any` route
  registration methods (delegate to `Router::Insert`)
- `tests/P1_Router_Test.pbi` — 25 assertions covering router exact/param/wildcard
  matching, priority ordering, context param extraction, KV store, and handler chain
  with abort

### Changed
- `src/PureSimple.pb` — added `Router.pbi` and `Context.pbi` includes; added
  `UseModule Types` so that `RequestContext` and friends are accessible globally
- `src/Types.pbi` — redesigned: moved types into `DeclareModule Types` to make them
  accessible from other module bodies via `UseModule Types`
- `tests/run_all.pb` — enabled `P1_Router_Test.pbi`

### Notes
- `Ctx::Advance` is the Gin-style "Next" — `Next` is a reserved PureBasic keyword
- PureBasic module bodies are fully isolated from main-code globals; use
  `DeclareModule` + `UseModule` to share types across modules

---

## [0.0.0] — 2026-03-19 · P0: Project Foundation

### Added
- `src/PureSimple.pb` — framework entry point (stub)
- `src/Types.pbi` — `RequestContext`, `RouteEntry`, `RouterEngine` structure stubs
- `src/Engine.pbi` — `Engine::NewApp()` and `Engine::Run(port)` procedure stubs
- `tests/TestHarness.pbi` — macro-based assertion library (`Assert`, `AssertEqual`, `AssertString`, `PrintResults`)
- `tests/run_all.pb` — test suite entry point; add new phase test files here
- `tests/P0_Harness_Test.pbi` — self-tests verifying the harness and framework stub compile correctly
- `examples/hello_world/main.pb` — minimal example confirming the include chain resolves
- `resources/common-pitfalls.md` — PureBasic gotchas reference (9 entries)
- `templates/404.html`, `templates/500.html` — default Jinja error templates
- `scripts/deploy.sh` — SSH-based deploy pipeline (pull → compile → test → swap → start → health check)
- `scripts/rollback.sh` — emergency rollback script
- `deploy/puresimple.service` — systemd unit for the production server
- `deploy/Caddyfile` — Caddy reverse proxy config
- `deploy/setup-server.sh` — one-time server provisioning script
- `README.md` — project description, architecture diagram, build instructions
- `.gitignore` — compiled binaries, macOS artifacts, `.env`

# Changelog

All notable changes to PureSimple are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows `v0.{phase}.0` during the pre-1.0 development phases.

---

## [Unreleased]

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
  - `Rendering::Render(*C, templateName, [templatesDir])` — renders a Jinja2
    template via PureJinja; exposes the request KV store as template variables
- `templates/test.html` — minimal Jinja2 template used by the P4 test suite
- `tests/P4_Rendering_Test.pbi` — 20 assertions across 8 suites: JSON, HTML,
  Text, Status, Redirect (302 and 301), File-missing 404, and Jinja2 Render

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
- `templates/404.html`, `templates/500.html` — default Jinja2 error templates
- `scripts/deploy.sh` — SSH-based deploy pipeline (pull → compile → test → swap → start → health check)
- `scripts/rollback.sh` — emergency rollback script
- `deploy/puresimple.service` — systemd unit for the production server
- `deploy/Caddyfile` — Caddy reverse proxy config
- `deploy/setup-server.sh` — one-time server provisioning script
- `README.md` — project description, architecture diagram, build instructions
- `.gitignore` — compiled binaries, macOS artifacts, `.env`

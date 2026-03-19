# Changelog

All notable changes to PureSimple are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows `v0.{phase}.0` during the pre-1.0 development phases.

---

## [Unreleased]

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

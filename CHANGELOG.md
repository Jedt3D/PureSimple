# Changelog

All notable changes to PureSimple are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows `v0.{phase}.0` during the pre-1.0 development phases.

---

## [Unreleased]

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

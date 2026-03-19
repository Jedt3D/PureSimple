# Book Outline: PureSimple Web Framework

**Title**: *PureSimple Web Framework: Building Fast, Dependency-Free Web Applications with PureBasic*

**Subtitle**: From Hello World to Production Blog in One Binary

**Audience**: Intermediate PureBasic developers; experienced developers from other
languages (Go, Python, C) who are new to PureBasic.

**Goal**: Walk the reader from zero to a production-ready web application — a
blog or API — compiled to a single native binary with no runtime dependencies.

**Authoring guidelines**: See [`book_authoring_plan.md`](book_authoring_plan.md)
for voice, style, visual asset specs, and per-chapter production checklists.

**Chapters**: 23 + 5 appendices &middot; ~450-550 pages

---

## Part I — Foundations

### Chapter 1: Why PureBasic for the Web?

*Tagline: The case for compiling your web app into a single file that just runs.*

**Objectives:** Understand the binary advantage, the three-repo ecosystem, and set up a development environment.

- The case for native binaries: no interpreter, no VM, no deployment surprises
- Comparison: deploying PureSimple vs Go vs Node.js (size, startup, dependencies)
- Memory model: manual allocation, no GC pauses
- Cross-platform: one codebase for macOS, Linux, Windows
- The three-repo ecosystem: PureSimpleHTTPServer, PureSimple, PureJinja
- Setting up the development environment (IDE, compiler paths, `PUREBASIC_HOME`)
- Hello World: your first PureSimple app in 10 lines

**Diagrams:** Fig 1.1 Three-repo ecosystem &middot; Fig 1.2 Compilation pipeline
**Illustration:** Compiled binary vs Rube Goldberg interpreters (pen sketch)
**Listings:** Hello World app; compile-and-run terminal session

*Summary &middot; Key takeaways (3) &middot; Questions (3, incl. "Try it: compile Hello World")*

---

### Chapter 2: The PureBasic Language

*Tagline: Everything you need to read framework code and write handlers.*

**Objectives:** Master types, strings, data structures, modules, error handling, and reserved-word gotchas.

- Types and the `.i` integer gotcha (pointer-sized: 4 vs 8 bytes)
- `EnableExplicit` — non-negotiable for production code
- Strings: concatenation, `StringField`, `CountString`, `Mid`, `FindString`
- Structures and pointers: `*pointer.StructName`
- `NewMap`, `NewList`, and `Dim` — when to use each (and the `Dim a(N)` = N+1 trap)
- Procedures, return types, `Prototype.i` for function pointers, `@MyProc()`
- Modules: `DeclareModule`/`Module`/`UseModule` — why module bodies are black boxes
- Common pitfalls: `FileSize` vs FileExists, `Default` keyword, `Next` keyword
- Error handling: return-code pattern vs `OnErrorGoto`
- Reserved words that will bite you: `Next`, `Default`, `Data`, `Debug`, `FreeJSON`, `Assert`

**Illustration:** Craftsman's workbench with labelled tool drawers (pen sketch)
**Listings:** Type declarations; StringField splitting; Structure + pointer; Map/List/Array comparison; Module declaration; OnErrorGoto pattern; Reserved-word workarounds table

*Summary &middot; Key takeaways (4) &middot; Questions (3, incl. "Try it: write a module")*

---

### Chapter 3: The PureBasic Toolchain — Compiler, Debugger, and PureUnit

*Tagline: The three tools that turn your code into a tested, debugged binary.*

**Objectives:** Compile from the command line, navigate the include tree, write tests with PureUnit and the PureSimple harness, and use the debugger.

**This chapter is the foundation for all code examples in the book.** After completing
it, readers can compile, test, and debug any code in the PureSimple repository.

- **The PureBasic compiler (`pbcompiler`)**
  - Command-line invocation and `PUREBASIC_HOME`
  - Essential flags: `-cl` (console), `-o` (output), `-z` (optimiser), `-k` (syntax check), `-t` (threads), `-dl` (DLL)
  - The include resolution model: how `XIncludeFile` builds the compilation unit
  - `XIncludeFile` vs `IncludeFile` — why `X` prevents duplicate definitions
  - Compiler constants: `#PB_Compiler_OS`, `#PB_Compiler_Processor`, `#PB_Compiler_File`, `#PB_Compiler_Line`
  - Cross-platform compilation notes (macOS, Linux, Windows paths)

- **The include tree**
  - How `src/PureSimple.pb` includes all modules in dependency order
  - Tracing the include chain from `tests/run_all.pb`

- **The PureBasic IDE and debugger**
  - IDE overview (for GUI-preferring readers)
  - Integrated debugger: breakpoints, variable watches, call stack, profiler
  - The `Debug` statement and debug output window
  - When to use IDE vs command line (web servers need the command line)

- **PureUnit — the built-in test framework**
  - `Assert()` and `AssertString()` — halt on first failure
  - Writing and running PureUnit tests
  - Limitation: halt-on-fail means you only see the first broken test

- **The PureSimple test harness**
  - Why PureSimple uses a custom harness (count-and-continue reporting)
  - `TestHarness.pbi`: `Check`, `CheckEqual`, `CheckStr`, `BeginSuite`, `PrintResults`
  - The `run_all.pb` pattern: one entry point, one binary, all 264+ assertions
  - Writing your first test suite: step-by-step walkthrough

- **Putting it all together**
  - Compile → Run Tests → Debug Failure → Fix → Re-test cycle

**Diagrams:** Fig 3.1 Compiler pipeline (.pb → preprocessor → C backend → linker → binary) &middot; Fig 3.2 XIncludeFile resolution tree for PureSimple.pb
**Illustration:** Precision lathe turning source scrolls into a polished gear (pen sketch)
**Listings:** Compiling console app; PureSimple.pb include chain (annotated); PureUnit test file; Check/CheckEqual/CheckStr macros; Writing a test suite; run_all.pb pattern; Compiler constants for diagnostics

*Summary &middot; Key takeaways (4) &middot; Questions (3, incl. "Try it: write a test suite with a failing check")*

---

### Chapter 4: HTTP Fundamentals

*Tagline: The language your browser and server speak to each other.*

**Objectives:** Understand the HTTP request/response cycle, URL structure, content types, and stateless communication.

- Request/response model: method, path, headers, body, status
- URL structure: path segments, query string, percent encoding
- Content negotiation: JSON vs HTML vs plain text
- Stateless HTTP and the role of cookies/sessions
- What PureSimpleHTTPServer provides (and what PureSimple adds on top)

**Diagrams:** Fig 4.1 HTTP request/response cycle (sequence diagram) &middot; Fig 4.2 URL anatomy
**Illustration:** Edwardian postal sorting office (pen sketch)
**Listings:** Raw HTTP request (text); Raw HTTP response (text)

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

## Part II — The PureSimple Framework

### Chapter 5: Routing

*Tagline: Teaching your server which handler answers which URL.*

**Objectives:** Register routes, use named parameters and wildcards, understand priority, and set up custom error handlers.

- Registering routes with `Engine::GET`, `POST`, `PUT`, `PATCH`, `DELETE`, `Any`
- Named parameters (`:id`) and wildcards (`*path`)
- Route priority: exact > param > wildcard
- The radix trie data structure (conceptual, not implementation detail)
- Custom 404 and 405 handlers

**Diagrams:** Fig 5.1 Radix trie routing example
**Illustration:** Tree with paths carved into its trunk, signposts at branches (pen sketch)
**Listings:** Route registration; named param extraction; wildcard catch-all; priority demo; custom 404 handler

*Summary &middot; Key takeaways (3) &middot; Questions (2, incl. "Try it: register routes and test with curl")*

---

### Chapter 6: The Request Context

*Tagline: The backpack every request carries through the handler chain.*

**Objectives:** Navigate the RequestContext struct, use Advance/Abort, pass data through the KV store, extract route parameters.

- `RequestContext` — what lives on it and why
- `Ctx::Advance` — the "Next" pattern (and why it can't be called Next)
- `Ctx::Abort` and `Ctx::AbortWithError` — stopping the chain early
- The KV store: `Ctx::Set`/`Ctx::Get` for passing data between middleware
- Route parameters with `Binding::Param`

**Diagrams:** Fig 6.1 RequestContext struct fields &middot; Fig 6.2 KV store data flow
**Illustration:** Traveller's rucksack with labelled pockets (pen sketch)
**Listings:** Ctx::Init; Ctx::Advance chain demo; Ctx::Abort; Set/Get KV store; Param extraction

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 7: Middleware

*Tagline: The security gates every request must pass through.*

**Objectives:** Understand the middleware chain, use Logger and Recovery, write custom middleware, reason about ordering.

- What middleware is and when to use it
- The chain pattern: call `Ctx::Advance` to continue, return to stop
- Logger middleware: timing and structured output
- Recovery middleware: turning runtime errors into 500 responses
- Writing your own middleware: rate limiting, request IDs, CORS headers
- Middleware ordering and why it matters

**Diagrams:** Fig 7.1 Onion model (middleware wrapping) &middot; Fig 7.2 Middleware ordering (A→B→handler→B→A)
**Illustration:** Series of gates in a walled garden (pen sketch)
**Listings:** Logger middleware walkthrough; Recovery middleware; custom rate-limiter

*Summary &middot; Key takeaways (4) &middot; Questions (2, incl. "Try it: write a request-ID middleware")*

---

### Chapter 8: Request Binding

*Tagline: Turning raw bytes into the data your handler needs.*

**Objectives:** Extract query strings, form data, and JSON bodies; validate input.

- Query strings: `Binding::Query` and URL decoding
- Form data: `Binding::PostForm`
- JSON body: `Binding::BindJSON`, field accessors, `ReleaseJSON`
- File uploads (coming in a later phase)
- Validation patterns: checking required fields, returning 400 errors

**Illustration:** Intake funnel sorting materials into labelled bins (pen sketch)
**Listings:** Query extraction; PostForm; BindJSON + JSONString; ReleaseJSON; validation pattern

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 9: Response Rendering

*Tagline: Giving your server a voice — JSON, HTML, redirects, and files.*

**Objectives:** Render JSON, HTML, text, redirects, and files; use PureJinja templates.

- `Rendering::JSON` — building JSON strings manually vs with PureBasic's JSON API
- `Rendering::HTML` and `Rendering::Text`
- `Rendering::Redirect` — 302 vs 301
- `Rendering::File` — serving static content
- `Rendering::Render` — Jinja2 templates with PureJinja

**Illustration:** Gutenberg printing press assembling a page (pen sketch)
**Listings:** JSON response; HTML response; redirect; file serving; Render with template + KV vars

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 10: Route Groups

*Tagline: Organising routes the way you organise your code — by responsibility.*

**Objectives:** Create groups with prefixes and middleware, nest groups, implement API versioning and admin routes.

- Why groups exist: shared prefixes, shared middleware
- `Group::Init`, `Group::Use`, route registration
- Nested groups with `Group::SubGroup`
- API versioning pattern: `/api/v1/...` vs `/api/v2/...`
- Admin-only routes with group-scoped authentication middleware

**Diagrams:** Fig 10.1 Group tree with prefix inheritance and middleware stacking
**Illustration:** Tree of roads diverging with toll booths at junctions (pen sketch)
**Listings:** Group::Init + Use; nested SubGroup; API versioning; admin group with BasicAuth

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

## Part III — Templates

### Chapter 11: PureJinja — Jinja2 Templates in PureBasic

*Tagline: The template engine that speaks Python syntax and runs at C speed.*

**Objectives:** Write Jinja2 templates, use inheritance and filters, render templates from handlers.

- Template syntax: `{{ variable }}`, `{% if %}`, `{% for %}`, filters
- `Rendering::Render` and the KV store as template context
- Template inheritance with `{% extends %}` and `{% block %}`
- The 34 built-in filters (plus 3 aliases) (upper, lower, default, join, split, length, ...)
- Custom template directories and `SetTemplatePath`
- Escaping HTML and the `safe` filter

**Diagrams:** Fig 11.1 PureJinja render pipeline (tokenize → parse → render) &middot; Fig 11.2 Template inheritance tree (base.html → index.html / post.html)
**Illustration:** Puppet theatre — puppet master (PureJinja) controls HTML elements on stage (pen sketch)
**Listings:** Variable output; if/for blocks; extends/block inheritance; filter chaining; the `split` filter; `safe` filter

*Summary &middot; Key takeaways (3) &middot; Questions (2, incl. "Try it: create a base template with two child pages")*

---

### Chapter 12: Building an HTML Application

*Tagline: From empty directory to rendered pages in one sitting.*

**Objectives:** Structure an HTML project, build a base template, create list and detail pages, handle errors.

- Project structure: `main.pb`, `templates/`, `static/`
- Base template with navigation and footer
- Index page: iterating a list of items
- Detail page: displaying a single item
- Error pages: 404.html and 500.html
- Flash messages via sessions

**Illustration:** Completed jigsaw puzzle of a webpage (pen sketch)
**Listings:** Project directory layout; base.html; index.html with for loop; detail page; 404.html; flash message pattern

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

## Part IV — Data

### Chapter 13: SQLite Integration

*Tagline: Your database compiles into the binary too.*

**Objectives:** Open databases, execute DDL/DML, query with parameters, run migrations.

- Opening databases (file-based and in-memory)
- DDL with `DB::Exec`: creating tables and indexes
- DML: `INSERT`, `UPDATE`, `DELETE`
- Queries: `DB::Query`, `DB::NextRow`, `DB::GetStr`/`GetInt`/`GetFloat`
- Parameterised queries: `DB::BindStr`/`BindInt` (preventing injection)
- `DB::Error` — handling failures gracefully
- The migration runner: `AddMigration`, `Migrate`, and idempotency

**Diagrams:** Fig 13.1 SQLite lifecycle: open → migrate → query → close
**Illustration:** Library card catalogue cabinet (pen sketch)
**Listings:** DB::Open; Exec DDL/DML; Query + NextRow loop; BindStr/BindInt; AddMigration + Migrate

*Summary &middot; Key takeaways (4) &middot; Questions (2, incl. "Try it: create a migration that adds a table and seeds data")*

---

### Chapter 14: Database Patterns

*Tagline: Patterns that keep your data layer clean as the app grows.*

**Objectives:** Implement the repository pattern, pagination, transactions, and test isolation.

- Repository pattern: isolating DB code behind a module
- Pagination: LIMIT/OFFSET queries
- Transactions: `BEGIN`/`COMMIT`/`ROLLBACK` via `DB::Exec`
- Seeding test data and resetting state between tests
- Connection pooling considerations (single-threaded vs multi-threaded)

**Illustration:** Architect's drafting table with blueprints and revision stamps (pen sketch)
**Listings:** Repository module; paginated query; transaction wrapper; seed/reset pattern

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

## Part V — Security and Auth

### Chapter 15: Cookies and Sessions

*Tagline: Teaching a stateless protocol to remember who you are.*

**Objectives:** Read/write cookies, manage session lifecycle, understand session storage trade-offs.

- `Cookie::Get` / `Cookie::Set` — reading and writing cookies
- Session lifecycle: create, load, update, persist
- `Session::Middleware` — the auto-save pattern
- Session storage: in-memory (current) vs persistent (SQLite-backed)
- Session security: `HttpOnly`, `Secure`, `SameSite` attributes (future)

**Diagrams:** Fig 15.1 Session lifecycle &middot; Fig 15.2 Cookie read/write flow
**Illustration:** Hotel reception desk with room keys and pigeonholes (pen sketch)
**Listings:** Cookie::Get/Set; Session::Middleware; Session::Get/Set; Session::Save

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 16: Authentication

*Tagline: Making sure the person at the door is who they say they are.*

**Objectives:** Implement BasicAuth, hash passwords, build a session-based login flow, scope access with groups.

- HTTP Basic Auth with `BasicAuth::SetCredentials` / `BasicAuth::Middleware`
- Token-based auth: storing tokens in the KV store
- Password hashing: PureBasic's `Fingerprint` with SHA-256
- Login/logout flow: session-based auth walkthrough
- Role-based access control with group middleware

**Diagrams:** Fig 16.1 BasicAuth decode pipeline
**Illustration:** Castle gate with guard checking credentials (pen sketch)
**Listings:** BasicAuth::SetCredentials + Middleware; Fingerprint SHA-256 hashing; session login flow; role-based group

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 17: CSRF Protection

*Tagline: The invisible attack you only discover after it's too late.*

**Objectives:** Understand CSRF attacks, generate and validate tokens, protect forms.

- What CSRF is and why it matters for form-based apps
- `CSRF::GenerateToken` — 128-bit random tokens
- `CSRF::SetToken` and embedding tokens in HTML forms
- `CSRF::Middleware` — validation for POST/PUT/PATCH/DELETE
- JSON API exemption: when CSRF is not needed

**Diagrams:** Fig 17.1 CSRF token flow (generate → embed → validate)
**Illustration:** Wax seal press stamping tokens onto documents (pen sketch)
**Listings:** CSRF::GenerateToken; SetToken; form with `_csrf` hidden field; Middleware

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

## Part VI — Configuration and Operations

### Chapter 18: Configuration and Logging

*Tagline: Twelve-factor config and logs that tell you what happened at 3 AM.*

**Objectives:** Load `.env` files, use config with fallbacks, set run modes, configure levelled logging.

- `Config::Load` — `.env` files for twelve-factor apps
- `Config::Get`/`GetInt`/`Has` — reading config with fallbacks
- `Engine::SetMode` — debug vs release vs test
- `Log::SetLevel` / `Log::SetOutput` — structured log output
- Log levels in practice: what to log at each level
- Log rotation and file management

**Illustration:** Control room with dials, gauges, and mode switch (pen sketch)
**Listings:** Config::Load; Get/GetInt/Has/Set/Reset; Engine::SetMode; Log levels; Log::SetOutput to file

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 19: Deployment

*Tagline: Getting your binary from your laptop to a server, without crossing your fingers.*

**Objectives:** Build for production, configure systemd and Caddy, deploy with health checks, roll back safely.

- Compiling for production: `-z` optimizer flag, stripping debug info
- The systemd service file (`deploy/puresimple.service`)
- Caddy as a reverse proxy: TLS termination, HTTP/2, compression
- The deploy script: pull → compile → test → swap → health check
- The rollback script: keeping `app.bak`
- Zero-downtime deployments (conceptual)
- Monitoring: health check endpoint pattern

**Diagrams:** Fig 19.1 Deploy pipeline &middot; Fig 19.2 systemd lifecycle &middot; Fig 19.3 Caddy reverse proxy architecture
**Illustration:** Crane lowering a binary onto a server rack (pen sketch)
**Listings:** deploy.sh walkthrough; rollback.sh; systemd unit file; Caddyfile; health check endpoint

*Summary &middot; Key takeaways (4) &middot; Questions (2)*

---

### Chapter 20: Testing

*Tagline: The 264 assertions that let you refactor without fear.*

**Objectives:** Write unit tests for handlers, test middleware chains, integrate with in-memory SQLite, isolate test state.

- The PureSimple test harness: `Check`, `CheckEqual`, `CheckStr`
- Unit testing request handlers without an HTTP server
- Testing middleware chains: constructing `RequestContext` manually
- Integration testing with SQLite in-memory databases
- Regression testing: the `run_all.pb` pattern
- Test isolation: `ResetMiddleware`, `ClearStore`, `Config::Reset`

**Illustration:** Laboratory bench with test tubes, microscope, and lab notebook (pen sketch)
**Listings:** Handler unit test; middleware chain test; integration test with :memory: SQLite; run_all.pb pattern

*Summary &middot; Key takeaways (3) &middot; Questions (2, incl. "Try it: write a test suite for a new handler")*

---

## Part VII — Complete Projects

### Chapter 21: Building a REST API (To-Do List)

*Tagline: Your first API, from scaffold to curl, in one chapter.*

**Objectives:** Scaffold a project, implement JSON CRUD, validate input, add authentication.

- Project scaffold with `scripts/new-project.sh`
- JSON CRUD: Create, Read, Update, Delete
- In-memory storage vs SQLite persistence
- Input validation and error responses
- Testing with `curl`
- Adding authentication to the API

**Illustration:** Kitchen mise-en-place with ingredients being assembled (pen sketch)
**Listings:** Full main.pb (todo app); CRUD handlers; curl test commands; adding auth

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

### Chapter 22: Building a Blog — Wild & Still

*Tagline: 596 lines of PureBasic. One binary. A production blog.*

**Objectives:** Build a full-featured blog with SQLite, admin CRUD, BasicAuth, templates, and deployment.

**This is the capstone chapter.** It ties together Chapters 1-20 using the
`examples/massively/` application as the reference implementation.

- Route design: `/`, `/post/:slug`, `/admin/...`
- Database schema: posts, contacts, site_settings (10 migrations)
- The `PostsToStr` / `AllPostsToStr` pipe-delimited data pattern
- PureJinja templates: Massively theme (public) + Tabler (admin)
  - Template inheritance with `base.html`
  - The `split('\n')` / `split('|')` / `split('\n\n')` pattern
- Admin group: BasicAuth + full post CRUD + contact inbox
- Contact form: POST binding, validation, PRG redirect pattern
- Deploying the blog to a production server (Caddy + systemd)

**Diagrams:** Fig 22.1 Blog route map and handler chain diagram
**Illustration:** Newspaper printing workshop with layout tables and delivery bicycle (pen sketch)
**Listings:** Full main.pb walkthrough (annotated sections); InitDB with 10 migrations; PostsToStr helper; IndexHandler + PostHandler; AdminPostCreateHandler; contact form PRG; Caddyfile for static assets

*Summary &middot; Key takeaways (4) &middot; Questions (3, incl. "Try it: add a tag system to the blog")*

---

### Chapter 23: Multi-Database Support

*Tagline: One interface, three drivers, zero code changes.*

**Objectives:** Understand DSN-based connection factories, swap databases via config, use DBConnect.

- Why abstract over the database layer
- `DBConnect::Driver` — detect driver from DSN prefix
- `DBConnect::Open` — parse DSN, activate driver, return handle
- `DBConnect::OpenFromConfig` — read `DB_DSN` from `.env`
- `DBConnect::ConnStr` — URL-style DSN to PureBasic key=value format
- Swapping SQLite for PostgreSQL or MySQL
- Connection string configuration via `.env`

**Diagrams:** Fig 23.1 DSN factory: one interface, three drivers
**Illustration:** Three identical keys opening the same lock (pen sketch)
**Listings:** DBConnect::Open with all three DSN types; OpenFromConfig; Driver detection; ConnStr parsing

*Summary &middot; Key takeaways (3) &middot; Questions (2)*

---

## Appendices

### Appendix A: PureBasic Quick Reference for Web Developers
- Key differences from C, Go, Python (comparison table)
- Standard library cheat sheet (strings, files, JSON, HTTP)
- Common gotchas table (condensed from `resources/common-pitfalls.md`)

### Appendix B: PureSimple API Reference
- All 11 modules and their procedures (mirrors `docs/api/`)
- `RequestContext` field reference (all fields, types, descriptions)
- Handler signature reference

### Appendix C: PureJinja Filter Reference
- All 34 built-in filters (plus 3 aliases) with one-line descriptions and examples
- Grouped by category: String, Number, List, Object, Encoding, Special

### Appendix D: Compiler Flags Reference
- Key `pbcompiler` flags for development and production builds
- Columns: flag, description, when to use, example

### Appendix E: Review Question Answers
- One-paragraph answers to all chapter-end questions
- "Try it" questions include complete code solutions

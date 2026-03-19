# Appendix B: PureSimple API Reference

This appendix documents every public procedure in the PureSimple framework, organised by module. It mirrors the content from `docs/api/` in the repository, consolidated into a single reference. Use it when you need to look up a procedure signature, a default parameter value, or the exact name of a field on `RequestContext`.

---

## B.1 Handler Signature

Every route handler and middleware in PureSimple follows the same procedure signature:

```purebasic
Prototype.i PS_HandlerFunc(*C.RequestContext)
```

Declare handlers as regular procedures and pass their address with `@`:

```purebasic
Procedure MyHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  Rendering::JSON(*C, ~"{\"id\":\"" + id + ~"\"}")
EndProcedure

Engine::GET("/users/:id", @MyHandler())
```

---

## B.2 Engine Module

**File:** `src/Engine.pbi`

The Engine module is the top-level application API. It registers routes, manages global middleware, configures error handlers, and controls the application lifecycle.

### Route Registration

| Procedure | Description |
|---|---|
| `Engine::GET(Pattern.s, Handler.i)` | Register a GET route |
| `Engine::POST(Pattern.s, Handler.i)` | Register a POST route |
| `Engine::PUT(Pattern.s, Handler.i)` | Register a PUT route |
| `Engine::PATCH(Pattern.s, Handler.i)` | Register a PATCH route |
| `Engine::DELETE(Pattern.s, Handler.i)` | Register a DELETE route |
| `Engine::Any(Pattern.s, Handler.i)` | Register a route for all five methods |

Patterns support literal segments (`/users/profile`), named parameters (`/users/:id`), and wildcards (`/static/*path`).

### Middleware

| Procedure | Description |
|---|---|
| `Engine::Use(Handler.i)` | Register global middleware (prepended to every request chain) |
| `Engine::ResetMiddleware()` | Clear all middleware and error handlers (for test isolation) |

Global middleware executes in registration order. Call `Use` before registering routes.

### Error Handlers

| Procedure | Description |
|---|---|
| `Engine::SetNotFoundHandler(Handler.i)` | Custom 404 handler |
| `Engine::HandleNotFound(*C.RequestContext)` | Invoke the 404 handler (used internally) |
| `Engine::SetMethodNotAllowedHandler(Handler.i)` | Custom 405 handler |
| `Engine::HandleMethodNotAllowed(*C.RequestContext)` | Invoke the 405 handler (used internally) |

Default responses when no custom handler is registered:
- **404:** `"404 Not Found"` with `text/plain`
- **405:** `"405 Method Not Allowed"` with `text/plain`

### Run Mode

| Procedure | Description |
|---|---|
| `Engine::SetMode(mode.s)` | Set mode: `"debug"` (default), `"release"`, or `"test"` |
| `Engine::Mode()` | Returns the current mode string |

### App Lifecycle

| Procedure | Description |
|---|---|
| `Engine::NewApp()` | Create application (stub, returns 0) |
| `Engine::Run(Port.i)` | Start listening (stub, returns `#False`) |

### Internal Procedures

| Procedure | Description |
|---|---|
| `Engine::CombineHandlers(*C.RequestContext, RouteHandler.i)` | Build the handler chain for a top-level route |
| `Engine::AppendGlobalMiddleware(*C.RequestContext)` | Copy global middleware into a context's handler array |

---

## B.3 Router Module

**File:** `src/Router.pbi`

The Router module implements a radix trie for URL pattern matching. Most applications interact with the router indirectly through `Engine::GET`, `Engine::POST`, etc. Direct use is needed only for custom dispatch callbacks.

### Procedures

| Procedure | Description |
|---|---|
| `Router::Insert(Method.s, Pattern.s, Handler.i)` | Register a handler for a method and pattern |
| `Router::Match(Method.s, Path.s, *C.RequestContext)` | Walk the trie and populate params. Returns handler address or 0. |

### Segment Priority

1. **Exact match** (fastest) -- e.g., `/users`
2. **Named parameter** -- e.g., `/users/:id`
3. **Wildcard** -- e.g., `/files/*path`

### Pattern Examples

```purebasic
Router::Insert("GET",    "/",               @HomeHandler())
Router::Insert("GET",    "/users",          @ListUsers())
Router::Insert("GET",    "/users/:id",      @GetUser())
Router::Insert("POST",   "/users",          @CreateUser())
Router::Insert("DELETE", "/users/:id",      @DeleteUser())
Router::Insert("GET",    "/files/*path",    @ServeFile())
```

Match results:

| Request | Handler | Params |
|---|---|---|
| `GET /users/42` | `GetUser` | `id="42"` |
| `GET /files/a/b` | `ServeFile` | `path="a/b"` |
| `GET /users` | `ListUsers` | (exact match wins) |

---

## B.4 Context Module

**File:** `src/Context.pbi`

The Context module manages the per-request lifecycle. It initialises the `RequestContext`, dispatches the handler chain, and provides the KV store for middleware-to-handler communication.

### Lifecycle

| Procedure | Description |
|---|---|
| `Ctx::Init(*C.RequestContext, ContextID.i)` | Reset all fields and assign the context ID |
| `Ctx::AddHandler(*C.RequestContext, Handler.i)` | Append a handler to the chain |
| `Ctx::Dispatch(*C.RequestContext)` | Call the first handler in the chain |
| `Ctx::Advance(*C.RequestContext)` | Call the next handler (equivalent to Gin's `Next`) |

`Advance` increments `HandlerIndex` and calls `handlers[HandlerIndex]`. Each middleware should call `Advance` to pass control down the chain.

### Abort

| Procedure | Description |
|---|---|
| `Ctx::Abort(*C.RequestContext)` | Stop the chain (subsequent `Advance` calls are no-ops) |
| `Ctx::IsAborted(*C.RequestContext)` | Returns `#True` if `Abort` was called |
| `Ctx::AbortWithStatus(*C.RequestContext, StatusCode.i)` | Abort and set the HTTP status code |
| `Ctx::AbortWithError(*C.RequestContext, StatusCode.i, Message.s)` | Abort with status and error message body |

### Route Parameters

| Procedure | Description |
|---|---|
| `Ctx::Param(*C.RequestContext, Name.s)` | Get a named route parameter. Returns `""` if not found. |

### KV Store

| Procedure | Description |
|---|---|
| `Ctx::Set(*C.RequestContext, Key.s, Val.s)` | Store a string value for this request |
| `Ctx::Get(*C.RequestContext, Key.s)` | Retrieve a string value. Returns `""` if not found. |

The KV store is used to pass data between middleware and handlers, and as the template variable source for `Rendering::Render`.

---

## B.5 Binding Module

**File:** `src/Binding.pbi`

The Binding module extracts data from the incoming request: route parameters, query strings, form bodies, and JSON payloads.

### Route Parameters

| Procedure | Description |
|---|---|
| `Binding::Param(*C.RequestContext, Name.s)` | Get named route param (delegates to `Ctx::Param`) |

### Query String

| Procedure | Description |
|---|---|
| `Binding::Query(*C.RequestContext, Name.s)` | Get a query string value. URL-decodes `+` and `%XX`. |

Lazy-parsed from `*C\RawQuery` on first call. Results cached in `*C\QueryKeys` / `*C\QueryVals`.

### Form Data

| Procedure | Description |
|---|---|
| `Binding::PostForm(*C.RequestContext, Field.s)` | Get a form field from `application/x-www-form-urlencoded` body |

Parses `*C\Body` as URL-encoded form data on every call. Results are stored in module-level temporaries, not cached on the `RequestContext`.

### JSON Body

| Procedure | Description |
|---|---|
| `Binding::BindJSON(*C.RequestContext)` | Parse `*C\Body` as JSON. Stores handle in `*C\JSONHandle`. |
| `Binding::JSONString(*C.RequestContext, Key.s)` | Get a string field from parsed JSON |
| `Binding::JSONInteger(*C.RequestContext, Key.s)` | Get an integer field from parsed JSON |
| `Binding::JSONBool(*C.RequestContext, Key.s)` | Get a boolean field from parsed JSON |
| `Binding::ReleaseJSON(*C.RequestContext)` | Free the JSON handle. Always call when done. |

**Important:** `ReleaseJSON` is named to avoid shadowing PureBasic's built-in `FreeJSON`. Invalid JSON sets `JSONHandle = 0` and `StatusCode = 400`. Field accessors return safe defaults (`""` / `0` / `#False`) when the handle is 0 or the key is absent.

---

## B.6 Rendering Module

**File:** `src/Rendering.pbi`

The Rendering module writes HTTP responses. Every procedure sets `StatusCode`, `ContentType`, and `ResponseBody` on the context.

### Procedures

| Procedure | Signature | Description |
|---|---|---|
| `Rendering::JSON` | `(*C, Body.s, Status.i = 200)` | JSON response (`application/json`) |
| `Rendering::HTML` | `(*C, Body.s, Status.i = 200)` | HTML response (`text/html`) |
| `Rendering::Text` | `(*C, Body.s, Status.i = 200)` | Plain text response (`text/plain`) |
| `Rendering::Status` | `(*C, Status.i)` | Set status code only, no body (for 204 No Content) |
| `Rendering::Redirect` | `(*C, URL.s, Status.i = 302)` | Redirect. Sets `*C\Location`. Use 302 for temporary, 301 for permanent. |
| `Rendering::File` | `(*C, Path.s)` | Serve a file from disk. Returns 404 if file does not exist. |
| `Rendering::Render` | `(*C, TemplateName.s, TemplatesDir.s = "templates/")` | Render a Jinja2 template via PureJinja. Variables come from the KV store. |

### Template Rendering Details

`Rendering::Render` performs the following steps:
1. Creates a PureJinja environment
2. Sets the template search path to `TemplatesDir`
3. Reads template variables from `*C\StoreKeys` / `*C\StoreVals`
4. Renders the template
5. Frees the environment
6. Sets `ContentType = "text/html"` and `StatusCode = 200`

On render failure, the response body contains the PureJinja error string.

---

## B.7 Group Module

**File:** `src/Group.pbi`

The Group module implements sub-routers with shared path prefixes and middleware stacks.

### Structure

```purebasic
Structure PS_RouterGroup
  Prefix.s            ; path prefix for all routes
  MW.i[32]            ; group-level middleware (max 32)
  MWCount.i           ; number of registered middleware
EndStructure
```

### Procedures

| Procedure | Description |
|---|---|
| `Group::Init(*G.PS_RouterGroup, Prefix.s)` | Initialise a group with a path prefix |
| `Group::Use(*G.PS_RouterGroup, Handler.i)` | Add middleware to the group |
| `Group::GET(*G, Pattern.s, Handler.i)` | Register a GET route in the group |
| `Group::POST(*G, Pattern.s, Handler.i)` | Register a POST route in the group |
| `Group::PUT(*G, Pattern.s, Handler.i)` | Register a PUT route in the group |
| `Group::PATCH(*G, Pattern.s, Handler.i)` | Register a PATCH route in the group |
| `Group::DELETE(*G, Pattern.s, Handler.i)` | Register a DELETE route in the group |
| `Group::Any(*G, Pattern.s, Handler.i)` | Register all methods in the group |
| `Group::SubGroup(*Parent, *Child, SubPrefix.s)` | Create a nested sub-group. Copies parent middleware to child. |
| `Group::CombineHandlers(*G, *C, RouteHandler.i)` | Build handler chain: global MW + group MW + route handler |

### Handler Chain Order

`CombineHandlers` builds the flat handler array in this order:

1. **Global engine middleware** (registered with `Engine::Use`)
2. **Group middleware** (registered with `Group::Use`)
3. **Route handler**

`SubGroup` copies parent middleware to the child at creation time. Middleware added to the child after `SubGroup` does not affect the parent.

---

## B.8 Middleware Modules

**Files:** `src/Middleware/*.pbi`

PureSimple ships six built-in middleware modules. All follow the standard handler signature.

### Logger

**File:** `src/Middleware/Logger.pbi`

| Procedure | Description |
|---|---|
| `Logger::Middleware()` | Returns the Logger handler address. Register with `Engine::Use(@Logger::Middleware())`. |

Logs one line per request after the downstream chain returns:

```
[LOG] GET /users/42 -> 200 (3ms)
```

Uses `ElapsedMilliseconds()` for timing. Output goes to stdout via `PrintN`.

### Recovery

**File:** `src/Middleware/Recovery.pbi`

| Procedure | Description |
|---|---|
| `Recovery::Middleware()` | Returns the Recovery handler address. |

Installs an `OnErrorGoto` checkpoint around the downstream chain. On a PureBasic runtime error, writes a `500 Internal Server Error` response and resumes cleanly.

**Note:** On macOS arm64, OS signals (SIGSEGV, SIGHUP from `RaiseError`) are not interceptable via `OnErrorGoto`. Recovery works reliably on Linux and Windows.

### Cookie

**File:** `src/Middleware/Cookie.pbi`

| Procedure | Description |
|---|---|
| `Cookie::Get(*C.RequestContext, Name.s)` | Read a cookie from the incoming `Cookie` header |
| `Cookie::Set(*C.RequestContext, Name.s, Value.s)` | Set a response cookie (basic) |
| `Cookie::Set(*C, Name.s, Value.s, Path.s, MaxAge.i)` | Set a response cookie with path and Max-Age |

`Get` parses `*C\Cookie` (semicolon-delimited `name=value` pairs). `Set` appends `Set-Cookie` directives to `*C\SetCookies` (Chr(10)-delimited).

### Session

**File:** `src/Middleware/Session.pbi`

| Procedure | Description |
|---|---|
| `Session::Middleware()` | Returns the Session middleware handler address |
| `Session::Get(*C.RequestContext, Key.s)` | Read a session value (returns last-write for the key) |
| `Session::Set(*C.RequestContext, Key.s, Value.s)` | Write a session value |
| `Session::ID(*C.RequestContext)` | Get the current session ID |
| `Session::Save(*C.RequestContext)` | Persist session data (auto-called by middleware after chain) |
| `Session::ClearStore()` | Wipe all sessions (for test isolation) |

Sessions are stored in a global in-memory map (`sessionID` to serialised KV). The session ID is a 32-character random hex string stored in the `_psid` cookie.

### BasicAuth

**File:** `src/Middleware/BasicAuth.pbi`

| Procedure | Description |
|---|---|
| `BasicAuth::SetCredentials(User.s, Pass.s)` | Set the expected username and password |
| `BasicAuth::Middleware()` | Returns the BasicAuth handler address |

Decodes the `Authorization: Basic <base64>` header. Aborts with `401 Unauthorized` if the header is missing, malformed, or credentials do not match. On success, stores the authenticated username in the KV store under `_auth_user`.

### CSRF

**File:** `src/Middleware/CSRF.pbi`

| Procedure | Description |
|---|---|
| `CSRF::GenerateToken()` | Generate a 128-bit random hex token |
| `CSRF::SetToken(*C.RequestContext)` | Store token in session and cookie |
| `CSRF::ValidateToken(*C.RequestContext, Token.s)` | Validate a token against the session. Returns `#True` on match. |
| `CSRF::Middleware()` | Returns the CSRF middleware handler address |

`CSRF::Middleware` skips `GET` and `HEAD` requests. For all other methods, it reads the `_csrf` form field via `Binding::PostForm` and compares it against the session-stored token. Aborts with `403 Forbidden` on mismatch.

**Requires:** Session middleware must be registered before CSRF middleware.

---

## B.9 DB Module (SQLite)

**File:** `src/DB/SQLite.pbi`

The DB module wraps PureBasic's built-in SQLite support with a streamlined API and adds a migration runner.

### Opening and Closing

| Procedure | Description |
|---|---|
| `DB::Open(Path.s)` | Open or create a SQLite database. Returns handle (0 on failure). |
| `DB::Close(Handle.i)` | Close a database handle |

Use `":memory:"` for an in-memory database (no persistence, ideal for tests).

### Executing SQL

| Procedure | Description |
|---|---|
| `DB::Exec(Handle.i, SQL.s)` | Execute non-SELECT SQL (DDL, INSERT, UPDATE, DELETE). Returns `#True` on success. |
| `DB::Error()` | Returns the last database error string |

### Querying

| Procedure | Description |
|---|---|
| `DB::Query(Handle.i, SQL.s)` | Execute a SELECT query. Returns `#True` on success. |
| `DB::NextRow(Handle.i)` | Advance to the next row. Returns `#True` if a row is available. |
| `DB::Done(Handle.i)` | Free the result set |

`NextRow` is named to avoid the reserved keyword `Next`.

### Column Accessors

| Procedure | Description |
|---|---|
| `DB::GetStr(Handle.i, Col.i)` | Get string value (0-based column index). Returns `""` if NULL. |
| `DB::GetInt(Handle.i, Col.i)` | Get integer value. Returns 0 if NULL. |
| `DB::GetFloat(Handle.i, Col.i)` | Get float value. Returns 0.0 if NULL. |

### Parameter Binding

| Procedure | Description |
|---|---|
| `DB::BindStr(Handle.i, Index.i, Value.s)` | Bind a string to a `?` placeholder (0-based) |
| `DB::BindInt(Handle.i, Index.i, Value.i)` | Bind an integer to a `?` placeholder (0-based) |

Binding must occur before the `Exec` or `Query` call that uses the placeholders.

### Migrations

| Procedure | Description |
|---|---|
| `DB::AddMigration(Version.i, SQL.s)` | Register a migration |
| `DB::Migrate(Handle.i)` | Apply all pending migrations (idempotent) |
| `DB::ResetMigrations()` | Clear registered migrations (for test isolation) |

`Migrate` creates a `puresimple_migrations` tracking table on first run, then applies each registered migration whose version number is not already recorded. Running `Migrate` twice is safe. Migrations run in registration order.

---

## B.10 DBConnect Module (Multi-Driver Factory)

**File:** `src/DB/Connect.pbi`

The DBConnect module provides a DSN-based connection factory that supports SQLite, PostgreSQL, and MySQL. All handles returned by `DBConnect::Open` are compatible with `DB::*` procedures.

### Procedures

| Procedure | Description |
|---|---|
| `DBConnect::Open(DSN.s)` | Parse DSN, activate driver, open connection. Returns handle. |
| `DBConnect::OpenFromConfig()` | Read `DB_DSN` from config (defaults to `"sqlite::memory:"`). |
| `DBConnect::Driver(DSN.s)` | Detect driver from DSN prefix. Returns a driver constant. |
| `DBConnect::ConnStr(DSN.s)` | Convert URL-style DSN to `key=value` format (for PostgreSQL/MySQL). |

### Driver Constants

| Constant | Value | DSN Prefix |
|---|---|---|
| `DBConnect::#Driver_SQLite` | 0 | `sqlite:` |
| `DBConnect::#Driver_Postgres` | 1 | `postgres://` or `postgresql://` |
| `DBConnect::#Driver_MySQL` | 2 | `mysql://` |
| `DBConnect::#Driver_Unknown` | -1 | anything else |

### DSN Examples

```
sqlite::memory:
sqlite:data/app.db
postgres://user:pass@host:5432/mydb
mysql://user:pass@host:3306/mydb
```

### ConnStr Conversion

```
Input:  postgres://alice:s3cr3t@db.host.io:5432/myapp
Output: host=db.host.io port=5432 dbname=myapp
```

---

## B.11 Config Module

**File:** `src/Config.pbi`

The Config module loads `.env` files and provides a runtime key/value configuration store.

### Procedures

| Procedure | Description |
|---|---|
| `Config::Load(Path.s)` | Load a `.env` file. Returns `#True` on success, `#False` if not found. |
| `Config::Get(Key.s)` | Get a config value. Returns `""` if not set. |
| `Config::Get(Key.s, Default.s)` | Get a config value with a fallback. |
| `Config::GetInt(Key.s, Default.i)` | Get an integer config value (via `Val()`). |
| `Config::Has(Key.s)` | Returns `#True` if the key exists. |
| `Config::Set(Key.s, Value.s)` | Set or overwrite a config value at runtime. |
| `Config::Reset()` | Clear all config values (for test isolation). |

### `.env` File Format

```
# Comments start with #
PORT=8080
MODE=release
APP_NAME=MyApp
DB_PATH=data/app.db
EMPTY_VALUE=
```

Rules:
- Lines split on the first `=`; whitespace trimmed
- Comment lines (`#`) and blank lines are skipped
- Keys are case-sensitive
- Re-loading overwrites existing keys

---

## B.12 Log Module

**File:** `src/Log.pbi`

The Log module provides leveled logging with optional file output.

### Log Levels

| Constant | Value | Use |
|---|---|---|
| `Log::#LevelDebug` | 0 | Verbose development output |
| `Log::#LevelInfo` | 1 | Normal operational messages (default) |
| `Log::#LevelWarn` | 2 | Recoverable problems |
| `Log::#LevelError` | 3 | Failures that need attention |

### Configuration

| Procedure | Description |
|---|---|
| `Log::SetLevel(Level.i)` | Set minimum log level. Messages below this level are suppressed. |
| `Log::SetOutput(Path.s)` | Write logs to a file (append mode). Pass `""` for stdout. |

### Writing Messages

| Procedure | Description |
|---|---|
| `Log::Dbg(Message.s)` | Write a `[DEBUG]` message |
| `Log::Info(Message.s)` | Write an `[INFO]` message |
| `Log::Warn(Message.s)` | Write a `[WARN]` message |
| `Log::Error(Message.s)` | Write an `[ERROR]` message |

**Note:** The debug procedure is named `Log::Dbg` (not `Log::Debug`) because `Debug` is a reserved PureBasic keyword.

### Output Format

```
[2026-03-20 14:32:01] [INFO]  Server starting on :8080
[2026-03-20 14:32:05] [WARN]  Rate limit approaching
[2026-03-20 14:32:09] [ERROR] Database connection lost
```

When `SetOutput` is given a non-empty path, the file is opened and closed on each write (safe for single-threaded use). If the file exists, messages are appended. If it does not exist, it is created.

---

## B.13 RequestContext Field Reference

The `RequestContext` structure is defined in `src/Types.pbi`. Every handler and middleware receives a pointer to this structure. Fields are accessed via the `\` operator: `*C\Method`, `*C\StatusCode`, etc.

### Request Fields (populated by HTTP server dispatch)

| Field | Type | Description |
|---|---|---|
| `Method` | `.s` | HTTP method: `"GET"`, `"POST"`, `"PUT"`, `"PATCH"`, `"DELETE"` |
| `Path` | `.s` | URL path, e.g., `"/api/users/42"` |
| `RawQuery` | `.s` | Query string, e.g., `"page=1&limit=10"` |
| `Body` | `.s` | Raw request body (for JSON binding and form parsing) |
| `ClientIP` | `.s` | Remote IP address |
| `Cookie` | `.s` | Raw incoming `Cookie` header, e.g., `"session=abc; foo=bar"` |
| `Authorization` | `.s` | Raw `Authorization` header, e.g., `"Basic dXNlcjpwYXNz"` |

### Response Fields (set by rendering procedures)

| Field | Type | Description |
|---|---|---|
| `StatusCode` | `.i` | HTTP status code to send (200, 404, 500, etc.) |
| `ResponseBody` | `.s` | Response content |
| `ContentType` | `.s` | MIME type: `"application/json"`, `"text/html"`, `"text/plain"` |
| `Location` | `.s` | Redirect URL (set by `Rendering::Redirect`, read by HTTP server) |
| `SetCookies` | `.s` | Accumulated `Set-Cookie` directives, Chr(10)-delimited |

### Handler Chain Fields (managed by Context module)

| Field | Type | Description |
|---|---|---|
| `ContextID` | `.i` | Slot index into global handler chain arrays |
| `HandlerIndex` | `.i` | Current position in the handler chain |
| `Aborted` | `.i` | `#True` if `Ctx::Abort` was called |

### Route Parameter Fields (populated by Router::Match)

| Field | Type | Description |
|---|---|---|
| `ParamKeys` | `.s` | Chr(9)-delimited list of parameter names |
| `ParamVals` | `.s` | Chr(9)-delimited list of parameter values |

### Query String Cache Fields (populated by Binding::Query)

| Field | Type | Description |
|---|---|---|
| `QueryKeys` | `.s` | Chr(9)-delimited list of query parameter names |
| `QueryVals` | `.s` | Chr(9)-delimited list of query parameter values |

### KV Store Fields (used by Ctx::Set / Ctx::Get)

| Field | Type | Description |
|---|---|---|
| `StoreKeys` | `.s` | Chr(9)-delimited list of store keys |
| `StoreVals` | `.s` | Chr(9)-delimited list of store values |

### JSON Binding Field

| Field | Type | Description |
|---|---|---|
| `JSONHandle` | `.i` | Handle to parsed JSON object (from `Binding::BindJSON`) |

### Session Fields (populated by Session middleware)

| Field | Type | Description |
|---|---|---|
| `SessionID` | `.s` | Current session ID |
| `SessionKeys` | `.s` | Chr(9)-delimited session KV keys |
| `SessionVals` | `.s` | Chr(9)-delimited session KV values |

---

## B.14 Request Lifecycle Summary

```
HTTP request arrives at PureSimpleHTTPServer
  -> dispatch callback invoked with raw method + path + headers + body
  -> Router::Match(method, path) -> route handler + params
  -> Engine::CombineHandlers or Group::CombineHandlers
       builds flat handler array: [global MW...] [group MW...] [route handler]
  -> Ctx::Init populates RequestContext
  -> Ctx::Dispatch calls handlers[0]
  -> Each middleware calls Ctx::Advance to pass control to the next handler
  -> Route handler writes response via Rendering::*
  -> PureSimpleHTTPServer sends StatusCode + ContentType + ResponseBody
```

---

## B.15 Related Structures

### RouterEngine

```purebasic
Structure RouterEngine
  Port.i              ; port to listen on
  Running.i           ; #True once Run() is called
EndStructure
```

### PS_RouterGroup

```purebasic
Structure PS_RouterGroup
  Prefix.s            ; path prefix prepended to all routes
  MW.i[32]            ; group-level middleware (max 32)
  MWCount.i           ; number of group-level middleware registered
EndStructure
```

# Appendix E: Review Question Answers

This appendix provides answers to all review questions from Chapters 1 through 23. Conceptual questions receive a one-paragraph explanation. "Try it" questions include complete, compilable code solutions.

---

## Chapter 1: Why PureBasic for the Web?

### Question 1

**Q:** Name the three repositories in the PureSimple ecosystem and explain what each one does.

**A:** The three repositories are **PureSimpleHTTPServer**, **PureSimple**, and **PureJinja**. PureSimpleHTTPServer is the HTTP/1.1 listener that handles low-level socket operations, TLS termination, gzip compression, and static file serving. PureSimple is the web framework layer that provides routing (via a radix trie), middleware chaining, request context management, request binding, response rendering, database integration, sessions, authentication, and configuration. PureJinja is a Jinja2-compatible template engine with 37 registered filters (34 unique implementations plus 3 aliases) that compiles templates at C speed. All three repositories compile into a single native binary through PureBasic's `XIncludeFile` inclusion mechanism -- there is no runtime linking, no package manager, and no deployment dependency chain.

### Question 2

**Q:** What is the advantage of compiling a web app into a single binary versus deploying an interpreted language?

**A:** A single compiled binary eliminates an entire category of deployment problems. There is no runtime to install on the server, no version mismatches between development and production, no `node_modules` directory to transfer, no virtual environment to configure, and no interpreter startup overhead. You copy one file, make it executable, and run it. The binary starts in milliseconds rather than seconds, uses less memory because there is no interpreter or garbage collector running alongside your code, and cannot break because a system update changed a shared library. The deployment script reduces to `scp binary server:path && ssh server restart`. Rollback is equally simple: you swap back to the previous binary.

### Question 3 (Try it)

**Q:** Clone all three repos, compile and run the Hello World example.

**A:**

```bash
# Clone all three repos side by side
cd ~/projects
git clone https://github.com/Jedt3D/PureSimpleHTTPServer
git clone https://github.com/Jedt3D/pure_jinja
git clone https://github.com/Jedt3D/PureSimple

# Set the compiler path (macOS)
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"

# Compile the Hello World example
cd PureSimple
$PUREBASIC_HOME/compilers/pbcompiler examples/hello_world/main.pb -cl -o hello_world

# Run it
./hello_world
```

Open a browser to `http://localhost:8080` to see the response.

---

## Chapter 2: The PureBasic Language

### Question 1

**Q:** Why does `Dim a(5)` create six elements, and how would you create exactly five?

**A:** PureBasic's `Dim a(N)` creates elements with indices from 0 to N inclusive, which is N+1 elements total. This follows a "maximum index" convention rather than a "count" convention. `Dim a(5)` creates indices 0, 1, 2, 3, 4, and 5 -- six elements. To create exactly five elements (indices 0 through 4), write `Dim a(4)`. This convention differs from fixed-size arrays inside structures, where `arr.i[5]` creates exactly 5 elements (indices 0 through 4). The two conventions are opposite, which is one of PureBasic's most common gotchas.

### Question 2

**Q:** Explain the difference between `IncludeFile` and `XIncludeFile`.

**A:** `IncludeFile` includes a source file unconditionally every time it appears. If two modules both use `IncludeFile "Types.pbi"`, the compiler processes `Types.pbi` twice, causing "structure already declared" and "module already declared" errors. `XIncludeFile` (the "X" stands for "exclusive") tracks which files have already been included and silently skips a file if it has been included before. This makes it safe for diamond-shaped dependency graphs where multiple modules depend on the same type definitions. Every `.pbi` file in PureSimple uses `XIncludeFile` exclusively.

### Question 3 (Try it)

**Q:** Write a module that exposes a `Greet(name.s)` procedure returning `"Hello, " + name + "!"`.

**A:**

```purebasic
; Listing E.1 -- Greet module
EnableExplicit

DeclareModule Greeter
  Declare.s Greet(name.s)
EndDeclareModule

Module Greeter
  Procedure.s Greet(name.s)
    ProcedureReturn "Hello, " + name + "!"
  EndProcedure
EndModule

; Test it
OpenConsole()
PrintN(Greeter::Greet("Alice"))   ; "Hello, Alice!"
PrintN(Greeter::Greet("World"))   ; "Hello, World!"
CloseConsole()
```

Compile and run:

```bash
$PUREBASIC_HOME/compilers/pbcompiler greet.pb -cl -o greet
./greet
```

Expected output:

```
Hello, Alice!
Hello, World!
```

---

## Chapter 3: The PureBasic Toolchain

### Question 1

**Q:** What is the difference between `-cl` and the default compiler mode, and why does it matter for web servers?

**A:** The `-cl` flag tells the PureBasic compiler to produce a console application. Without it, the compiler produces a GUI application that opens a window and routes output to the IDE's debug panel. A web server needs to write to stdout for logging, read from stdin for input, and run without a graphical interface -- especially on a headless Linux server. Without `-cl`, calls to `OpenConsole()`, `PrintN()`, and `Input()` either fail silently or behave unpredictably. The PureSimple test runner also requires `-cl` because it prints test results to the terminal. Every server binary and every test binary in this book is compiled with `-cl`.

### Question 2

**Q:** Why does PureSimple use `Check()` instead of PureBasic's built-in `Assert()`?

**A:** PureBasic 6.x ships with built-in `Assert()` and `AssertString()` macros (defined in `pureunit.res`) that halt execution on the first failure. This halt-on-fail behaviour means you only see one broken test per run, which slows down debugging when multiple tests fail simultaneously. PureSimple's custom harness uses `Check()`, `CheckEqual()`, and `CheckStr()` macros that increment pass/fail counters and continue execution. At the end of the run, `PrintResults()` prints a summary showing all failures, not just the first one. Additionally, redefining `Assert()` in a module would shadow the built-in and cause subtle conflicts, so the harness deliberately uses different names.

### Question 3 (Try it)

**Q:** Write a test file with `BeginSuite`, three `Check` assertions (one failing), compile with `-cl`, run it, and read the output.

**A:**

```purebasic
; Listing E.2 -- Test suite with a deliberate failure
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"
XIncludeFile "../../tests/TestHarness.pbi"

OpenConsole()

BeginSuite("My First Test Suite")

; Passing test: 1 + 1 equals 2
Check(1 + 1 = 2)

; Passing test: string comparison
CheckStr("hello", "hello")

; Deliberately failing test: 3 does not equal 4
CheckEqual(3, 4)

PrintResults()
CloseConsole()
```

Compile and run:

```bash
$PUREBASIC_HOME/compilers/pbcompiler my_test.pb -cl -o my_test
./my_test
```

Expected output (passes are silent; only failures are printed):

```
  [Suite] My First Test Suite
  FAIL  CheckEqual @ my_test.pb:18 => 3 <> 4

======================================
  FAILURES: 1 / 3
======================================
```

---

## Chapter 4: HTTP Fundamentals

### Question 1

**Q:** What is the difference between a path parameter (`/users/:id`) and a query parameter (`/users?id=42`)?

**A:** A path parameter is embedded in the URL path itself and is part of the route pattern. The router uses it to match requests to handlers: `/users/:id` matches `/users/42`, `/users/99`, etc., and the value (`42`, `99`) is extracted by name. Path parameters identify a specific resource and make the URL readable and bookmarkable. A query parameter is appended after the `?` in the URL and is not part of the route matching logic. `/users?id=42` and `/users?page=2` both match the `/users` route. Query parameters are typically used for filtering, sorting, pagination, and optional modifiers. In PureSimple, path parameters are accessed with `Binding::Param(*C, "id")` and query parameters with `Binding::Query(*C, "id")`.

### Question 2

**Q:** Why is HTTP considered stateless, and what mechanism do web apps use to remember users between requests?

**A:** HTTP is stateless because each request-response cycle is independent. The server does not retain any memory of previous requests from the same client. When a browser sends `GET /dashboard`, the server has no built-in way to know whether the client just logged in or is a first-time visitor. Web applications work around this limitation using cookies and sessions. The server sends a `Set-Cookie` header with a unique session ID, and the browser automatically includes that cookie in every subsequent request. The server maps the session ID to a data store (in-memory, database, or file) that holds user-specific state such as login status, preferences, and shopping cart contents. PureSimple implements this pattern through the Cookie and Session middleware modules.

---

## Chapter 5: Routing

### Question 1

**Q:** What is the priority order when a URL could match multiple route patterns?

**A:** The router resolves ambiguity using a three-level priority system: (1) an exact literal match wins first, (2) a named parameter match (`:param`) wins second, and (3) a wildcard match (`*path`) wins last. For example, if you register `/users/profile`, `/users/:id`, and `/users/*path`, a request to `/users/profile` matches the exact route, `/users/42` matches the named parameter route, and `/users/photos/vacation/sunset.jpg` matches the wildcard. This priority is evaluated per segment of the path, not globally, so `/users/profile` does not compete with `/admin/:id` -- they occupy different branches of the radix trie.

### Question 2 (Try it)

**Q:** Register routes and test with curl.

**A:**

```purebasic
; Listing E.3 -- Route registration and testing
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"

; Declare handlers before taking their addresses
Declare HomeHandler(*C.RequestContext)
Declare ListHandler(*C.RequestContext)
Declare GetHandler(*C.RequestContext)
Declare CreateHandler(*C.RequestContext)
Declare DeleteHandler(*C.RequestContext)
Declare FileHandler(*C.RequestContext)

Engine::GET("/",              @HomeHandler())
Engine::GET("/users",         @ListHandler())
Engine::GET("/users/:id",     @GetHandler())
Engine::POST("/users",        @CreateHandler())
Engine::DELETE("/users/:id",  @DeleteHandler())
Engine::GET("/files/*path",   @FileHandler())

Engine::Run(8080)

Procedure HomeHandler(*C.RequestContext)
  Rendering::Text(*C, "Welcome home")
EndProcedure

Procedure ListHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"[{\"id\":1},{\"id\":2}]")
EndProcedure

Procedure GetHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  Rendering::JSON(*C, ~"{\"id\":\"" + id + ~"\"}")
EndProcedure

Procedure CreateHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"created\":true}", 201)
EndProcedure

Procedure DeleteHandler(*C.RequestContext)
  Rendering::Status(*C, 204)
EndProcedure

Procedure FileHandler(*C.RequestContext)
  Protected path.s = Binding::Param(*C, "path")
  Rendering::Text(*C, "Serving: " + path)
EndProcedure
```

Test with curl:

```bash
curl http://localhost:8080/
curl http://localhost:8080/users
curl http://localhost:8080/users/42
curl -X POST http://localhost:8080/users
curl -X DELETE http://localhost:8080/users/42
curl http://localhost:8080/files/images/photo.jpg
```

---

## Chapter 6: The Request Context

### Question 1

**Q:** Why is the handler chain method named `Advance` instead of `Next`?

**A:** `Next` is a reserved keyword in PureBasic. It is used to close `For...Next` loops, and PureBasic does not allow reserved keywords to be used as procedure names, even inside modules. Attempting to define `Procedure Next(*C.RequestContext)` causes a compiler error. The PureSimple framework chose `Advance` as the replacement name because it clearly conveys the intent: advance to the next handler in the chain. This is one of the most notable differences between PureSimple and Go frameworks like Gin (which uses `c.Next()`) or Express.js (which uses `next()`).

### Question 2

**Q:** How does the KV store allow middleware to pass data to handlers?

**A:** The KV store is a pair of Chr(9)-delimited string fields on `RequestContext` (`StoreKeys` and `StoreVals`). When middleware calls `Ctx::Set(*C, "user_id", "42")`, the key and value are appended to these fields. When a downstream handler calls `Ctx::Get(*C, "user_id")`, it searches `StoreKeys` for the matching key and returns the corresponding value from `StoreVals`. Because the store exists on the per-request context, data is automatically scoped to the current request and cannot leak between concurrent requests. The same store is used by `Rendering::Render` to populate template variables -- any key/value pair set with `Ctx::Set` becomes available as `{{ key }}` in Jinja2 templates.

---

## Chapter 7: Middleware

### Question 1

**Q:** Why does middleware ordering matter?

**A:** Middleware executes in registration order, forming a chain where each middleware wraps the ones registered after it. If Logger is registered before Recovery, the Logger measures the total time including any error recovery. If Recovery is registered before Logger, a runtime error could crash the Logger. The correct order is Logger first (to time everything), then Recovery (to catch errors in downstream handlers). Similarly, Session middleware must be registered before CSRF middleware, because CSRF reads the token from the session. Registering them in the wrong order causes CSRF to find an empty session and reject every request. The general principle: middleware that needs data from another middleware must be registered after the one that provides it.

### Question 2 (Try it)

**Q:** Write a request-ID middleware.

**A:**

```purebasic
; Listing E.4 -- Request-ID middleware
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"

; Generate a simple unique ID using timestamp + random
Procedure.s GenerateRequestID()
  Protected ts.s = Str(ElapsedMilliseconds())
  Protected rn.s = Str(Random(99999))
  ProcedureReturn "req-" + ts + "-" + rn
EndProcedure

; The middleware
Procedure RequestIDMiddleware(*C.RequestContext)
  Protected reqID.s = GenerateRequestID()
  Ctx::Set(*C, "request_id", reqID)
  PrintN("[RequestID] " + reqID + " " +
         *C\Method + " " + *C\Path)
  Ctx::Advance(*C)
EndProcedure

; Register it
Engine::Use(@RequestIDMiddleware())

; A handler that reads the request ID
Engine::GET("/", @HomeHandler())
Engine::Run(8080)

Procedure HomeHandler(*C.RequestContext)
  Protected rid.s = Ctx::Get(*C, "request_id")
  Rendering::JSON(*C,
    ~"{\"message\":\"hello\",\"request_id\":\"" +
    rid + ~"\"}")
EndProcedure
```

---

## Chapter 8: Request Binding

### Question 1

**Q:** Why is the JSON cleanup procedure named `ReleaseJSON` instead of `FreeJSON`?

**A:** PureBasic provides a built-in `FreeJSON()` function as part of its JSON library. If PureSimple defined its own `FreeJSON` procedure inside a module, it would shadow the built-in and cause confusion or subtle bugs when the wrong version gets called. The PureSimple convention is to avoid name collisions with PureBasic built-ins by choosing an alternative name. `ReleaseJSON` clearly conveys the same intent (free the JSON handle and clean up resources) without conflicting with the standard library. This pattern applies to other PureBasic built-ins too -- PureSimple uses `DB::NextRow` instead of `Next`, `Log::Dbg` instead of `Debug`, and `Ctx::Advance` instead of `Next`.

### Question 2

**Q:** What happens if you forget to call `Binding::ReleaseJSON` after `Binding::BindJSON`?

**A:** The parsed JSON object remains allocated in memory for the lifetime of the process. Each un-released JSON handle leaks memory proportional to the size of the parsed JSON body. In a web server handling hundreds or thousands of requests, this leads to steadily growing memory consumption until the process is killed by the operating system or runs out of address space. Always call `ReleaseJSON` in every handler that calls `BindJSON`, even in error paths. A good pattern is to call `BindJSON`, do all your field extraction, and call `ReleaseJSON` immediately afterward, before any business logic that might return early.

---

## Chapter 9: Response Rendering

### Question 1

**Q:** What is the difference between `Rendering::Redirect(*C, "/login")` and `Rendering::Redirect(*C, "/login", 301)`?

**A:** The default status code for `Redirect` is 302 (Found), which is a temporary redirect. The browser follows the redirect but does not cache it -- the next time the user visits the original URL, the browser sends the request to the original URL again, and the server can decide whether to redirect again or serve content. A 301 (Moved Permanently) tells the browser to cache the redirect indefinitely. The browser will go directly to the new URL on subsequent visits without contacting the original URL. Use 302 for situations like "you are not logged in, go to the login page" (because after logging in, the original URL should work). Use 301 for permanent URL changes like "this page moved from /old-path to /new-path forever."

### Question 2

**Q:** How does `Rendering::Render` get its template variables?

**A:** `Rendering::Render` reads template variables from the request context's KV store (`*C\StoreKeys` and `*C\StoreVals`). Before calling `Render`, the handler (or middleware) populates the store using `Ctx::Set(*C, "key", "value")`. When `Render` creates the PureJinja environment, it iterates over all stored key-value pairs and registers them as template variables. In the template, `{{ key }}` outputs the corresponding value. This design means there is no separate "template context" object to construct -- the same KV store used for middleware communication doubles as the template variable source.

---

## Chapter 10: Route Groups

### Question 1

**Q:** What happens to middleware when you create a sub-group with `Group::SubGroup`?

**A:** `SubGroup` copies the parent group's middleware stack to the child at the time of creation. This means the child inherits all middleware registered on the parent up to that point. Middleware added to the parent after `SubGroup` is called does not propagate to the child, and middleware added to the child does not affect the parent. When a request matches a child group's route, the handler chain contains: all global engine middleware, then the child's middleware (which includes the inherited parent middleware plus any child-specific middleware), then the route handler. This copy-on-create behaviour prevents unexpected interactions between groups that share a parent.

### Question 2

**Q:** How would you structure groups for an API with v1 and v2 versions?

**A:** Create a parent group for `/api`, then two sub-groups for `/v1` and `/v2`. Each version can have its own middleware (for example, v2 might require a different authentication scheme). Routes registered on each sub-group automatically get the full prefix (`/api/v1/users`, `/api/v2/users`). Handlers can be shared between versions when the behaviour is the same, or you can write version-specific handlers when the API changes.

```purebasic
Protected api.PS_RouterGroup
Group::Init(@api, "/api")
Group::Use(@api, @Logger::Middleware())

Protected v1.PS_RouterGroup
Group::SubGroup(@api, @v1, "/v1")
Group::GET(@v1, "/users", @ListUsersV1())

Protected v2.PS_RouterGroup
Group::SubGroup(@api, @v2, "/v2")
Group::Use(@v2, @NewAuthMiddleware())
Group::GET(@v2, "/users", @ListUsersV2())
```

---

## Chapter 11: PureJinja

### Question 1

**Q:** What is the difference between `{{ variable }}` and `{% block %}` in Jinja2?

**A:** `{{ variable }}` is an expression tag that outputs the value of a variable or expression to the rendered HTML. It is replaced by the variable's string value at render time. `{% block %}` is a statement tag that defines a named content block for template inheritance. When a child template extends a parent template, it can override specific blocks to replace their content while keeping everything else from the parent. Expression tags produce output directly; statement tags control the template structure and logic (including `if`, `for`, `extends`, and `block`). You use `{{ }}` when you want to display data and `{% %}` when you want to control what gets displayed.

### Question 2 (Try it)

**Q:** Create a base template with two child pages.

**A:**

Create `templates/base.html`:

```html
<!DOCTYPE html>
<html>
<head>
  <title>{% block title %}My Site{% endblock %}</title>
</head>
<body>
  <nav>
    <a href="/">Home</a> |
    <a href="/about">About</a>
  </nav>
  <main>
    {% block content %}{% endblock %}
  </main>
  <footer>
    <p>Built with PureSimple</p>
  </footer>
</body>
</html>
```

Create `templates/index.html`:

```html
{% extends "base.html" %}
{% block title %}Home - My Site{% endblock %}
{% block content %}
  <h1>Welcome</h1>
  <p>Hello, {{ username|default("visitor") }}!</p>
{% endblock %}
```

Create `templates/about.html`:

```html
{% extends "base.html" %}
{% block title %}About - My Site{% endblock %}
{% block content %}
  <h1>About Us</h1>
  <p>This site is powered by PureSimple.</p>
{% endblock %}
```

Handler code:

```purebasic
Procedure IndexHandler(*C.RequestContext)
  Ctx::Set(*C, "username", "Alice")
  Rendering::Render(*C, "index.html")
EndProcedure

Procedure AboutHandler(*C.RequestContext)
  Rendering::Render(*C, "about.html")
EndProcedure

Engine::GET("/", @IndexHandler())
Engine::GET("/about", @AboutHandler())
```

---

## Chapter 12: Building an HTML Application

### Question 1

**Q:** Why should templates live in a dedicated `templates/` directory rather than alongside source code?

**A:** Separating templates from source code enforces a clean boundary between logic and presentation. Designers can edit HTML without navigating PureBasic source files. The directory structure mirrors deployment: `Rendering::Render` defaults to looking in `templates/`, and a dedicated directory makes it straightforward to set the template search path. It also prevents accidental inclusion of template files in the compilation unit -- PureBasic's `XIncludeFile` would choke on HTML syntax if a template were accidentally included.

### Question 2

**Q:** How do flash messages work with sessions?

**A:** A flash message is a one-time notification stored in the session and displayed on the next page load. The typical pattern is: (1) a handler performs an action (e.g., creating a post), (2) it stores a message in the session with `Session::Set(*C, "flash", "Post created successfully")`, (3) it redirects to another page with `Rendering::Redirect(*C, "/posts")`, (4) the target handler reads the flash message with `Session::Get(*C, "flash")`, passes it to the template via `Ctx::Set`, and clears it from the session. The message appears once and disappears on the next navigation. This is the Post-Redirect-Get (PRG) pattern, and it prevents form resubmission on browser refresh.

---

## Chapter 13: SQLite Integration

### Question 1

**Q:** Why should you always use parameterised queries instead of string concatenation?

**A:** String concatenation embeds user input directly into SQL, creating a SQL injection vulnerability. If a user submits the name `'; DROP TABLE users; --`, concatenation produces `SELECT * FROM users WHERE name = ''; DROP TABLE users; --'`, which deletes the table. Parameterised queries with `DB::BindStr` and `DB::BindInt` send the SQL template and the values separately. The database engine treats bound values as data, never as SQL commands, regardless of what characters they contain. There is no performance penalty for using parameters, and they also handle quoting and escaping correctly for all data types. Never concatenate user input into SQL. Use `?` placeholders and `DB::BindStr`/`DB::BindInt` in every query that includes external data.

### Question 2 (Try it)

**Q:** Create a migration that adds a table and seeds data.

**A:**

```purebasic
; Listing E.5 -- Migration with seed data
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"

; Register migrations
DB::AddMigration(1,
  "CREATE TABLE IF NOT EXISTS categories (" +
  "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
  "name TEXT NOT NULL, " +
  "slug TEXT NOT NULL UNIQUE)")

DB::AddMigration(2,
  "INSERT INTO categories (name, slug) VALUES " +
  "('Technology', 'technology')")

DB::AddMigration(3,
  "INSERT INTO categories (name, slug) VALUES " +
  "('Travel', 'travel')")

DB::AddMigration(4,
  "INSERT INTO categories (name, slug) VALUES " +
  "('Food', 'food')")

; Open an in-memory database and run migrations
Protected db.i = DB::Open(":memory:")
If db
  DB::Migrate(db)

  ; Verify
  OpenConsole()
  DB::Query(db, "SELECT id, name, slug FROM categories")
  While DB::NextRow(db)
    PrintN(Str(DB::GetInt(db, 0)) + ": " +
           DB::GetStr(db, 1) + " (" +
           DB::GetStr(db, 2) + ")")
  Wend
  DB::Done(db)
  DB::Close(db)
  CloseConsole()
EndIf

DB::ResetMigrations()
```

Expected output:

```
1: Technology (technology)
2: Travel (travel)
3: Food (food)
```

---

## Chapter 14: Database Patterns

### Question 1

**Q:** What is the repository pattern and why is it useful?

**A:** The repository pattern isolates all database access for a particular entity behind a dedicated module. Instead of scattering SQL queries throughout your handlers, you create a module (e.g., `PostRepo`) that exposes procedures like `PostRepo::FindAll()`, `PostRepo::FindByID(id)`, `PostRepo::Create(title, body)`, and `PostRepo::Delete(id)`. Handlers call these procedures without knowing the underlying SQL. This makes it easy to change the database schema without modifying handler code, write tests by swapping in a mock repository, and keep SQL centralised so it can be reviewed for correctness and security in one place.

### Question 2

**Q:** Why is `:memory:` useful for test databases?

**A:** An in-memory SQLite database exists only in RAM and is destroyed when the connection closes. This gives tests three benefits: speed (no disk I/O), isolation (each test gets a fresh database with no leftover data), and cleanup (closing the handle is all you need -- no files to delete). In a test suite, you open a `:memory:` database, run migrations, seed test data, execute your assertions, and close the handle. The next test starts with a clean slate. This is dramatically faster than file-based databases and eliminates the "forgot to clean up test data" class of bugs.

---

## Chapter 15: Cookies and Sessions

### Question 1

**Q:** What is the difference between a cookie and a session?

**A:** A cookie is a small piece of data stored in the browser and sent to the server with every request. It is visible to the client and has size limits (typically 4 KB). A session is server-side storage identified by a session ID that is itself stored in a cookie. The browser only sees the session ID (a random 32-character hex string); the actual session data (user ID, preferences, flash messages) lives on the server in a map, database, or file. Cookies are suitable for non-sensitive preferences. Sessions are required for sensitive data like authentication state, because the data never leaves the server.

### Question 2

**Q:** Why does PureSimple use in-memory session storage, and what is the trade-off?

**A:** In-memory session storage uses a global PureBasic map keyed by session ID. It is fast (no disk or network I/O), simple to implement, and requires no external dependencies. The trade-off is that all sessions are lost when the server process restarts. This is acceptable during development and for applications where session loss is tolerable (users simply log in again). For production systems that cannot afford session loss, a persistent storage backend (SQLite, Redis, or a database table) would be needed. PureSimple's in-memory store is the pragmatic starting point.

---

## Chapter 16: Authentication

### Question 1

**Q:** Why should passwords never be stored in plaintext?

**A:** If an attacker gains access to your database (through SQL injection, a backup leak, or a server compromise), plaintext passwords are immediately usable. The attacker can log into every user's account and, because people reuse passwords, likely into their accounts on other services too. Hashing passwords with a one-way function like SHA-256 (via PureBasic's `Fingerprint`) means the database stores only the hash. When a user logs in, the server hashes the submitted password and compares hashes. Even if the database is stolen, the attacker has hashes, not passwords, and cannot reverse them. For maximum security, use a salt (a random string prepended to each password before hashing) to prevent rainbow table attacks.

### Question 2

**Q:** How does BasicAuth middleware decode the `Authorization` header?

**A:** The `Authorization: Basic <base64>` header contains a Base64-encoded string of the format `username:password`. The BasicAuth middleware extracts the header from `*C\Authorization`, strips the `Basic ` prefix, Base64-decodes the remainder, and splits the result on the first `:` to separate the username and password. It then compares these credentials against the values set with `BasicAuth::SetCredentials`. If the header is missing, malformed, or the credentials do not match, the middleware calls `Ctx::AbortWithError(*C, 401, "Unauthorized")` and returns without calling `Ctx::Advance`. On success, it stores the authenticated username in the KV store under `_auth_user` and calls `Advance` to continue the chain.

---

## Chapter 17: CSRF Protection

### Question 1

**Q:** What is a CSRF attack and how does the token pattern prevent it?

**A:** A Cross-Site Request Forgery (CSRF) attack tricks a logged-in user's browser into submitting a request to a different site where the user is authenticated. For example, a malicious page could contain a hidden form that submits `POST /admin/delete-all` to your blog. The browser automatically includes the user's session cookie, so the server thinks the user intentionally submitted the form. The token pattern prevents this by embedding a random token in every legitimate form and validating it on submission. The attacker's page cannot read the token (same-origin policy prevents cross-site reads), so the forged form submission arrives without a valid token and is rejected with 403 Forbidden.

### Question 2

**Q:** When is CSRF protection not needed?

**A:** CSRF protection is unnecessary for JSON APIs that use `Authorization` headers (Bearer tokens, API keys) instead of cookies. The browser's automatic cookie inclusion is what makes CSRF possible. If authentication relies on a header that the client must explicitly set (not automatically attached by the browser), a cross-site page cannot forge the request because it cannot set custom headers on cross-origin requests. `GET` and `HEAD` requests are also exempt because they should be idempotent (they do not modify state). PureSimple's CSRF middleware automatically skips `GET` and `HEAD` requests and only validates tokens for `POST`, `PUT`, `PATCH`, and `DELETE`.

---

## Chapter 18: Configuration and Logging

### Question 1

**Q:** Why should `.env` files never be committed to version control?

**A:** `.env` files contain environment-specific configuration: database credentials, API keys, secret tokens, and server addresses. Committing them to Git means anyone with repository access (including public GitHub viewers, if the repo is ever made public) can read your production secrets. Each environment (development, staging, production) should have its own `.env` file created locally or injected by a deployment pipeline. Add `.env` to `.gitignore` and commit a `.env.example` file with placeholder values so new developers know which keys to configure. This is one of the twelve-factor app principles: store config in the environment, never in code.

### Question 2

**Q:** What is the difference between `Log::#LevelDebug` and `Log::#LevelInfo`, and when would you change the level?

**A:** `Log::#LevelDebug` (value 0) is the most verbose level, producing detailed output useful during development -- query timings, variable values, middleware entry/exit. `Log::#LevelInfo` (value 1) is the default production level, logging normal operational events like server startup, request handling summaries, and configuration values. When `SetLevel` is set to `Info`, all `Debug`-level messages are suppressed. You would set `Debug` during local development to see everything, and set `Info` or `Warn` in production to reduce log volume and avoid exposing internal details. PureSimple's common pattern is: read the `MODE` config value, and set `Debug` level for `"debug"` mode, `Info` level for `"release"` mode.

---

## Chapter 19: Deployment

### Question 1

**Q:** Why does the deploy script include a health check?

**A:** A health check verifies that the newly deployed binary actually started and is serving requests correctly. Without it, the deploy script might report success even though the binary crashed on startup (wrong config, missing database, port conflict). The health check sends `GET /health` and expects a `200 OK` response. If the check fails, the deploy script can automatically trigger a rollback to the previous binary (`app.bak`). This turns a potentially hours-long manual recovery into a seconds-long automated one. The health check endpoint should be cheap to execute (no database queries, no external calls) and should return 200 only when the application is genuinely ready to serve traffic.

### Question 2

**Q:** What does Caddy provide that PureSimple does not?

**A:** Caddy acts as a reverse proxy in front of PureSimple and provides: (1) automatic HTTPS with Let's Encrypt certificate provisioning and renewal, (2) HTTP/2 support, (3) gzip/brotli compression, (4) static file serving with proper caching headers, (5) request rate limiting, and (6) graceful connection handling. PureSimpleHTTPServer handles the core HTTP/1.1 protocol, but Caddy handles the TLS termination and edge-server concerns that are complex to implement correctly and dangerous to get wrong. The architecture is: internet traffic hits Caddy on ports 80/443, Caddy terminates TLS and proxies to PureSimple on `localhost:8080`, and PureSimple handles routing and application logic. This separation lets each component focus on what it does best.

---

## Chapter 20: Testing

### Question 1

**Q:** Why should you call `ResetMiddleware()`, `Session::ClearStore()`, and `Config::Reset()` between test suites?

**A:** These functions restore global state to a clean baseline. Without them, middleware registered in one test suite leaks into subsequent suites, causing unexpected handler chains. Session data from one test could satisfy authentication checks in another, producing false-passing tests. Config values set in one suite could change the behaviour of the next. The general principle is test isolation: every suite should start from a known, clean state so that tests pass or fail based on their own logic, not on execution order. Call these reset functions in the setup section of each suite, before registering any new middleware or config.

### Question 2 (Try it)

**Q:** Write a test suite for a new handler.

**A:**

```purebasic
; Listing E.6 -- Testing a handler
EnableExplicit
XIncludeFile "../../src/PureSimple.pb"
XIncludeFile "../../tests/TestHarness.pbi"

; The handler under test
Procedure GreetHandler(*C.RequestContext)
  Protected name.s = Binding::Query(*C, "name")
  If name = ""
    name = "World"
  EndIf
  Rendering::JSON(*C,
    ~"{\"greeting\":\"Hello, " + name + ~"!\"}")
EndProcedure

OpenConsole()

; Reset state
Engine::ResetMiddleware()

BeginSuite("GreetHandler Tests")

; Test 1: default greeting when no name provided
Protected c1.RequestContext
Ctx::Init(@c1, 0)
c1\Method = "GET"
c1\Path = "/greet"
c1\RawQuery = ""
GreetHandler(@c1)
CheckEqual(c1\StatusCode, 200)
CheckStr(c1\ContentType, "application/json")
Check(FindString(c1\ResponseBody, "Hello, World!") > 0)

; Test 2: greeting with a name
Protected c2.RequestContext
Ctx::Init(@c2, 1)
c2\Method = "GET"
c2\Path = "/greet"
c2\RawQuery = "name=Alice"
GreetHandler(@c2)
CheckEqual(c2\StatusCode, 200)
Check(FindString(c2\ResponseBody, "Hello, Alice!") > 0)

; Test 3: greeting with a URL-encoded name
Protected c3.RequestContext
Ctx::Init(@c3, 2)
c3\Method = "GET"
c3\Path = "/greet"
c3\RawQuery = "name=Bob+Smith"
GreetHandler(@c3)
CheckEqual(c3\StatusCode, 200)
Check(FindString(c3\ResponseBody, "Hello, Bob Smith!") > 0)

PrintResults()
CloseConsole()
```

---

## Chapter 21: Building a REST API (To-Do List)

### Question 1

**Q:** What is the difference between in-memory storage and SQLite persistence for a To-Do API?

**A:** In-memory storage (using PureBasic maps or lists) is fast and simple but loses all data when the server restarts. It is suitable for prototyping, demos, and tests. SQLite persistence writes data to a file on disk, surviving server restarts and providing ACID guarantees (atomicity, consistency, isolation, durability). For a production To-Do API, SQLite is the minimum viable choice. The transition from in-memory to SQLite requires replacing direct map operations with `DB::Exec` and `DB::Query` calls, but the handler signatures and JSON responses remain the same.

### Question 2

**Q:** How would you add authentication to the To-Do API?

**A:** Create a route group for the API endpoints and attach the BasicAuth middleware to the group. All routes within the group require valid credentials. The health check endpoint stays outside the group so monitoring tools can access it without authentication.

```purebasic
BasicAuth::SetCredentials("admin", "secret")

Protected api.PS_RouterGroup
Group::Init(@api, "/api")
Group::Use(@api, @BasicAuth::Middleware())

Group::GET(@api,    "/todos",     @ListTodos())
Group::POST(@api,   "/todos",     @CreateTodo())
Group::GET(@api,    "/todos/:id", @GetTodo())
Group::PUT(@api,    "/todos/:id", @UpdateTodo())
Group::DELETE(@api, "/todos/:id", @DeleteTodo())

; Health check outside the auth group
Engine::GET("/health", @HealthCheck())
```

---

## Chapter 22: Building a Blog

### Question 1

**Q:** What is the `PostsToStr` pipe-delimited data pattern, and why does the blog use it?

**A:** `PostsToStr` serialises a list of database rows into a single string where rows are separated by newlines (`\n`) and fields within each row are separated by pipes (`|`). For example: `"Post Title|post-slug|2026-01-15|Summary text\nAnother Post|another|2026-01-16|More text"`. The template then uses `{{ posts|split('\n') }}` to iterate rows and `{{ row|split('|') }}` to access fields. This pattern exists because PureJinja's template context is a flat KV store of strings (not structured objects). Rather than passing complex data structures through the template engine, the blog serialises data into delimited strings and uses PureJinja's `split` filter to reconstruct the structure in the template. It is simple, efficient, and avoids the need for a custom object serialisation layer.

### Question 2

**Q:** What is the Post-Redirect-Get (PRG) pattern and why does the contact form use it?

**A:** PRG is a web development pattern that prevents duplicate form submissions. When a user submits the contact form (POST), the handler processes the data (saves to database), then responds with a 302 redirect to a confirmation page (GET) rather than directly rendering a response. If the user refreshes the confirmation page, the browser repeats the GET request, not the POST. Without PRG, refreshing would resubmit the form, potentially creating duplicate contact messages. PureSimple implements PRG with `Rendering::Redirect(*C, "/contact/ok")` after successful form processing.

### Question 3 (Try it)

**Q:** Add a tag system to the blog.

**A:** This requires three components: a tags table, a post-tag join table, and migrations to create them.

```purebasic
; Listing E.7 -- Tag system migrations
DB::AddMigration(11,
  "CREATE TABLE IF NOT EXISTS tags (" +
  "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
  "name TEXT NOT NULL UNIQUE, " +
  "slug TEXT NOT NULL UNIQUE)")

DB::AddMigration(12,
  "CREATE TABLE IF NOT EXISTS post_tags (" +
  "post_id INTEGER NOT NULL, " +
  "tag_id INTEGER NOT NULL, " +
  "PRIMARY KEY (post_id, tag_id), " +
  "FOREIGN KEY (post_id) REFERENCES posts(id), " +
  "FOREIGN KEY (tag_id) REFERENCES tags(id))")

DB::AddMigration(13,
  "INSERT INTO tags (name, slug) VALUES " +
  "('PureBasic', 'purebasic')")

DB::AddMigration(14,
  "INSERT INTO tags (name, slug) VALUES " +
  "('Web Development', 'web-development')")
```

Handler to display posts by tag:

```purebasic
Procedure TagHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")

  DB::BindStr(_db, 0, slug)
  DB::Query(_db,
    "SELECT p.title, p.slug, p.created_at " +
    "FROM posts p " +
    "JOIN post_tags pt ON p.id = pt.post_id " +
    "JOIN tags t ON t.id = pt.tag_id " +
    "WHERE t.slug = ?")

  Protected posts.s = ""
  While DB::NextRow(_db)
    If posts <> "" : posts + ~"\n" : EndIf
    posts + DB::GetStr(_db, 0) + "|" +
            DB::GetStr(_db, 1) + "|" +
            DB::GetStr(_db, 2)
  Wend
  DB::Done(_db)

  Ctx::Set(*C, "posts", posts)
  Ctx::Set(*C, "tag", slug)
  Rendering::Render(*C, "tag.html")
EndProcedure

Engine::GET("/tag/:slug", @TagHandler())
```

---

## Chapter 23: Multi-Database Support

### Question 1

**Q:** How does `DBConnect::Open` determine which database driver to use?

**A:** `DBConnect::Open` examines the DSN (Data Source Name) prefix to determine the driver. A DSN starting with `sqlite:` activates the SQLite driver and passes the remainder as the file path (or `:memory:` for in-memory). A DSN starting with `postgres://` or `postgresql://` activates the PostgreSQL driver, parses the URL to extract host, port, database name, and credentials, and opens a PostgreSQL connection. A DSN starting with `mysql://` does the same for MySQL. Internally, `DBConnect::Driver(DSN)` returns a driver constant (`#Driver_SQLite`, `#Driver_Postgres`, `#Driver_MySQL`, or `#Driver_Unknown`), and `Open` dispatches to `OpenDatabase()` with the appropriate driver constant (`#PB_Database_SQLite`, `#PB_Database_PostgreSQL`, or `#PB_Database_MySQL`). The returned handle is compatible with all `DB::*` procedures, so application code does not need to change when switching databases.

### Question 2

**Q:** What is the advantage of reading the database DSN from configuration rather than hardcoding it?

**A:** Reading the DSN from configuration (via `DBConnect::OpenFromConfig()`, which reads the `DB_DSN` key from the `.env` file) decouples the application code from the database it connects to. The same binary can connect to an in-memory SQLite for tests, a file-based SQLite for development, and a PostgreSQL server for production, simply by changing the `.env` file. No recompilation is needed. This follows the twelve-factor app principle of storing configuration in the environment. It also means database credentials never appear in source code, reducing the risk of accidental exposure through version control.

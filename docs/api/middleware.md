# Middleware

PureSimple ships six middleware modules in `src/Middleware/`.

## Logger

`src/Middleware/Logger.pbi`

```purebasic
Engine::Use(@Logger::Middleware())
```

Logs one line per request **after** the downstream chain returns:

```
[LOG] GET /users/42 -> 200 (3ms)
```

Uses `ElapsedMilliseconds()` for timing. Output goes to stdout via `PrintN`.

---

## Recovery

`src/Middleware/Recovery.pbi`

```purebasic
Engine::Use(@Recovery::Middleware())
```

Installs an `OnErrorGoto` checkpoint around the downstream chain. On a
PureBasic runtime error, writes a `500 Internal Server Error` response and
resumes cleanly.

> **macOS arm64 note**: OS signals (SIGSEGV, SIGHUP from `RaiseError`) are not
> interceptable via `OnErrorGoto` on macOS arm64. Recovery works reliably on
> Linux and Windows.

---

## Cookie

`src/Middleware/Cookie.pbi`

```purebasic
; Read incoming cookie
val = Cookie::Get(*C, "session_id")

; Write response cookie
Cookie::Set(*C, "name", "value")
Cookie::Set(*C, "name", "value", "/", 3600)   ; with path and Max-Age seconds
```

`Cookie::Get` parses `*C\Cookie` (raw `Cookie:` header, semicolon-delimited
`name=value` pairs). `Cookie::Set` appends `Set-Cookie` directives to
`*C\SetCookies` (Chr(10)-delimited); the HTTP server sends them in the
response.

---

## Session

`src/Middleware/Session.pbi`

```purebasic
Engine::Use(@Session::Middleware())

; Inside a handler:
val = Session::Get(*C, "user_id")
Session::Set(*C, "user_id", "42")
sid = Session::ID(*C)
Session::Save(*C)      ; auto-called by middleware after chain
Session::ClearStore()  ; wipe all sessions (for tests)
```

Sessions are stored in a global in-memory map (`sessionID → serialised KV`).
The session ID is a 32-char random hex string stored in the `_psid` cookie.

`Session::Set` always appends; `Session::Get` returns the **last** value for a
key (last-write-wins). `Session::Middleware` auto-saves after `Ctx::Advance`
returns.

---

## BasicAuth

`src/Middleware/BasicAuth.pbi`

```purebasic
BasicAuth::SetCredentials("user", "password")
Engine::Use(@BasicAuth::Middleware())

; Inside a handler, if auth succeeded:
user = Ctx::Get(*C, "_auth_user")
```

Decodes the `Authorization: Basic <base64>` header. Aborts with `401
Unauthorized` if the header is missing, malformed, or credentials do not match.
On success, stores the authenticated username in the KV store under `_auth_user`.

---

## CSRF

`src/Middleware/CSRF.pbi`

```purebasic
; Requires Session middleware registered first
Engine::Use(@Session::Middleware())
Engine::Use(@CSRF::Middleware())

; Generate and embed a token in an HTML form:
CSRF::SetToken(*C)
token = Session::Get(*C, "_csrf_token")

; In the HTML template:
; <input type="hidden" name="_csrf" value="{{ _csrf_token }}">
```

`CSRF::Middleware` skips `GET` and `HEAD` requests. For all other methods it
reads the `_csrf` form field (via `Binding::PostForm`) and compares it against
the token stored in the session. Aborts with `403 Forbidden` on mismatch.

```purebasic
; Manual token generation (e.g. for JSON APIs using a custom header):
token = CSRF::GenerateToken()
CSRF::SetToken(*C)                         ; stores in session + cookie
ok    = CSRF::ValidateToken(*C, token)     ; #True if match
```

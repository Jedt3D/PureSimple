; P4_Rendering_Test.pbi — Tests for the Rendering module

Global P4_ctx.RequestContext

; =================================================================
; Suite: Rendering::JSON
; =================================================================
BeginSuite("P4 / Rendering — JSON")

Ctx::Init(@P4_ctx, "GET", "/api/hello")

Rendering::JSON(@P4_ctx, ~"{\"ok\":true}")

CheckEqual(P4_ctx\StatusCode,  200)
CheckStr(P4_ctx\ContentType,   "application/json")
CheckStr(P4_ctx\ResponseBody,  ~"{\"ok\":true}")

; Custom status code
Rendering::JSON(@P4_ctx, ~"{\"error\":\"not found\"}", 404)
CheckEqual(P4_ctx\StatusCode, 404)

; =================================================================
; Suite: Rendering::HTML
; =================================================================
BeginSuite("P4 / Rendering — HTML")

Ctx::Init(@P4_ctx, "GET", "/")

Rendering::HTML(@P4_ctx, "<h1>Hello</h1>")

CheckEqual(P4_ctx\StatusCode, 200)
CheckStr(P4_ctx\ContentType,  "text/html")
CheckStr(P4_ctx\ResponseBody, "<h1>Hello</h1>")

; =================================================================
; Suite: Rendering::Text
; =================================================================
BeginSuite("P4 / Rendering — Text")

Ctx::Init(@P4_ctx, "GET", "/ping")

Rendering::Text(@P4_ctx, "pong")

CheckEqual(P4_ctx\StatusCode, 200)
CheckStr(P4_ctx\ContentType,  "text/plain")
CheckStr(P4_ctx\ResponseBody, "pong")

; =================================================================
; Suite: Rendering::Status
; =================================================================
BeginSuite("P4 / Rendering — Status")

Ctx::Init(@P4_ctx, "GET", "/empty")

Rendering::Status(@P4_ctx, 204)

CheckEqual(P4_ctx\StatusCode, 204)

; =================================================================
; Suite: Rendering::Redirect
; =================================================================
BeginSuite("P4 / Rendering — Redirect")

Ctx::Init(@P4_ctx, "GET", "/old")

Rendering::Redirect(@P4_ctx, "/new")

CheckEqual(P4_ctx\StatusCode, 302)
CheckStr(P4_ctx\Location,     "/new")

; Permanent redirect
Rendering::Redirect(@P4_ctx, "/permanent", 301)
CheckEqual(P4_ctx\StatusCode, 301)
CheckStr(P4_ctx\Location,     "/permanent")

; =================================================================
; Suite: Rendering::File — missing file returns 404
; =================================================================
BeginSuite("P4 / Rendering — File missing")

Ctx::Init(@P4_ctx, "GET", "/missing")

Rendering::File(@P4_ctx, "no_such_file.html")

CheckEqual(P4_ctx\StatusCode, 404)

; =================================================================
; Suite: Rendering::Render — PureJinja template
; =================================================================
BeginSuite("P4 / Rendering — Render template")

Ctx::Init(@P4_ctx, "GET", "/hello")
Ctx::Set(@P4_ctx, "name", "Alice")
Ctx::Set(@P4_ctx, "age",  "30")

Rendering::Render(@P4_ctx, "test.html", "templates/")

CheckEqual(P4_ctx\StatusCode, 200)
CheckStr(P4_ctx\ContentType,  "text/html")
; Template: "Hello, {{ name }}! You are {{ age }} years old.\n"
CheckStr(P4_ctx\ResponseBody, "Hello, Alice! You are 30 years old." + #LF$)

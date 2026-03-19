; P3_Binding_Test.pbi — Tests for the Binding module

Global P3_ctx.RequestContext

; =================================================================
; Suite: Binding::Param — delegates to Ctx::Param
; =================================================================
BeginSuite("P3 / Binding — Param")

Ctx::Init(@P3_ctx, "GET", "/users/42")
P3_ctx\ParamKeys = "id" + Chr(9)
P3_ctx\ParamVals = "42" + Chr(9)

CheckStr(Binding::Param(@P3_ctx, "id"),      "42")
CheckStr(Binding::Param(@P3_ctx, "missing"), "")

; =================================================================
; Suite: Binding::Query — lazy query string parsing
; =================================================================
BeginSuite("P3 / Binding — Query")

Ctx::Init(@P3_ctx, "GET", "/search")
P3_ctx\RawQuery = "page=2&limit=10&q=hello+world"

CheckStr(Binding::Query(@P3_ctx, "page"),    "2")
CheckStr(Binding::Query(@P3_ctx, "limit"),   "10")
CheckStr(Binding::Query(@P3_ctx, "q"),       "hello world")   ; + -> space
CheckStr(Binding::Query(@P3_ctx, "missing"), "")

; Second call uses cached QueryKeys/QueryVals (no re-parse)
CheckStr(Binding::Query(@P3_ctx, "page"),    "2")

; =================================================================
; Suite: Binding::Query — percent-encoded values
; =================================================================
BeginSuite("P3 / Binding — Query percent-encoding")

Ctx::Init(@P3_ctx, "GET", "/items")
P3_ctx\RawQuery = "tag=a%2Fb&name=hello%20world"

CheckStr(Binding::Query(@P3_ctx, "tag"),  "a/b")       ; %2F -> /
CheckStr(Binding::Query(@P3_ctx, "name"), "hello world") ; %20 -> space

; =================================================================
; Suite: Binding::PostForm — URL-encoded form body
; =================================================================
BeginSuite("P3 / Binding — PostForm")

Ctx::Init(@P3_ctx, "POST", "/login")
P3_ctx\Body = "username=alice&password=secret&remember=1"

CheckStr(Binding::PostForm(@P3_ctx, "username"), "alice")
CheckStr(Binding::PostForm(@P3_ctx, "password"), "secret")
CheckStr(Binding::PostForm(@P3_ctx, "remember"), "1")
CheckStr(Binding::PostForm(@P3_ctx, "missing"),  "")

; =================================================================
; Suite: Binding::PostForm — URL-decoded form values
; =================================================================
BeginSuite("P3 / Binding — PostForm URL decoding")

Ctx::Init(@P3_ctx, "POST", "/search")
P3_ctx\Body = "q=hello+world&tag=a%2Fb"

CheckStr(Binding::PostForm(@P3_ctx, "q"),   "hello world")
CheckStr(Binding::PostForm(@P3_ctx, "tag"), "a/b")

; =================================================================
; Suite: Binding::BindJSON + JSONString/JSONInteger/JSONBool
; =================================================================
BeginSuite("P3 / Binding — BindJSON")

Ctx::Init(@P3_ctx, "POST", "/api/users")
P3_ctx\Body = ~"{\"name\":\"bob\",\"age\":30,\"active\":true}"

Global P3_jsonHandle.i = Binding::BindJSON(@P3_ctx)

CheckEqual(Bool(P3_jsonHandle <> 0), 1)                ; parse succeeded
CheckStr(Binding::JSONString(@P3_ctx, "name"),   "bob")
CheckEqual(Binding::JSONInteger(@P3_ctx, "age"), 30)
CheckEqual(Binding::JSONBool(@P3_ctx, "active"), 1)

CheckStr(Binding::JSONString(@P3_ctx,  "missing"), "") ; missing key -> ""
CheckEqual(Binding::JSONInteger(@P3_ctx, "missing"), 0) ; missing key -> 0

; =================================================================
; Suite: Binding::ReleaseJSON
; =================================================================
BeginSuite("P3 / Binding — ReleaseJSON")

; JSONHandle is still set from previous suite — release it
Binding::ReleaseJSON(@P3_ctx)
CheckEqual(P3_ctx\JSONHandle, 0)

; Calling accessors after release returns safe defaults
CheckStr(Binding::JSONString(@P3_ctx, "name"), "")
CheckEqual(Binding::JSONInteger(@P3_ctx, "age"), 0)

; =================================================================
; Suite: Binding::BindJSON — invalid JSON returns 0
; =================================================================
BeginSuite("P3 / Binding — BindJSON invalid body")

Ctx::Init(@P3_ctx, "POST", "/api/bad")
P3_ctx\Body = "this is not json"

Global P3_bad.i = Binding::BindJSON(@P3_ctx)
CheckEqual(P3_bad, 0)
CheckEqual(P3_ctx\JSONHandle, 0)

; =================================================================
; Suite: Binding::BindJSON — empty body returns 0
; =================================================================
BeginSuite("P3 / Binding — BindJSON empty body")

Ctx::Init(@P3_ctx, "POST", "/api/empty")
; Body defaults to "" after Init

Global P3_empty.i = Binding::BindJSON(@P3_ctx)
CheckEqual(P3_empty, 0)

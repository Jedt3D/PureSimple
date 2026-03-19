; P7_Auth_Test.pbi — Tests for Cookie, Session, BasicAuth, CSRF

Global P7_ctx.RequestContext

; Helper: base64-encode a plain ASCII string
Procedure.s P7_EncodeB64(plain.s)
  Protected len.i = Len(plain)
  Protected *in   = AllocateMemory(len + 1)
  If *in = 0 : ProcedureReturn "" : EndIf
  PokeS(*in, plain, len, #PB_Ascii)
  Protected result.s = Base64Encoder(*in, len)
  FreeMemory(*in)
  ProcedureReturn result
EndProcedure

; Thin wrappers — module proc addresses can't be used in Global inits
Procedure P7_SessionMW(*C.RequestContext)
  Session::Middleware(*C)
EndProcedure
Procedure P7_BasicAuthMW(*C.RequestContext)
  BasicAuth::Middleware(*C)
EndProcedure
Procedure P7_CSRFMw(*C.RequestContext)
  CSRF::Middleware(*C)
EndProcedure
Procedure P7_SetBodyHandler(*C.RequestContext)
  *C\ResponseBody = "ok"
EndProcedure

; =================================================================
; Suite: Cookie::Get — parse incoming Cookie header
; =================================================================
BeginSuite("P7 / Cookie — Get")

Ctx::Init(@P7_ctx, "GET", "/")
P7_ctx\Cookie = "session=abc123; theme=dark; user=alice"

CheckStr(Cookie::Get(@P7_ctx, "session"), "abc123")
CheckStr(Cookie::Get(@P7_ctx, "theme"),   "dark")
CheckStr(Cookie::Get(@P7_ctx, "user"),    "alice")
CheckStr(Cookie::Get(@P7_ctx, "missing"), "")

; =================================================================
; Suite: Cookie::Set — generate Set-Cookie directives
; =================================================================
BeginSuite("P7 / Cookie — Set")

Ctx::Init(@P7_ctx, "GET", "/")
Cookie::Set(@P7_ctx, "foo", "bar")
Cookie::Set(@P7_ctx, "id",  "42", "/api", 3600)

CheckEqual(CountString(P7_ctx\SetCookies, Chr(10)) + 1, 2)
CheckStr(StringField(P7_ctx\SetCookies, 1, Chr(10)), "foo=bar; Path=/")
CheckStr(StringField(P7_ctx\SetCookies, 2, Chr(10)), "id=42; Path=/api; Max-Age=3600")

; =================================================================
; Suite: Session — new session created when no cookie present
; =================================================================
BeginSuite("P7 / Session — new session on first request")

Session::ClearStore()
Engine::ResetMiddleware()
Ctx::Init(@P7_ctx, "GET", "/")
Ctx::AddHandler(@P7_ctx, @P7_SessionMW())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(Bool(Session::ID(@P7_ctx) <> ""),          1)
CheckEqual(Bool(Len(Session::ID(@P7_ctx)) = 32),      1)   ; 32-char hex ID
CheckEqual(Bool(FindString(P7_ctx\SetCookies, "_psid=") > 0), 1)

; =================================================================
; Suite: Session::Get / Set — direct API, last-write-wins
; =================================================================
BeginSuite("P7 / Session — Get and Set")

Ctx::Init(@P7_ctx, "GET", "/profile")
P7_ctx\SessionID = "test_sid"   ; assign a known session ID

Session::Set(@P7_ctx, "user_id", "99")
Session::Set(@P7_ctx, "role",    "admin")

CheckStr(Session::Get(@P7_ctx, "user_id"), "99")
CheckStr(Session::Get(@P7_ctx, "role"),    "admin")
CheckStr(Session::Get(@P7_ctx, "missing"), "")

; last-write-wins: set same key again
Session::Set(@P7_ctx, "user_id", "100")
CheckStr(Session::Get(@P7_ctx, "user_id"), "100")

; =================================================================
; Suite: Session — data persists across request boundaries
; =================================================================
BeginSuite("P7 / Session — persistence across requests")

Session::ClearStore()

; Request 1: dispatch through session middleware (creates new session)
Ctx::Init(@P7_ctx, "POST", "/login")
Ctx::AddHandler(@P7_ctx, @P7_SessionMW())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)
Global P7_sid.s = P7_ctx\SessionID
Session::Set(@P7_ctx, "logged_in", "1")
Session::Save(@P7_ctx)

; Request 2: same session ID via cookie
Ctx::Init(@P7_ctx, "GET", "/dashboard")
P7_ctx\Cookie = "_psid=" + P7_sid
Ctx::AddHandler(@P7_ctx, @P7_SessionMW())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckStr(P7_ctx\SessionID,                    P7_sid)   ; same session
CheckStr(Session::Get(@P7_ctx, "logged_in"),  "1")      ; data persisted

Session::ClearStore()

; =================================================================
; Suite: BasicAuth::Middleware — valid credentials pass
; =================================================================
BeginSuite("P7 / BasicAuth — valid credentials")

BasicAuth::SetCredentials("alice", "secret")
Ctx::Init(@P7_ctx, "GET", "/protected")
P7_ctx\Authorization = "Basic " + P7_EncodeB64("alice:secret")
Ctx::AddHandler(@P7_ctx, @P7_BasicAuthMW())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(P7_ctx\StatusCode,                     200)
CheckEqual(Ctx::IsAborted(@P7_ctx),               0)
CheckStr(Ctx::Get(@P7_ctx, "_auth_user"),         "alice")
CheckStr(P7_ctx\ResponseBody,                     "ok")

; =================================================================
; Suite: BasicAuth::Middleware — wrong password aborts 401
; =================================================================
BeginSuite("P7 / BasicAuth — wrong password")

BasicAuth::SetCredentials("alice", "secret")
Ctx::Init(@P7_ctx, "GET", "/protected")
P7_ctx\Authorization = "Basic " + P7_EncodeB64("alice:wrong")
Ctx::AddHandler(@P7_ctx, @P7_BasicAuthMW())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(P7_ctx\StatusCode,       401)
CheckEqual(Ctx::IsAborted(@P7_ctx), 1)
CheckStr(P7_ctx\ResponseBody,       "Unauthorized")

; =================================================================
; Suite: BasicAuth::Middleware — missing header aborts 401
; =================================================================
BeginSuite("P7 / BasicAuth — missing Authorization header")

BasicAuth::SetCredentials("alice", "secret")
Ctx::Init(@P7_ctx, "GET", "/protected")
; Authorization defaults to "" after Init
Ctx::AddHandler(@P7_ctx, @P7_BasicAuthMW())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(P7_ctx\StatusCode,       401)
CheckEqual(Ctx::IsAborted(@P7_ctx), 1)

; =================================================================
; Suite: CSRF::GenerateToken — 32-char hex string, unique
; =================================================================
BeginSuite("P7 / CSRF — GenerateToken")

Global P7_tok1.s = CSRF::GenerateToken()
Global P7_tok2.s = CSRF::GenerateToken()

CheckEqual(Len(P7_tok1),                  32)
CheckEqual(Bool(P7_tok1 <> ""),            1)
CheckEqual(Bool(P7_tok1 <> P7_tok2),       1)   ; extremely unlikely to collide

; =================================================================
; Suite: CSRF::SetToken + ValidateToken
; =================================================================
BeginSuite("P7 / CSRF — SetToken and ValidateToken")

Session::ClearStore()
Ctx::Init(@P7_ctx, "GET", "/form")
P7_ctx\SessionID = "csrf_test_sess"

CSRF::SetToken(@P7_ctx)
Global P7_csrf.s = Session::Get(@P7_ctx, "_csrf_token")

CheckEqual(Len(P7_csrf),                           32)
CheckEqual(CSRF::ValidateToken(@P7_ctx, P7_csrf),   1)   ; correct token
CheckEqual(CSRF::ValidateToken(@P7_ctx, "bad"),      0)   ; wrong token

; Context with no session token → always fails
Ctx::Init(@P7_ctx, "POST", "/form")
CheckEqual(CSRF::ValidateToken(@P7_ctx, P7_csrf),   0)

Session::ClearStore()

; =================================================================
; Suite: CSRF::Middleware — GET passes without token check
; =================================================================
BeginSuite("P7 / CSRF — Middleware GET passes")

Ctx::Init(@P7_ctx, "GET", "/page")
Ctx::AddHandler(@P7_ctx, @P7_CSRFMw())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(P7_ctx\StatusCode,       200)
CheckEqual(Ctx::IsAborted(@P7_ctx), 0)
CheckStr(P7_ctx\ResponseBody,       "ok")

; =================================================================
; Suite: CSRF::Middleware — POST with valid token passes
; =================================================================
BeginSuite("P7 / CSRF — Middleware POST valid token")

Session::ClearStore()
Global P7_csrf2.s = CSRF::GenerateToken()

Ctx::Init(@P7_ctx, "POST", "/submit")
P7_ctx\SessionID   = "post_sess"
P7_ctx\SessionKeys = "_csrf_token" + Chr(9)
P7_ctx\SessionVals = P7_csrf2 + Chr(9)
P7_ctx\Body        = "_csrf=" + P7_csrf2

Ctx::AddHandler(@P7_ctx, @P7_CSRFMw())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(P7_ctx\StatusCode,       200)
CheckEqual(Ctx::IsAborted(@P7_ctx), 0)
CheckStr(P7_ctx\ResponseBody,       "ok")

Session::ClearStore()

; =================================================================
; Suite: CSRF::Middleware — POST with wrong token aborts 403
; =================================================================
BeginSuite("P7 / CSRF — Middleware POST invalid token")

Session::ClearStore()

Ctx::Init(@P7_ctx, "POST", "/submit")
P7_ctx\SessionID   = "bad_sess"
P7_ctx\SessionKeys = "_csrf_token" + Chr(9)
P7_ctx\SessionVals = "realtoken" + Chr(9)
P7_ctx\Body        = "_csrf=wrongtoken"

Ctx::AddHandler(@P7_ctx, @P7_CSRFMw())
Ctx::AddHandler(@P7_ctx, @P7_SetBodyHandler())
Ctx::Dispatch(@P7_ctx)

CheckEqual(P7_ctx\StatusCode,       403)
CheckEqual(Ctx::IsAborted(@P7_ctx), 1)
CheckStr(P7_ctx\ResponseBody,       "CSRF token invalid or missing")

Session::ClearStore()
Engine::ResetMiddleware()

; P1_Router_Test.pbi — Tests for Router and Context modules

; =================================================================
; Global flags for handler chain tests (declared before procedures
; that reference them)
; =================================================================
Global _P1_h1.i = 0
Global _P1_h2.i = 0
Global _P1_h3.i = 0
Global _P1_ha.i = 0

; =================================================================
; Handler procedures — all defined before registration or test code
; =================================================================

; Stub handlers for router registration tests (no logic needed)
Procedure P1_HelloHandler(*C.RequestContext) : EndProcedure
Procedure P1_UserHandler(*C.RequestContext)  : EndProcedure
Procedure P1_FileHandler(*C.RequestContext)  : EndProcedure
Procedure P1_ExactHandler(*C.RequestContext) : EndProcedure
Procedure P1_ParamHandler(*C.RequestContext) : EndProcedure

; Handler chain test procedures
Procedure P1_H1(*C.RequestContext)
  _P1_h1 = 1
  Ctx::Advance(*C)     ; pass control downstream
EndProcedure

Procedure P1_H2(*C.RequestContext)
  _P1_h2 = 1
  Ctx::Advance(*C)
EndProcedure

Procedure P1_H3(*C.RequestContext)
  _P1_h3 = 1
  ; Last handler — intentionally does not call Next()
EndProcedure

Procedure P1_HAbort(*C.RequestContext)
  _P1_ha = 1
  Ctx::Abort(*C)    ; stops the chain; does not call Next()
EndProcedure

; =================================================================
; Route registration
; =================================================================
Engine::GET("/hello",       @P1_HelloHandler())
Engine::GET("/users/:id",   @P1_UserHandler())
Engine::GET("/files/*path", @P1_FileHandler())
Engine::GET("/items/:id",   @P1_ParamHandler())
Engine::GET("/items/new",   @P1_ExactHandler())

; =================================================================
; Test variables
; =================================================================
Global P1_ctx.RequestContext
Global P1_ctx2.RequestContext
Global P1_h.i

; =================================================================
; Suite: Router — exact match
; =================================================================
BeginSuite("P1 / Router — exact match")

Ctx::Init(@P1_ctx, "GET", "/")

P1_h = Router::Match("GET", "/hello", @P1_ctx)
CheckEqual(Bool(P1_h <> 0), 1)     ; handler found

P1_h = Router::Match("POST", "/hello", @P1_ctx)
CheckEqual(P1_h, 0)                ; wrong method — not found

P1_h = Router::Match("GET", "/nope", @P1_ctx)
CheckEqual(P1_h, 0)                ; unregistered path — not found

; =================================================================
; Suite: Router — named params
; =================================================================
BeginSuite("P1 / Router — named params")

Ctx::Init(@P1_ctx, "GET", "/")
P1_h = Router::Match("GET", "/users/42", @P1_ctx)
CheckEqual(Bool(P1_h <> 0), 1)
CheckStr(Ctx::Param(@P1_ctx, "id"), "42")

Ctx::Init(@P1_ctx, "GET", "/")
P1_h = Router::Match("GET", "/users/alice", @P1_ctx)
CheckEqual(Bool(P1_h <> 0), 1)
CheckStr(Ctx::Param(@P1_ctx, "id"), "alice")

; =================================================================
; Suite: Router — wildcard
; =================================================================
BeginSuite("P1 / Router — wildcard")

Ctx::Init(@P1_ctx, "GET", "/")
P1_h = Router::Match("GET", "/files/a/b/c", @P1_ctx)
CheckEqual(Bool(P1_h <> 0), 1)
CheckStr(Ctx::Param(@P1_ctx, "path"), "a/b/c")

; =================================================================
; Suite: Router — exact beats param
; =================================================================
BeginSuite("P1 / Router — exact beats param")

Ctx::Init(@P1_ctx, "GET", "/")
P1_h = Router::Match("GET", "/items/new", @P1_ctx)
CheckEqual(P1_h, @P1_ExactHandler())   ; "new" matches exact, not :id

Ctx::Init(@P1_ctx, "GET", "/")
P1_h = Router::Match("GET", "/items/99", @P1_ctx)
CheckEqual(P1_h, @P1_ParamHandler())   ; "99" falls through to :id param
CheckStr(Ctx::Param(@P1_ctx, "id"), "99")

; =================================================================
; Suite: Context — Param extraction
; =================================================================
BeginSuite("P1 / Context — Param extraction")

Ctx::Init(@P1_ctx2, "GET", "/api/99")
P1_ctx2\ParamKeys = "id" + Chr(9)
P1_ctx2\ParamVals = "99" + Chr(9)

CheckStr(Ctx::Param(@P1_ctx2, "id"), "99")
CheckStr(Ctx::Param(@P1_ctx2, "missing"), "")

; =================================================================
; Suite: Context — KV store
; =================================================================
BeginSuite("P1 / Context — KV store")

Ctx::Init(@P1_ctx2, "GET", "/")
Ctx::Set(@P1_ctx2, "user", "alice")
Ctx::Set(@P1_ctx2, "role", "admin")

CheckStr(Ctx::Get(@P1_ctx2, "user"), "alice")
CheckStr(Ctx::Get(@P1_ctx2, "role"), "admin")
CheckStr(Ctx::Get(@P1_ctx2, "none"), "")

; =================================================================
; Suite: Context — handler chain (all pass)
; =================================================================
BeginSuite("P1 / Context — handler chain")

_P1_h1 = 0 : _P1_h2 = 0 : _P1_h3 = 0
Ctx::Init(@P1_ctx2, "GET", "/chain")
Ctx::AddHandler(@P1_ctx2, @P1_H1())
Ctx::AddHandler(@P1_ctx2, @P1_H2())
Ctx::AddHandler(@P1_ctx2, @P1_H3())
Ctx::Dispatch(@P1_ctx2)

CheckEqual(_P1_h1, 1)
CheckEqual(_P1_h2, 1)
CheckEqual(_P1_h3, 1)
CheckEqual(Ctx::IsAborted(@P1_ctx2), #False)

; =================================================================
; Suite: Context — Abort stops chain
; =================================================================
BeginSuite("P1 / Context — Abort")

_P1_h1 = 0 : _P1_ha = 0 : _P1_h2 = 0
Ctx::Init(@P1_ctx2, "GET", "/abort")
Ctx::AddHandler(@P1_ctx2, @P1_H1())
Ctx::AddHandler(@P1_ctx2, @P1_HAbort())
Ctx::AddHandler(@P1_ctx2, @P1_H2())
Ctx::Dispatch(@P1_ctx2)

CheckEqual(_P1_h1, 1)
CheckEqual(_P1_ha, 1)
CheckEqual(_P1_h2, 0)             ; not called after Abort
CheckEqual(Ctx::IsAborted(@P1_ctx2), #True)

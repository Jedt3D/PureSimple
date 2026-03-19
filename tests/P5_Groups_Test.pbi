; P5_Groups_Test.pbi — Tests for RouterGroup and structured error helpers

Global P5_ctx.RequestContext
Global P5_g.PS_RouterGroup
Global P5_g2.PS_RouterGroup

; Thin wrappers for module procedures (can't use @Module::Proc() in Global init)
Procedure P5_MW_A(*C.RequestContext)
  *C\ResponseBody + "A"
  Ctx::Advance(*C)
  *C\ResponseBody + "a"
EndProcedure

Procedure P5_MW_B(*C.RequestContext)
  *C\ResponseBody + "B"
  Ctx::Advance(*C)
  *C\ResponseBody + "b"
EndProcedure

Procedure P5_RouteHandler(*C.RequestContext)
  *C\ResponseBody + "R"
EndProcedure

Procedure P5_NotFoundHandler(*C.RequestContext)
  *C\StatusCode   = 404
  *C\ResponseBody = "custom 404"
  *C\ContentType  = "text/html"
EndProcedure

Procedure P5_MethodNotAllowedHandler(*C.RequestContext)
  *C\StatusCode   = 405
  *C\ResponseBody = "custom 405"
  *C\ContentType  = "text/html"
EndProcedure

; =================================================================
; Suite: Group::Init
; =================================================================
BeginSuite("P5 / Group — Init")

Group::Init(@P5_g, "/api")

CheckStr(P5_g\Prefix,   "/api")
CheckEqual(P5_g\MWCount, 0)

; =================================================================
; Suite: Group::Use
; =================================================================
BeginSuite("P5 / Group — Use")

Group::Init(@P5_g, "/api")
Group::Use(@P5_g, @P5_MW_A())
Group::Use(@P5_g, @P5_MW_B())

CheckEqual(P5_g\MWCount, 2)
CheckEqual(P5_g\MW[0], @P5_MW_A())
CheckEqual(P5_g\MW[1], @P5_MW_B())

; =================================================================
; Suite: Group::GET — route registered with prefix
; =================================================================
BeginSuite("P5 / Group — GET registers prefixed route")

Engine::ResetMiddleware()
Group::Init(@P5_g, "/api")
Group::GET(@P5_g, "/users", @P5_RouteHandler())

; Verify the combined route is in the router
Ctx::Init(@P5_ctx, "GET", "/api/users")
Global P5_h.i = Router::Match("GET", "/api/users", @P5_ctx)
CheckEqual(Bool(P5_h <> 0), 1)    ; route found
CheckEqual(P5_h, @P5_RouteHandler())

; Prefix-only path should NOT match
Ctx::Init(@P5_ctx, "GET", "/api")
Global P5_miss.i = Router::Match("GET", "/api", @P5_ctx)
CheckEqual(P5_miss, 0)

; =================================================================
; Suite: Group::SubGroup — inherits prefix and middleware
; =================================================================
BeginSuite("P5 / Group — SubGroup")

Group::Init(@P5_g, "/api")
Group::Use(@P5_g, @P5_MW_A())

Group::SubGroup(@P5_g, @P5_g2, "/v1")

CheckStr(P5_g2\Prefix,   "/api/v1")
CheckEqual(P5_g2\MWCount, 1)            ; inherited MW_A
CheckEqual(P5_g2\MW[0], @P5_MW_A())

; Register and match a nested route
Group::GET(@P5_g2, "/items", @P5_RouteHandler())
Ctx::Init(@P5_ctx, "GET", "/api/v1/items")
Global P5_nested.i = Router::Match("GET", "/api/v1/items", @P5_ctx)
CheckEqual(P5_nested, @P5_RouteHandler())

; =================================================================
; Suite: Group::CombineHandlers — global + group + route order
; =================================================================
BeginSuite("P5 / Group — CombineHandlers ordering")

Engine::ResetMiddleware()
Engine::Use(@P5_MW_A())             ; global: A

Group::Init(@P5_g, "/test")
Group::Use(@P5_g, @P5_MW_B())      ; group: B

Ctx::Init(@P5_ctx, "GET", "/test/go")
Group::CombineHandlers(@P5_g, @P5_ctx, @P5_RouteHandler())
Ctx::Dispatch(@P5_ctx)

; Onion order: A wraps B wraps R → A→B→R→b→a
CheckStr(P5_ctx\ResponseBody, "ABRba")

Engine::ResetMiddleware()

; =================================================================
; Suite: Group without global MW — only group + route
; =================================================================
BeginSuite("P5 / Group — CombineHandlers no global MW")

Engine::ResetMiddleware()
Group::Init(@P5_g, "/x")
Group::Use(@P5_g, @P5_MW_B())

Ctx::Init(@P5_ctx, "GET", "/x/go")
Group::CombineHandlers(@P5_g, @P5_ctx, @P5_RouteHandler())
Ctx::Dispatch(@P5_ctx)

CheckStr(P5_ctx\ResponseBody, "BRb")

Engine::ResetMiddleware()

; =================================================================
; Suite: Ctx::AbortWithStatus
; =================================================================
BeginSuite("P5 / Context — AbortWithStatus")

Ctx::Init(@P5_ctx, "GET", "/secret")
Ctx::AbortWithStatus(@P5_ctx, 403)

CheckEqual(P5_ctx\StatusCode, 403)
CheckEqual(Ctx::IsAborted(@P5_ctx), 1)

; =================================================================
; Suite: Ctx::AbortWithError
; =================================================================
BeginSuite("P5 / Context — AbortWithError")

Ctx::Init(@P5_ctx, "GET", "/bad")
Ctx::AbortWithError(@P5_ctx, 422, "Unprocessable Entity")

CheckEqual(P5_ctx\StatusCode,   422)
CheckStr(P5_ctx\ResponseBody,   "Unprocessable Entity")
CheckStr(P5_ctx\ContentType,    "text/plain")
CheckEqual(Ctx::IsAborted(@P5_ctx), 1)

; =================================================================
; Suite: Engine::HandleNotFound — default 404
; =================================================================
BeginSuite("P5 / Engine — HandleNotFound default")

Engine::ResetMiddleware()
Ctx::Init(@P5_ctx, "GET", "/no-such-route")
Engine::HandleNotFound(@P5_ctx)

CheckEqual(P5_ctx\StatusCode,   404)
CheckStr(P5_ctx\ResponseBody,   "404 Not Found")

; =================================================================
; Suite: Engine::SetNotFoundHandler — custom 404
; =================================================================
BeginSuite("P5 / Engine — SetNotFoundHandler custom")

Engine::SetNotFoundHandler(@P5_NotFoundHandler())
Ctx::Init(@P5_ctx, "GET", "/missing")
Engine::HandleNotFound(@P5_ctx)

CheckEqual(P5_ctx\StatusCode,   404)
CheckStr(P5_ctx\ResponseBody,   "custom 404")
CheckStr(P5_ctx\ContentType,    "text/html")

Engine::ResetMiddleware()   ; clears custom handlers too

; =================================================================
; Suite: Engine::HandleMethodNotAllowed — default 405
; =================================================================
BeginSuite("P5 / Engine — HandleMethodNotAllowed default")

Ctx::Init(@P5_ctx, "DELETE", "/read-only")
Engine::HandleMethodNotAllowed(@P5_ctx)

CheckEqual(P5_ctx\StatusCode,   405)
CheckStr(P5_ctx\ResponseBody,   "405 Method Not Allowed")

; =================================================================
; Suite: Engine::SetMethodNotAllowedHandler — custom 405
; =================================================================
BeginSuite("P5 / Engine — SetMethodNotAllowedHandler custom")

Engine::SetMethodNotAllowedHandler(@P5_MethodNotAllowedHandler())
Ctx::Init(@P5_ctx, "DELETE", "/read-only")
Engine::HandleMethodNotAllowed(@P5_ctx)

CheckEqual(P5_ctx\StatusCode,   405)
CheckStr(P5_ctx\ResponseBody,   "custom 405")
CheckStr(P5_ctx\ContentType,    "text/html")

Engine::ResetMiddleware()

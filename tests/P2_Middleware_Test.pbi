; P2_Middleware_Test.pbi — Tests for middleware engine (Logger, Recovery, Engine::Use)
;
; Note on Recovery panic tests:
;   PureBasic's OnErrorGoto intercepts PB-runtime errors (e.g. debugger-checked
;   bounds violations with -d). On macOS arm64, OS signals such as SIGSEGV and
;   SIGHUP reach the process before PB's setjmp checkpoint fires, so RaiseError /
;   null-pointer crash tests are platform-specific and run only on Linux/Windows.
;   Only the normal-flow Recovery path is tested here.

; =================================================================
; Global state flags for tracking handler execution order
; =================================================================
Global _P2_mw1.i   = 0   ; set by tracking middleware
Global _P2_after.i = 0   ; set AFTER Advance in tracking middleware
Global _P2_route.i = 0   ; set by route handler
Global _P2_seq.s   = ""  ; execution order trace for ordering test

; =================================================================
; Handler procedures
; =================================================================

; Middleware that records before/after Advance (tests wrap-around behaviour)
Procedure P2_TrackingMW(*C.RequestContext)
  _P2_mw1 = 1
  Ctx::Advance(*C)
  _P2_after = 1
EndProcedure

; Simple route handler — sets status 200 and marks itself run
Procedure P2_RouteHandler(*C.RequestContext)
  _P2_route = 1
  *C\StatusCode = 200
EndProcedure

; Ordering-test middleware: records entry letter before Advance, exit letter after
Procedure P2_MW_A(*C.RequestContext)
  _P2_seq + "A"
  Ctx::Advance(*C)
  _P2_seq + "a"
EndProcedure

Procedure P2_MW_B(*C.RequestContext)
  _P2_seq + "B"
  Ctx::Advance(*C)
  _P2_seq + "b"
EndProcedure

Procedure P2_MW_Route(*C.RequestContext)
  _P2_seq + "R"
EndProcedure

; Thin wrappers around module procedures.
; Global initialisers cannot resolve @Module::Proc() addresses; wrap them
; in named procedures and use @P2_LoggerMW() / @P2_RecoveryMW() instead.
Procedure P2_LoggerMW(*C.RequestContext)
  Logger::Middleware(*C)
EndProcedure

Procedure P2_RecoveryMW(*C.RequestContext)
  Recovery::Middleware(*C)
EndProcedure

; =================================================================
; Shared context
; =================================================================
Global P2_ctx.RequestContext

; =================================================================
; Suite: Engine::Use + CombineHandlers
; =================================================================
BeginSuite("P2 / Engine — Use + CombineHandlers")

Engine::ResetMiddleware()
_P2_mw1 = 0 : _P2_after = 0 : _P2_route = 0

Engine::Use(@P2_TrackingMW())
Ctx::Init(@P2_ctx, "GET", "/mw-test")
Engine::CombineHandlers(@P2_ctx, @P2_RouteHandler())
Ctx::Dispatch(@P2_ctx)

CheckEqual(_P2_mw1,   1)   ; middleware ran before route handler
CheckEqual(_P2_route, 1)   ; route handler ran
CheckEqual(_P2_after, 1)   ; post-Advance code in middleware ran
CheckEqual(P2_ctx\StatusCode, 200)

Engine::ResetMiddleware()

; =================================================================
; Suite: multiple global middleware — correct execution order
; =================================================================
BeginSuite("P2 / Engine — multiple middleware ordering")

Engine::ResetMiddleware()
_P2_seq = ""

Engine::Use(@P2_MW_A())
Engine::Use(@P2_MW_B())
Ctx::Init(@P2_ctx, "GET", "/order")
Engine::CombineHandlers(@P2_ctx, @P2_MW_Route())
Ctx::Dispatch(@P2_ctx)

; A enters → B enters → R runs → B exits → A exits
CheckStr(_P2_seq, "ABRba")

Engine::ResetMiddleware()

; =================================================================
; Suite: Logger middleware — downstream chain still runs
; =================================================================
BeginSuite("P2 / Logger — downstream handler executes")

_P2_route = 0
Ctx::Init(@P2_ctx, "GET", "/log-test")
Ctx::AddHandler(@P2_ctx, @P2_LoggerMW())
Ctx::AddHandler(@P2_ctx, @P2_RouteHandler())
Ctx::Dispatch(@P2_ctx)

CheckEqual(_P2_route, 1)           ; route handler ran inside Logger
CheckEqual(P2_ctx\StatusCode, 200) ; status preserved

; =================================================================
; Suite: Recovery — normal request (no error)
; =================================================================
BeginSuite("P2 / Recovery — normal flow")

_P2_route = 0
Ctx::Init(@P2_ctx, "GET", "/recover-ok")
Ctx::AddHandler(@P2_ctx, @P2_RecoveryMW())
Ctx::AddHandler(@P2_ctx, @P2_RouteHandler())
Ctx::Dispatch(@P2_ctx)

CheckEqual(_P2_route, 1)
CheckEqual(P2_ctx\StatusCode, 200)
CheckEqual(Ctx::IsAborted(@P2_ctx), #False)

; =================================================================
; Suite: Recovery — Abort+500 from downstream is preserved
; =================================================================
BeginSuite("P2 / Recovery — explicit 500 from handler is preserved")

Procedure P2_Explicit500(*C.RequestContext)
  *C\StatusCode = 500
  Ctx::Abort(*C)
EndProcedure

_P2_route = 0
Ctx::Init(@P2_ctx, "GET", "/recover-explicit-err")
Ctx::AddHandler(@P2_ctx, @P2_RecoveryMW())
Ctx::AddHandler(@P2_ctx, @P2_Explicit500())
Ctx::Dispatch(@P2_ctx)

CheckEqual(P2_ctx\StatusCode, 500)
CheckEqual(Ctx::IsAborted(@P2_ctx), #True)

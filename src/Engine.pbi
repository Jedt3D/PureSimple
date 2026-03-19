; Engine.pbi — Top-level application API
; NewApp() and Run() remain stubs until PureSimpleHTTPServer integration (future phase).
; GET/POST/PUT/PATCH/DELETE/Any delegate to Router::Insert.
; Use() registers global middleware; CombineHandlers() prepends it before each dispatch.

EnableExplicit

DeclareModule Engine
  Declare.i NewApp()
  Declare.i Run(Port.i)
  Declare   GET(Pattern.s, Handler.i)
  Declare   POST(Pattern.s, Handler.i)
  Declare   PUT(Pattern.s, Handler.i)
  Declare   PATCH(Pattern.s, Handler.i)
  Declare   DELETE(Pattern.s, Handler.i)
  Declare   Any(Pattern.s, Handler.i)
  Declare   Use(Handler.i)
  Declare   CombineHandlers(*C.RequestContext, RouteHandler.i)
  Declare   AppendGlobalMiddleware(*C.RequestContext)
  Declare   ResetMiddleware()
  Declare   SetNotFoundHandler(Handler.i)
  Declare   HandleNotFound(*C.RequestContext)
  Declare   SetMethodNotAllowedHandler(Handler.i)
  Declare   HandleMethodNotAllowed(*C.RequestContext)
EndDeclareModule

Module Engine
  UseModule Types   ; needed for *C.RequestContext in CombineHandlers

  #_MAX_MW = 32
  Global Dim _MW.i(#_MAX_MW)
  Global _MWCount.i           = 0
  Global _NotFoundHandler.i   = 0
  Global _MethodNotAllowed.i  = 0

  ; NewApp() — allocate application engine.
  ; Stub: returns 0. PureSimpleHTTPServer integration will replace this.
  Procedure.i NewApp()
    ProcedureReturn 0
  EndProcedure

  ; Run(Port) — start HTTP listener.
  ; Stub: returns #False until PureSimpleHTTPServer integration lands.
  Procedure.i Run(Port.i)
    ProcedureReturn #False
  EndProcedure

  Procedure GET(Pattern.s, Handler.i)
    Router::Insert("GET", Pattern, Handler)
  EndProcedure

  Procedure POST(Pattern.s, Handler.i)
    Router::Insert("POST", Pattern, Handler)
  EndProcedure

  Procedure PUT(Pattern.s, Handler.i)
    Router::Insert("PUT", Pattern, Handler)
  EndProcedure

  Procedure PATCH(Pattern.s, Handler.i)
    Router::Insert("PATCH", Pattern, Handler)
  EndProcedure

  Procedure DELETE(Pattern.s, Handler.i)
    Router::Insert("DELETE", Pattern, Handler)
  EndProcedure

  Procedure Any(Pattern.s, Handler.i)
    Router::Insert("GET",    Pattern, Handler)
    Router::Insert("POST",   Pattern, Handler)
    Router::Insert("PUT",    Pattern, Handler)
    Router::Insert("PATCH",  Pattern, Handler)
    Router::Insert("DELETE", Pattern, Handler)
  EndProcedure

  ; Register a global middleware handler (applied to every request via CombineHandlers).
  Procedure Use(Handler.i)
    If _MWCount < #_MAX_MW
      _MW(_MWCount) = Handler
      _MWCount + 1
    EndIf
  EndProcedure

  ; Prepend all global middleware to *C's handler chain, then append RouteHandler.
  ; Call after Ctx::Init and Router::Match, before Ctx::Dispatch.
  Procedure CombineHandlers(*C.RequestContext, RouteHandler.i)
    Protected i.i
    For i = 0 To _MWCount - 1
      Ctx::AddHandler(*C, _MW(i))
    Next i
    Ctx::AddHandler(*C, RouteHandler)
  EndProcedure

  ; Append all global middleware to *C's handler chain (without adding a route handler).
  ; Called by Group::CombineHandlers before adding group + route handlers.
  Procedure AppendGlobalMiddleware(*C.RequestContext)
    Protected i.i
    For i = 0 To _MWCount - 1
      Ctx::AddHandler(*C, _MW(i))
    Next i
  EndProcedure

  ; Clear all registered global middleware (used between tests).
  Procedure ResetMiddleware()
    _MWCount            = 0
    _NotFoundHandler    = 0
    _MethodNotAllowed   = 0
  EndProcedure

  ; Register a custom 404 Not Found handler.
  Procedure SetNotFoundHandler(Handler.i)
    _NotFoundHandler = Handler
  EndProcedure

  ; Invoke the registered 404 handler, or write a default 404 response.
  Procedure HandleNotFound(*C.RequestContext)
    Protected fn.PS_HandlerFunc
    If _NotFoundHandler <> 0
      fn = _NotFoundHandler
      fn(*C)
    Else
      *C\StatusCode   = 404
      *C\ResponseBody = "404 Not Found"
      *C\ContentType  = "text/plain"
    EndIf
  EndProcedure

  ; Register a custom 405 Method Not Allowed handler.
  Procedure SetMethodNotAllowedHandler(Handler.i)
    _MethodNotAllowed = Handler
  EndProcedure

  ; Invoke the registered 405 handler, or write a default 405 response.
  Procedure HandleMethodNotAllowed(*C.RequestContext)
    Protected fn.PS_HandlerFunc
    If _MethodNotAllowed <> 0
      fn = _MethodNotAllowed
      fn(*C)
    Else
      *C\StatusCode   = 405
      *C\ResponseBody = "405 Method Not Allowed"
      *C\ContentType  = "text/plain"
    EndIf
  EndProcedure

EndModule

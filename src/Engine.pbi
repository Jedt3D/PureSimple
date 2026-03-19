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
  Declare   ResetMiddleware()
EndDeclareModule

Module Engine
  UseModule Types   ; needed for *C.RequestContext in CombineHandlers

  #_MAX_MW = 32
  Global Dim _MW.i(#_MAX_MW)
  Global _MWCount.i = 0

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

  ; Clear all registered global middleware (used between tests).
  Procedure ResetMiddleware()
    _MWCount = 0
  EndProcedure

EndModule

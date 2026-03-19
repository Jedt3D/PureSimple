; Engine.pbi — Top-level application API
; NewApp() and Run() remain stubs until PureSimpleHTTPServer integration (future phase).
; GET/POST/PUT/PATCH/DELETE/Any delegate to Router::Insert.

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
EndDeclareModule

Module Engine
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
EndModule

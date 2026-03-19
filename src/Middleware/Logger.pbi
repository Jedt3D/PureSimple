; Middleware/Logger.pbi — Request logging middleware
;
; Records method, path, response status and elapsed time for every request.
; Output (to console): [LOG] METHOD /path -> STATUS (Xms)
;
; Usage:
;   Engine::Use(@Logger::Middleware())
;
; Middleware pattern: captures state before Advance, logs after it returns.

EnableExplicit

DeclareModule Logger
  Declare Middleware(*C.RequestContext)
EndDeclareModule

Module Logger
  UseModule Types

  Procedure Middleware(*C.RequestContext)
    Protected t0.i      = ElapsedMilliseconds()
    Protected method.s  = *C\Method
    Protected path.s    = *C\Path

    Ctx::Advance(*C)

    Protected elapsed.i = ElapsedMilliseconds() - t0
    PrintN("[LOG] " + method + " " + path + " -> " + Str(*C\StatusCode) +
           " (" + Str(elapsed) + "ms)")
  EndProcedure

EndModule

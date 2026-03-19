; Middleware/Recovery.pbi — Panic recovery middleware
;
; Wraps the downstream handler chain with OnErrorGoto so that runtime errors
; (e.g. null-pointer dereference, RaiseError) are caught via longjmp and
; converted into a 500 response instead of crashing the process.
;
; Usage:
;   Engine::Use(@Recovery::Middleware())
;
; Implementation notes:
;   OnErrorGoto(?_Mw_Recovery_Error) installs a setjmp checkpoint.
;   If any downstream handler triggers an error, longjmp fires and execution
;   resumes at _Mw_Recovery_Error: where the context is set to 500 + Aborted.
;   Goto _Mw_Recovery_Done skips the error block in the normal (no-error) path.
;   Global _CtxPtr holds the context address so it survives the longjmp.

EnableExplicit

DeclareModule Recovery
  Declare Middleware(*C.RequestContext)
EndDeclareModule

Module Recovery
  UseModule Types

  Global _CtxPtr.i = 0   ; address of the active RequestContext (safe across longjmp)

  Procedure Middleware(*C.RequestContext)
    Protected *Cx.RequestContext   ; typed alias rebuilt from global after longjmp

    _CtxPtr = *C
    OnErrorGoto(?_Mw_Recovery_Error)

    Ctx::Advance(*C)

    Goto _Mw_Recovery_Done

  _Mw_Recovery_Error:
    If _CtxPtr
      *Cx = _CtxPtr
      *Cx\StatusCode   = 500
      *Cx\ResponseBody = "Internal Server Error"
      *Cx\ContentType  = "text/plain"
      Ctx::Abort(*Cx)
    EndIf

  _Mw_Recovery_Done:
    _CtxPtr = 0
    OnErrorDefault()
  EndProcedure

EndModule

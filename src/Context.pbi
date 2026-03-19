; Context.pbi — RequestContext lifecycle and handler chain (Gin-style)
; Init resets a context slot. Each handler calls Next() to pass control
; downstream; Abort() prevents any further handlers from executing.

EnableExplicit

DeclareModule Ctx
  Declare     Init(*C.RequestContext, Method.s, Path.s)
  Declare.s   Param(*C.RequestContext, Name.s)
  Declare     Set(*C.RequestContext, Key.s, Val.s)
  Declare.s   Get(*C.RequestContext, Key.s)
  Declare     AddHandler(*C.RequestContext, Handler.i)
  Declare     Dispatch(*C.RequestContext)
  Declare     Advance(*C.RequestContext)   ; calls the next handler (Gin-style Next)
  Declare     Abort(*C.RequestContext)
  Declare.i   IsAborted(*C.RequestContext)
EndDeclareModule

Module Ctx
  UseModule Types   ; import RequestContext, PS_HandlerFunc, etc. into module scope

  #_MAX_CTX  = 32   ; max concurrent context slots (rolling, wraps around)
  #_MAX_HAND = 64   ; max handlers per context

  ; Per-slot handler chains (2D array: slot × handler index)
  Global Dim _Handlers.i(#_MAX_CTX, #_MAX_HAND)
  Global Dim _HandlerCount.i(#_MAX_CTX)
  Global _SlotSeq.i = 0   ; rolling counter for slot assignment

  ; ------------------------------------------------------------------
  ; Internal helper — look up Name in a Chr(9)-delimited parallel list
  ; ------------------------------------------------------------------
  Procedure.s _LookupTab(Keys.s, Vals.s, Name.s)
    Protected i.i = 1, k.s
    While i <= CountString(Keys, Chr(9))
      k = StringField(Keys, i, Chr(9))
      If k = Name
        ProcedureReturn StringField(Vals, i, Chr(9))
      EndIf
      i + 1
    Wend
    ProcedureReturn ""
  EndProcedure

  ; ------------------------------------------------------------------
  ; Public API
  ; ------------------------------------------------------------------

  ; Initialise (or re-use) a context slot; clears all fields.
  Procedure Init(*C.RequestContext, Method.s, Path.s)
    Protected slot.i = _SlotSeq % #_MAX_CTX
    _SlotSeq + 1
    *C\Method       = Method
    *C\Path         = Path
    *C\RawQuery     = ""
    *C\Body         = ""
    *C\ClientIP     = ""
    *C\StatusCode   = 200
    *C\ResponseBody = ""
    *C\ContentType  = "text/plain"
    *C\Location     = ""
    *C\ParamKeys    = ""
    *C\ParamVals    = ""
    *C\QueryKeys    = ""
    *C\QueryVals    = ""
    *C\StoreKeys    = ""
    *C\StoreVals    = ""
    *C\ContextID    = slot
    *C\HandlerIndex = 0
    *C\Aborted      = #False
    *C\JSONHandle   = 0
    _HandlerCount(slot) = 0
  EndProcedure

  ; Return a named route parameter value (populated by Router::Match).
  Procedure.s Param(*C.RequestContext, Name.s)
    ProcedureReturn _LookupTab(*C\ParamKeys, *C\ParamVals, Name)
  EndProcedure

  ; Store an arbitrary key/value for middleware communication.
  Procedure Set(*C.RequestContext, Key.s, Val.s)
    *C\StoreKeys + Key + Chr(9)
    *C\StoreVals + Val + Chr(9)
  EndProcedure

  ; Retrieve a value previously stored with Set.
  Procedure.s Get(*C.RequestContext, Key.s)
    ProcedureReturn _LookupTab(*C\StoreKeys, *C\StoreVals, Key)
  EndProcedure

  ; Append a handler to this context's handler chain.
  Procedure AddHandler(*C.RequestContext, Handler.i)
    Protected slot.i = *C\ContextID
    Protected cnt.i  = _HandlerCount(slot)
    If cnt < #_MAX_HAND
      _Handlers(slot, cnt) = Handler
      _HandlerCount(slot) + 1
    EndIf
  EndProcedure

  ; Advance to and execute the next handler in the chain.
  ; Middleware pattern: call Advance() to pass control downstream, then run
  ; "after" logic when Advance() returns.
  Procedure Advance(*C.RequestContext)
    Protected slot.i = *C\ContextID
    Protected idx.i  = *C\HandlerIndex
    Protected cnt.i  = _HandlerCount(slot)
    Protected fn.PS_HandlerFunc
    If Not *C\Aborted And idx < cnt
      *C\HandlerIndex + 1
      fn = _Handlers(slot, idx)
      If fn : fn(*C) : EndIf
    EndIf
  EndProcedure

  ; Start the handler chain from the beginning (called by the engine per request).
  Procedure Dispatch(*C.RequestContext)
    *C\HandlerIndex = 0
    *C\Aborted      = #False
    Advance(*C)
  EndProcedure

  ; Stop the handler chain — all subsequent handlers are skipped.
  Procedure Abort(*C.RequestContext)
    *C\Aborted = #True
  EndProcedure

  Procedure.i IsAborted(*C.RequestContext)
    ProcedureReturn *C\Aborted
  EndProcedure

EndModule

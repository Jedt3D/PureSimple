; Middleware/Session.pbi — In-memory session store with cookie-based session IDs.
;
; Sessions are stored in a global map: sessionID → Chr(9)-delimited KV pairs.
; The session ID is read from / written to the "_psid" cookie.
;
; Usage (middleware pattern):
;   Engine::Use(@SessionMW())   ; or wrap in a thin procedure per test convention
;
; Accessing session data inside a handler:
;   val = Session::Get(@ctx, "user_id")
;   Session::Set(@ctx, "user_id", "42")
;   Session::Save(@ctx)   ; called automatically by middleware after chain returns

EnableExplicit

DeclareModule Session
  Declare     Middleware(*C.RequestContext)
  Declare.s   Get(*C.RequestContext, Key.s)
  Declare     Set(*C.RequestContext, Key.s, Val.s)
  Declare.s   ID(*C.RequestContext)
  Declare     Save(*C.RequestContext)
  Declare     ClearStore()
EndDeclareModule

Module Session
  UseModule Types

  #_COOKIE_NAME = "_psid"

  ; Session storage: sessionID -> "keysStr" + Chr(1) + "valsStr"
  Global NewMap _Store.s()

  ; ------------------------------------------------------------------
  ; Internal helpers
  ; ------------------------------------------------------------------

  ; Generate a random 32-hex-char session ID.
  Procedure.s _GenerateID()
    Protected i.i, id.s = ""
    For i = 1 To 4
      id + RSet(Hex(Random($FFFFFFFF)), 8, "0")
    Next i
    ProcedureReturn id
  EndProcedure

  ; Return the last value for Key in a Chr(9)-delimited parallel list.
  ; (Last-match strategy: subsequent Set calls for the same key shadow earlier ones.)
  Procedure.s _LookupLast(Keys.s, Vals.s, Key.s)
    Protected i.i, result.s = ""
    For i = 1 To CountString(Keys, Chr(9))
      If StringField(Keys, i, Chr(9)) = Key
        result = StringField(Vals, i, Chr(9))
      EndIf
    Next i
    ProcedureReturn result
  EndProcedure

  ; ------------------------------------------------------------------
  ; Middleware — load/create session around the handler chain.
  ; ------------------------------------------------------------------
  Procedure Middleware(*C.RequestContext)
    Protected sid.s = Cookie::Get(*C, #_COOKIE_NAME)

    If sid = "" Or Not FindMapElement(_Store(), sid)
      sid = _GenerateID()
      _Store(sid) = Chr(1)   ; empty: "" + Chr(1) + ""
    EndIf

    *C\SessionID = sid

    ; Load session data from store into context
    Protected sessData.s = _Store(sid)
    Protected sep.i      = FindString(sessData, Chr(1))
    If sep > 0
      *C\SessionKeys = Left(sessData, sep - 1)
      *C\SessionVals = Mid(sessData, sep + 1)
    Else
      *C\SessionKeys = ""
      *C\SessionVals = ""
    EndIf

    ; Write session cookie to response
    Cookie::Set(*C, #_COOKIE_NAME, sid)

    Ctx::Advance(*C)

    ; Auto-save session after handler chain returns
    Save(*C)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Get — retrieve a value from the current request's session.
  ; Returns the last value set for Key, or "" if absent.
  ; ------------------------------------------------------------------
  Procedure.s Get(*C.RequestContext, Key.s)
    ProcedureReturn _LookupLast(*C\SessionKeys, *C\SessionVals, Key)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Set — write a key/value pair into the current request's session.
  ; Appends to the context's session KV lists; last write wins on Get.
  ; ------------------------------------------------------------------
  Procedure Set(*C.RequestContext, Key.s, Val.s)
    *C\SessionKeys + Key + Chr(9)
    *C\SessionVals + Val + Chr(9)
  EndProcedure

  ; ------------------------------------------------------------------
  ; ID — return the session ID for this request.
  ; ------------------------------------------------------------------
  Procedure.s ID(*C.RequestContext)
    ProcedureReturn *C\SessionID
  EndProcedure

  ; ------------------------------------------------------------------
  ; Save — persist context session data back to the in-memory store.
  ; Called automatically by Middleware after the handler chain returns.
  ; ------------------------------------------------------------------
  Procedure Save(*C.RequestContext)
    If *C\SessionID <> ""
      _Store(*C\SessionID) = *C\SessionKeys + Chr(1) + *C\SessionVals
    EndIf
  EndProcedure

  ; ------------------------------------------------------------------
  ; ClearStore — wipe all sessions (used between tests).
  ; ------------------------------------------------------------------
  Procedure ClearStore()
    ClearMap(_Store())
  EndProcedure

EndModule

; Binding.pbi — Request data extraction helpers
;
; Covers four binding sources:
;   Route params   — Binding::Param     (delegates to Ctx::Param)
;   Query string   — Binding::Query     (lazy-parses *C\RawQuery)
;   Form body      — Binding::PostForm  (parses *C\Body as URL-encoded)
;   JSON body      — Binding::BindJSON + JSONString/JSONInteger/JSONBool + ReleaseJSON
;
; URL decoding handled by private _URLDecode.
; JSON state stored in *C\JSONHandle (reset to 0 by Ctx::Init).
; ReleaseJSON (not FreeJSON) avoids shadowing PureBasic's built-in FreeJSON(json.i).

EnableExplicit

DeclareModule Binding
  Declare.s Param(*C.RequestContext, Name.s)
  Declare.s Query(*C.RequestContext, Name.s)
  Declare.s PostForm(*C.RequestContext, Field.s)
  Declare.i BindJSON(*C.RequestContext)
  Declare.s JSONString(*C.RequestContext, Key.s)
  Declare.i JSONInteger(*C.RequestContext, Key.s)
  Declare.i JSONBool(*C.RequestContext, Key.s)
  Declare   ReleaseJSON(*C.RequestContext)
EndDeclareModule

Module Binding
  UseModule Types

  ; Module-level temporaries used by PostForm's on-demand parse
  Global _TmpKeys.s = ""
  Global _TmpVals.s = ""

  ; ------------------------------------------------------------------
  ; Private: URL-decode a single string (+ -> space, %XX -> char)
  ; ------------------------------------------------------------------
  Procedure.s _URLDecode(s.s)
    Protected result.s = "", i.i = 1, n.i = Len(s), c.s
    While i <= n
      c = Mid(s, i, 1)
      If c = "+"
        result + " "
      ElseIf c = "%" And i + 2 <= n
        result + Chr(Val("$" + Mid(s, i + 1, 2)))
        i + 2
      Else
        result + c
      EndIf
      i + 1
    Wend
    ProcedureReturn result
  EndProcedure

  ; ------------------------------------------------------------------
  ; Private: look up Name in a Chr(9)-delimited parallel list
  ; ------------------------------------------------------------------
  Procedure.s _LookupKV(Keys.s, Vals.s, Name.s)
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
  ; Private: parse URL-encoded string into parallel key/val lists.
  ; If SetQuery=#True, stores result in *C\QueryKeys / *C\QueryVals.
  ; Always stores result in module globals _TmpKeys / _TmpVals.
  ; ------------------------------------------------------------------
  Procedure _ParseURLEncoded(encoded.s, *C.RequestContext, SetQuery.i)
    Protected n.i = CountString(encoded, "&") + 1
    Protected i.i, pair.s, k.s, v.s, eq.i
    Protected keys.s = "", vals.s = ""
    For i = 1 To n
      pair = StringField(encoded, i, "&")
      If pair = "" : Continue : EndIf
      eq = FindString(pair, "=")
      If eq > 0
        k = _URLDecode(Left(pair, eq - 1))
        v = _URLDecode(Mid(pair, eq + 1))
      Else
        k = _URLDecode(pair)
        v = ""
      EndIf
      keys + k + Chr(9)
      vals + v + Chr(9)
    Next
    _TmpKeys = keys
    _TmpVals = vals
    If SetQuery
      *C\QueryKeys = keys
      *C\QueryVals = vals
    EndIf
  EndProcedure

  ; ------------------------------------------------------------------
  ; Public API
  ; ------------------------------------------------------------------

  Procedure.s Param(*C.RequestContext, Name.s)
    ProcedureReturn Ctx::Param(*C, Name)
  EndProcedure

  ; Lazily parses *C\RawQuery into QueryKeys/QueryVals on first call.
  Procedure.s Query(*C.RequestContext, Name.s)
    If *C\QueryKeys = "" And *C\RawQuery <> ""
      _ParseURLEncoded(*C\RawQuery, *C, #True)
    EndIf
    ProcedureReturn _LookupKV(*C\QueryKeys, *C\QueryVals, Name)
  EndProcedure

  ; Parses *C\Body as URL-encoded form on every call.
  Procedure.s PostForm(*C.RequestContext, Field.s)
    If *C\Body = "" : ProcedureReturn "" : EndIf
    _TmpKeys = "" : _TmpVals = ""
    _ParseURLEncoded(*C\Body, *C, #False)
    ProcedureReturn _LookupKV(_TmpKeys, _TmpVals, Field)
  EndProcedure

  ; Parse *C\Body as JSON; store handle in *C\JSONHandle.
  ; Frees any prior handle first. Returns handle (> 0 on success).
  Procedure.i BindJSON(*C.RequestContext)
    If *C\JSONHandle <> 0
      FreeJSON(*C\JSONHandle)
      *C\JSONHandle = 0
    EndIf
    If *C\Body = "" : ProcedureReturn 0 : EndIf
    Protected h.i = ParseJSON(#PB_Any, *C\Body)
    *C\JSONHandle = h
    ProcedureReturn h
  EndProcedure

  ; Get a top-level string field from the JSON parsed by BindJSON.
  Procedure.s JSONString(*C.RequestContext, Key.s)
    Protected *root, *member
    If *C\JSONHandle = 0 : ProcedureReturn "" : EndIf
    *root = JSONValue(*C\JSONHandle)
    If *root = 0 : ProcedureReturn "" : EndIf
    *member = GetJSONMember(*root, Key)
    If *member = 0 : ProcedureReturn "" : EndIf
    ProcedureReturn GetJSONString(*member)
  EndProcedure

  ; Get a top-level integer field from the JSON parsed by BindJSON.
  Procedure.i JSONInteger(*C.RequestContext, Key.s)
    Protected *root, *member
    If *C\JSONHandle = 0 : ProcedureReturn 0 : EndIf
    *root = JSONValue(*C\JSONHandle)
    If *root = 0 : ProcedureReturn 0 : EndIf
    *member = GetJSONMember(*root, Key)
    If *member = 0 : ProcedureReturn 0 : EndIf
    ProcedureReturn GetJSONInteger(*member)
  EndProcedure

  ; Get a top-level boolean field from the JSON parsed by BindJSON.
  ; Returns 1 for true, 0 for false/missing.
  Procedure.i JSONBool(*C.RequestContext, Key.s)
    Protected *root, *member
    If *C\JSONHandle = 0 : ProcedureReturn 0 : EndIf
    *root = JSONValue(*C\JSONHandle)
    If *root = 0 : ProcedureReturn 0 : EndIf
    *member = GetJSONMember(*root, Key)
    If *member = 0 : ProcedureReturn 0 : EndIf
    ProcedureReturn GetJSONBoolean(*member)
  EndProcedure

  ; Free the JSON object and reset *C\JSONHandle to 0.
  ; Named ReleaseJSON (not FreeJSON) to avoid shadowing PB's built-in FreeJSON.
  Procedure ReleaseJSON(*C.RequestContext)
    If *C\JSONHandle <> 0
      FreeJSON(*C\JSONHandle)
      *C\JSONHandle = 0
    EndIf
  EndProcedure

EndModule

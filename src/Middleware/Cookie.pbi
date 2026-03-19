; Middleware/Cookie.pbi — Cookie parsing (incoming) and Set-Cookie generation (outgoing)
;
; Incoming cookies are read from *C\Cookie (raw "name=value; name=value" string).
; Outgoing Set-Cookie directives are accumulated in *C\SetCookies (Chr(10)-delimited).

EnableExplicit

DeclareModule Cookie
  Declare.s Get(*C.RequestContext, Name.s)
  Declare   Set(*C.RequestContext, Name.s, Value.s, Path.s = "/", MaxAge.i = 0)
EndDeclareModule

Module Cookie
  UseModule Types

  ; ------------------------------------------------------------------
  ; Get — extract a cookie value from the incoming Cookie header.
  ; Cookie header format: "name1=value1; name2=value2; ..."
  ; Returns "" if the cookie is not present.
  ; ------------------------------------------------------------------
  Procedure.s Get(*C.RequestContext, Name.s)
    Protected i.i, pair.s, sep.i, k.s
    For i = 1 To CountString(*C\Cookie, ";") + 1
      pair = Trim(StringField(*C\Cookie, i, ";"))
      sep  = FindString(pair, "=")
      If sep > 0
        k = Trim(Left(pair, sep - 1))
        If k = Name
          ProcedureReturn Mid(pair, sep + 1)
        EndIf
      EndIf
    Next i
    ProcedureReturn ""
  EndProcedure

  ; ------------------------------------------------------------------
  ; Set — append a Set-Cookie directive to *C\SetCookies.
  ; Multiple cookies are separated by Chr(10).
  ; MaxAge 0 = session cookie (no Max-Age attribute).
  ; ------------------------------------------------------------------
  Procedure Set(*C.RequestContext, Name.s, Value.s, Path.s = "/", MaxAge.i = 0)
    Protected cookie.s = Name + "=" + Value + "; Path=" + Path
    If MaxAge > 0
      cookie + "; Max-Age=" + Str(MaxAge)
    EndIf
    If *C\SetCookies <> ""
      *C\SetCookies + Chr(10)
    EndIf
    *C\SetCookies + cookie
  EndProcedure

EndModule

; Middleware/CSRF.pbi — CSRF token generation and validation.
;
; Tokens are 32 random hex characters (128 bits).
; A token is stored in the session under "_csrf_token" and also set as the
; "csrf_token" cookie so client-side code can embed it in forms.
;
; The CSRF middleware skips validation for GET and HEAD requests.
; For all other methods (POST, PUT, PATCH, DELETE) it reads the "_csrf"
; field from the POST form body and validates it against the session token.
; Mismatches: 403 Forbidden + Ctx::Abort.
;
; Usage:
;   Engine::Use(@SessionMW())   ; Session must run before CSRF
;   Engine::Use(@CSRFMw())

EnableExplicit

DeclareModule CSRF
  Declare.s GenerateToken()
  Declare   SetToken(*C.RequestContext)
  Declare.i ValidateToken(*C.RequestContext, Token.s)
  Declare   Middleware(*C.RequestContext)
EndDeclareModule

Module CSRF
  UseModule Types

  #_SESSION_KEY = "_csrf_token"
  #_FORM_FIELD  = "_csrf"

  ; ------------------------------------------------------------------
  ; GenerateToken — produce a 32-hex-char random token (128 bits).
  ; ------------------------------------------------------------------
  Procedure.s GenerateToken()
    Protected i.i, token.s = ""
    For i = 1 To 4
      token + RSet(Hex(Random($FFFFFFFF)), 8, "0")
    Next i
    ProcedureReturn token
  EndProcedure

  ; ------------------------------------------------------------------
  ; SetToken — generate a new token, store in session + Set-Cookie.
  ; Call from a GET handler to embed the token in a form page.
  ; ------------------------------------------------------------------
  Procedure SetToken(*C.RequestContext)
    Protected token.s = GenerateToken()
    Session::Set(*C, #_SESSION_KEY, token)
    Cookie::Set(*C, "csrf_token", token)
  EndProcedure

  ; ------------------------------------------------------------------
  ; ValidateToken — check Token against the session-stored CSRF token.
  ; Returns #True if valid, #False if missing or mismatched.
  ; ------------------------------------------------------------------
  Procedure.i ValidateToken(*C.RequestContext, Token.s)
    Protected expected.s = Session::Get(*C, #_SESSION_KEY)
    ProcedureReturn Bool(expected <> "" And expected = Token)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Middleware — enforce CSRF on state-changing requests.
  ; GET / HEAD pass through without validation.
  ; POST / PUT / PATCH / DELETE require "_csrf" form field to match session.
  ; ------------------------------------------------------------------
  Procedure Middleware(*C.RequestContext)
    Protected method.s = *C\Method

    If method = "GET" Or method = "HEAD"
      Ctx::Advance(*C)
      ProcedureReturn
    EndIf

    ; Read CSRF token from form body
    Protected token.s = Binding::PostForm(*C, #_FORM_FIELD)

    If Not ValidateToken(*C, token)
      Ctx::AbortWithError(*C, 403, "CSRF token invalid or missing")
      ProcedureReturn
    EndIf

    Ctx::Advance(*C)
  EndProcedure

EndModule

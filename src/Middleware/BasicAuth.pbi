; Middleware/BasicAuth.pbi — HTTP Basic Authentication middleware.
;
; Reads the Authorization header from *C\Authorization, decodes the
; Base64 credentials, and compares against configured user/password.
; On failure: 401 Unauthorized + Ctx::Abort.
; On success: stores the authenticated username in the context KV store
;             under "_auth_user", then calls Ctx::Advance.
;
; Usage:
;   BasicAuth::SetCredentials("admin", "secret")
;   Engine::Use(@BasicAuthMW())

EnableExplicit

DeclareModule BasicAuth
  Declare   SetCredentials(User.s, Pass.s)
  Declare   Middleware(*C.RequestContext)
EndDeclareModule

Module BasicAuth
  UseModule Types

  Global _User.s = ""
  Global _Pass.s = ""

  ; Configure the expected username and password.
  Procedure SetCredentials(User.s, Pass.s)
    _User = User
    _Pass = Pass
  EndProcedure

  ; Middleware — validate Basic Auth credentials.
  Procedure Middleware(*C.RequestContext)
    Protected auth.s = *C\Authorization

    ; Authorization header must start with "Basic "
    If Left(auth, 6) <> "Basic "
      Ctx::AbortWithError(*C, 401, "Unauthorized")
      ProcedureReturn
    EndIf

    ; Decode base64 credentials: "Basic <base64(user:pass)>"
    Protected encoded.s  = Mid(auth, 7)
    Protected bufSize.i  = Len(encoded) + 4
    Protected *buf       = AllocateMemory(bufSize)
    If *buf = 0
      Ctx::AbortWithError(*C, 500, "Memory error")
      ProcedureReturn
    EndIf

    Protected decodedLen.i  = Base64Decoder(encoded, *buf, bufSize)
    Protected credentials.s = PeekS(*buf, decodedLen, #PB_Ascii)
    FreeMemory(*buf)

    ; Split "user:pass" at the first colon
    Protected colon.i = FindString(credentials, ":")
    If colon = 0
      Ctx::AbortWithError(*C, 401, "Unauthorized")
      ProcedureReturn
    EndIf

    Protected user.s = Left(credentials, colon - 1)
    Protected pass.s = Mid(credentials, colon + 1)

    If user <> _User Or pass <> _Pass
      Ctx::AbortWithError(*C, 401, "Unauthorized")
      ProcedureReturn
    EndIf

    ; Credentials valid — store username and continue
    Ctx::Set(*C, "_auth_user", user)
    Ctx::Advance(*C)
  EndProcedure

EndModule

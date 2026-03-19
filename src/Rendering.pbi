; Rendering.pbi — Response helpers (JSON, HTML, Text, Redirect, File, Render)
;
; All procedures write into *C\ResponseBody, *C\ContentType, *C\StatusCode.
; Rendering::Render uses PureJinja to render a template file from templates/.
; The caller's KV store (Set/Get) is exposed as template variables.

EnableExplicit

DeclareModule Rendering
  Declare JSON(*C.RequestContext, Body.s, StatusCode.i = 200)
  Declare HTML(*C.RequestContext, Body.s, StatusCode.i = 200)
  Declare Text(*C.RequestContext, Body.s, StatusCode.i = 200)
  Declare Status(*C.RequestContext, StatusCode.i)
  Declare Redirect(*C.RequestContext, URL.s, StatusCode.i = 302)
  Declare File(*C.RequestContext, FilePath.s)
  Declare Render(*C.RequestContext, TemplateName.s, TemplatesDir.s = "templates/")
EndDeclareModule

Module Rendering
  UseModule Types

  ; ------------------------------------------------------------------
  ; JSON — send a JSON string with application/json content type
  ; ------------------------------------------------------------------
  Procedure JSON(*C.RequestContext, Body.s, StatusCode.i = 200)
    *C\StatusCode   = StatusCode
    *C\ResponseBody = Body
    *C\ContentType  = "application/json"
  EndProcedure

  ; ------------------------------------------------------------------
  ; HTML — send an HTML string with text/html content type
  ; ------------------------------------------------------------------
  Procedure HTML(*C.RequestContext, Body.s, StatusCode.i = 200)
    *C\StatusCode   = StatusCode
    *C\ResponseBody = Body
    *C\ContentType  = "text/html"
  EndProcedure

  ; ------------------------------------------------------------------
  ; Text — send a plain-text string
  ; ------------------------------------------------------------------
  Procedure Text(*C.RequestContext, Body.s, StatusCode.i = 200)
    *C\StatusCode   = StatusCode
    *C\ResponseBody = Body
    *C\ContentType  = "text/plain"
  EndProcedure

  ; ------------------------------------------------------------------
  ; Status — set status code only (body unchanged)
  ; ------------------------------------------------------------------
  Procedure Status(*C.RequestContext, StatusCode.i)
    *C\StatusCode = StatusCode
  EndProcedure

  ; ------------------------------------------------------------------
  ; Redirect — HTTP redirect (default 302 Found)
  ; ------------------------------------------------------------------
  Procedure Redirect(*C.RequestContext, URL.s, StatusCode.i = 302)
    *C\StatusCode   = StatusCode
    *C\Location     = URL
    *C\ResponseBody = ""
    *C\ContentType  = "text/plain"
  EndProcedure

  ; ------------------------------------------------------------------
  ; File — read a file from disk and send its contents as text/html
  ; ------------------------------------------------------------------
  Procedure File(*C.RequestContext, FilePath.s)
    Protected fh.i
    If FileSize(FilePath) < 0
      *C\StatusCode   = 404
      *C\ResponseBody = "File not found: " + FilePath
      *C\ContentType  = "text/plain"
      ProcedureReturn
    EndIf
    fh = ReadFile(#PB_Any, FilePath)
    If fh = 0
      *C\StatusCode   = 500
      *C\ResponseBody = "Cannot open file: " + FilePath
      *C\ContentType  = "text/plain"
      ProcedureReturn
    EndIf
    *C\ResponseBody = ""
    While Not Eof(fh)
      *C\ResponseBody + ReadString(fh) + #LF$
    Wend
    CloseFile(fh)
    *C\StatusCode  = 200
    *C\ContentType = "text/html"
  EndProcedure

  ; ------------------------------------------------------------------
  ; Render — render a Jinja template via PureJinja
  ;   TemplateName : filename relative to TemplatesDir
  ;   Context KV store (Set/Get) is exposed as template variables.
  ; ------------------------------------------------------------------
  Procedure Render(*C.RequestContext, TemplateName.s, TemplatesDir.s = "templates/")
    Protected *env.JinjaEnv::JinjaEnvironment
    Protected NewMap vars.JinjaVariant::JinjaVariant()
    Protected i.i, key.s, val.s

    ; Expose the request KV store as template variables
    For i = 1 To CountString(*C\StoreKeys, Chr(9))
      key = StringField(*C\StoreKeys, i, Chr(9))
      val = StringField(*C\StoreVals, i, Chr(9))
      If key <> ""
        JinjaVariant::StrVariant(@vars(key), val)
      EndIf
    Next i

    *env = JinjaEnv::CreateEnvironment()
    JinjaEnv::SetTemplatePath(*env, TemplatesDir)

    *C\ResponseBody = JinjaEnv::RenderTemplate(*env, TemplateName, vars())
    *C\StatusCode   = 200
    *C\ContentType  = "text/html"

    JinjaEnv::FreeEnvironment(*env)
    ForEach vars()
      JinjaVariant::FreeVariant(@vars())
    Next
  EndProcedure

EndModule

; Types.pbi — Core type definitions for PureSimple
;
; PureBasic module rule: module bodies cannot see main-code globals.
; Solution: wrap all shared types in DeclareModule Types so that:
;   - Main-code and tests: access as `RequestContext` (structures are globally
;     accessible even when defined inside a module)
;   - Other module bodies: UseModule Types or Types::RequestContext

EnableExplicit

DeclareModule Types

  ; RequestContext — per-request state (pre-allocated, reset per request)
  Structure RequestContext
    ; Raw request data (populated by PureSimpleHTTPServer dispatch callback)
    Method.s            ; "GET", "POST", etc.
    Path.s              ; URL path, e.g. "/api/users/42"
    RawQuery.s          ; query string, e.g. "page=1&limit=10"
    Body.s              ; raw request body (for JSON binding)
    ClientIP.s          ; remote address

    ; Response state
    StatusCode.i        ; HTTP status to send
    ResponseBody.s      ; response content
    ContentType.s       ; "application/json", "text/html", etc.
    Location.s          ; redirect URL (set by Rendering::Redirect, used by HTTP server)

    ; Handler chain state
    ContextID.i         ; slot index into global handler chain arrays (set by Ctx::Init)
    HandlerIndex.i      ; current position in the handler chain
    Aborted.i           ; #True if Abort() was called

    ; Route params and query (Chr(9)-delimited parallel lists)
    ParamKeys.s
    ParamVals.s
    QueryKeys.s
    QueryVals.s

    ; General-purpose KV store for middleware communication (Set/Get helpers)
    StoreKeys.s
    StoreVals.s

    ; JSON binding — handle to the parsed JSON object (Binding::BindJSON / FreeJSON)
    JSONHandle.i
  EndStructure

  ; HandlerFunc — universal handler/middleware procedure signature
  ; Declare handlers as: Procedure MyHandler(*Ctx.RequestContext)
  ; Register with:       Engine::GET("/path", @MyHandler())
  Prototype PS_HandlerFunc(*Ctx.RequestContext)

  ; RouterEngine — top-level application object
  Structure RouterEngine
    Port.i              ; port to listen on
    Running.i           ; #True once Run() is called
  EndStructure

  ; PS_RouterGroup — sub-router with a shared path prefix and middleware stack
  ; Create with Group::Init; register routes via Group::GET, POST, etc.
  ; Supports up to 32 group-level middleware handlers.
  Structure PS_RouterGroup
    Prefix.s            ; path prefix prepended to all routes in this group
    MW.i[32]            ; group-level middleware procedure addresses (indices 0..31)
    MWCount.i           ; number of group-level middleware handlers registered
  EndStructure

EndDeclareModule

Module Types
  ; Types module has no runtime code — it is a pure type library.
EndModule

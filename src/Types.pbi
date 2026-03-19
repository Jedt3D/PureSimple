; Types.pbi — Core structure definitions for PureSimple
; All framework-wide Structure definitions live here and are included first.

EnableExplicit

; ------------------------------------------------------------------
; RequestContext — per-request state (pre-allocated, reset per request)
; ------------------------------------------------------------------
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

  ; Routing state
  HandlerIndex.i      ; current position in the handler chain
  Aborted.i           ; #True if Abort() was called

  ; Params and query maps (KV lists — phase P1 will wire these properly)
  ParamKeys.s         ; pipe-delimited param keys   "id|name"
  ParamVals.s         ; pipe-delimited param values "42|alice"
  QueryKeys.s         ; pipe-delimited query keys
  QueryVals.s         ; pipe-delimited query values

  ; General-purpose KV store (Set/Get helpers)
  StoreKeys.s
  StoreVals.s
EndStructure

; ------------------------------------------------------------------
; RouteEntry — one registered route in the route table
; ------------------------------------------------------------------
Structure RouteEntry
  Method.s            ; HTTP method
  Pattern.s           ; route pattern, e.g. "/users/:id"
  ; Handler is stored as a procedure address (.i) — wired in P1
  HandlerAddr.i
EndStructure

; ------------------------------------------------------------------
; RouterEngine — top-level application object (stub for P0)
; ------------------------------------------------------------------
Structure RouterEngine
  Port.i              ; port to listen on (wired in P1)
  Running.i           ; #True once Run() is called
EndStructure

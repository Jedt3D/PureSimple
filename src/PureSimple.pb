; PureSimple.pb — Framework entry point
; Include order: Types → Router → Context → Middleware → Engine → (future modules)
; All phase modules are added here as they are implemented.
;
; Integration note:
;   PureSimpleHTTPServer: XIncludeFile "../../PureSimpleHTTPServer/src/HTTPServer.pbi"
;   PureJinja:            XIncludeFile "../../PureJinja/src/PureJinja.pbi"
; Both repos should be cloned alongside this one; their .pbi paths are
; referenced relative to the project root once integration lands in P4.

EnableExplicit

XIncludeFile "Types.pbi"               ; Structure definitions + PS_HandlerFunc prototype
UseModule Types                        ; import RequestContext, PS_HandlerFunc etc. into global scope
XIncludeFile "Router.pbi"              ; Segment-level trie router (Insert / Match)
XIncludeFile "Context.pbi"             ; RequestContext lifecycle: Advance, Abort, Param, KV
XIncludeFile "Middleware/Logger.pbi"   ; Logger middleware: method/path/status/elapsed
XIncludeFile "Middleware/Recovery.pbi" ; Recovery middleware: OnError -> 500 response
XIncludeFile "Engine.pbi"              ; Top-level API: NewApp(), Run(), GET(), POST(), Use(), …

; Future phases will add:
;   XIncludeFile "Config.pbi"
;   XIncludeFile "Binding.pbi"
;   XIncludeFile "Rendering.pbi"
;   XIncludeFile "DB/SQLite.pbi"

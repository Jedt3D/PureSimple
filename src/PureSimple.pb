; PureSimple.pb — Framework entry point
; Include order matters: Types first, then Engine (and future modules).
; All phase modules are added here as they are implemented.
;
; Integration note:
;   PureSimpleHTTPServer → https://github.com/your-org/PureSimpleHTTPServer
;   PureJinja            → https://github.com/your-org/PureJinja
; Both repos should be cloned alongside this one; their .pbi paths are
; referenced relative to the project root once integration lands in P4.

EnableExplicit

XIncludeFile "Types.pbi"
XIncludeFile "Engine.pbi"

; Future phases will add:
;   XIncludeFile "Config.pbi"
;   XIncludeFile "Router.pbi"
;   XIncludeFile "Context.pbi"
;   XIncludeFile "Middleware/Logger.pbi"
;   XIncludeFile "Middleware/Recovery.pbi"
;   XIncludeFile "Binding.pbi"
;   XIncludeFile "Rendering.pbi"
;   XIncludeFile "DB/SQLite.pbi"

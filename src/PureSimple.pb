; PureSimple.pb — Framework entry point
; Include order: Types → Router → Context → Middleware → Engine → (future modules)
; All phase modules are added here as they are implemented.
;
; Integration note:
;   PureSimpleHTTPServer: XIncludeFile "../../PureSimpleHTTPServer/src/HTTPServer.pbi"
;   PureJinja is cloned alongside this repo at: ../../pure_jinja/PureJinja.pbi

EnableExplicit

XIncludeFile "Types.pbi"               ; Structure definitions + PS_HandlerFunc prototype
UseModule Types                        ; import RequestContext, PS_HandlerFunc etc. into global scope
XIncludeFile "Router.pbi"              ; Segment-level trie router (Insert / Match)
XIncludeFile "Context.pbi"             ; RequestContext lifecycle: Advance, Abort, Param, KV
XIncludeFile "Middleware/Logger.pbi"   ; Logger middleware: method/path/status/elapsed
XIncludeFile "Middleware/Recovery.pbi" ; Recovery middleware: OnError -> 500 response
XIncludeFile "Binding.pbi"             ; Request binding: Param, Query, PostForm, JSON
XIncludeFile "Middleware/Cookie.pbi"   ; Cookie parsing (incoming) + Set-Cookie (outgoing)
XIncludeFile "Middleware/Session.pbi"  ; In-memory session store (uses Cookie)
XIncludeFile "Middleware/BasicAuth.pbi" ; HTTP Basic Authentication middleware
XIncludeFile "Middleware/CSRF.pbi"     ; CSRF token generation + validation (uses Session, Binding)
XIncludeFile "../../pure_jinja/PureJinja.pbi" ; PureJinja template engine (Jinja-compatible)
XIncludeFile "Rendering.pbi"           ; Response rendering: JSON, HTML, Text, Redirect, File, Render
XIncludeFile "Engine.pbi"              ; Top-level API: NewApp(), Run(), GET(), POST(), Use(), …
XIncludeFile "Group.pbi"               ; RouterGroup: sub-router with prefix + group middleware
XIncludeFile "DB/SQLite.pbi"           ; SQLite adapter + migration runner
XIncludeFile "Config.pbi"             ; .env file loader + key/value config store
XIncludeFile "Log.pbi"                ; Leveled logger (Debug/Info/Warn/Error, file or stdout)
XIncludeFile "DB/Connect.pbi"         ; DSN-based multi-driver connection factory (SQLite/Postgres/MySQL)

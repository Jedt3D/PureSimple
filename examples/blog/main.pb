; examples/blog/main.pb — PureSimple blog (HTML templates, sessions, config)
;
; Routes:
;   GET  /             — home page (post list)
;   GET  /post/:slug   — single post
;   GET  /about        — about page
;   GET  /health       — health check
;
; Compile:
;   $PUREBASIC_HOME/compilers/pbcompiler examples/blog/main.pb -cl -o blog
; Run:
;   ./blog
; Then visit http://localhost:8080/

EnableExplicit

XIncludeFile "../../src/PureSimple.pb"

; ---- In-memory post store --------------------------------------------------

Structure BlogPost
  slug.s
  title.s
  author.s
  date.s
  body.s
EndStructure

Global Dim _Posts.BlogPost(2)

Procedure InitPosts()
  _Posts(0)\slug   = "hello-puresimple"
  _Posts(0)\title  = "Hello, PureSimple!"
  _Posts(0)\author = "Alice"
  _Posts(0)\date   = "2026-03-20"
  _Posts(0)\body   = "Welcome to the first post on this PureBasic blog framework."

  _Posts(1)\slug   = "routing-in-purebasic"
  _Posts(1)\title  = "Routing in PureBasic"
  _Posts(1)\author = "Bob"
  _Posts(1)\date   = "2026-03-21"
  _Posts(1)\body   = "PureSimple uses a radix trie for fast route matching with :param support."

  _Posts(2)\slug   = "templates-with-purejinja"
  _Posts(2)\title  = "HTML Templates with PureJinja"
  _Posts(2)\author = "Alice"
  _Posts(2)\date   = "2026-03-22"
  _Posts(2)\body   = "PureJinja brings Jinja-compatible templates to native PureBasic executables."
EndProcedure

; ---- Handlers --------------------------------------------------------------

Procedure HomeHandler(*C.RequestContext)
  Protected titles.s = ""
  Protected i.i
  For i = 0 To 2
    titles + _Posts(i)\slug + Chr(9) + _Posts(i)\title + Chr(9) + _Posts(i)\date + Chr(10)
  Next i
  Ctx::Set(*C, "posts", titles)
  Ctx::Set(*C, "site_name", Config::Get("SITE_NAME", "PureSimple Blog"))
  Rendering::Render(*C, "index.html", "examples/blog/templates/")
EndProcedure

Procedure PostHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")
  Protected i.i
  For i = 0 To 2
    If _Posts(i)\slug = slug
      Ctx::Set(*C, "title",     _Posts(i)\title)
      Ctx::Set(*C, "author",    _Posts(i)\author)
      Ctx::Set(*C, "date",      _Posts(i)\date)
      Ctx::Set(*C, "body",      _Posts(i)\body)
      Ctx::Set(*C, "site_name", Config::Get("SITE_NAME", "PureSimple Blog"))
      Rendering::Render(*C, "post.html", "examples/blog/templates/")
      ProcedureReturn
    EndIf
  Next i
  Engine::HandleNotFound(*C)
EndProcedure

Procedure AboutHandler(*C.RequestContext)
  Ctx::Set(*C, "site_name", Config::Get("SITE_NAME", "PureSimple Blog"))
  Rendering::Render(*C, "about.html", "examples/blog/templates/")
EndProcedure

Procedure HealthHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"status\":\"ok\"}")
EndProcedure

; ---- Bootstrap -------------------------------------------------------------

InitPosts()
Config::Load(".env")
Protected port.i = Config::GetInt("PORT", 8080)
Engine::SetMode(Config::Get("MODE", "debug"))

Engine::Use(@Logger::Middleware())
Engine::Use(@Recovery::Middleware())

Engine::GET("/",            @HomeHandler())
Engine::GET("/post/:slug",  @PostHandler())
Engine::GET("/about",       @AboutHandler())
Engine::GET("/health",      @HealthHandler())

Log::Info("Blog starting on :" + Str(port) + " [" + Engine::Mode() + "]")
Engine::Run(port)

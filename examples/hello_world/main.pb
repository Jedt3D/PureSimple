; hello_world/main.pb — Minimal PureSimple example demonstrating P8 features
; Compile: pbcompiler examples/hello_world/main.pb -cl -o hello_world
; Run:     ./hello_world

EnableExplicit

XIncludeFile "../../src/PureSimple.pb"

; Load configuration from .env file (falls back to defaults if absent)
If Config::Load(".env")
  Log::Info(".env loaded")
Else
  Log::Warn("No .env found — using built-in defaults")
EndIf

; Read config with fallbacks
Protected port.i  = Config::GetInt("PORT",  8080)
Protected mode.s  = Config::Get("MODE", "debug")
Protected name.s  = Config::Get("APP_NAME", "hello_world")

; Apply run mode
Engine::SetMode(mode)

; Emit startup information
Log::Info("App: "  + name)
Log::Info("Mode: " + Engine::Mode())
Log::Info("Port: " + Str(port))

; Register routes
Engine::GET("/", @HelloHandler())
Engine::GET("/health", @HealthHandler())

; Run() is a stub until PureSimpleHTTPServer integration (future phase).
; In production it will block here serving HTTP on the configured port.
Log::Info("Listening on :" + Str(port) + " (stub — not yet connected to HTTP server)")
Engine::Run(port)

Procedure HelloHandler(*C.RequestContext)
  Rendering::Text(*C, "Hello from " + Config::Get("APP_NAME", "PureSimple") + "!")
EndProcedure

Procedure HealthHandler(*C.RequestContext)
  Rendering::Text(*C, "OK")
EndProcedure

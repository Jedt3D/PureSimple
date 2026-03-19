# PureSimple API Reference

PureSimple is a lightweight web framework for PureBasic 6.x. All modules are
accessed via their module prefix (e.g. `Engine::GET`, `Ctx::Advance`).

## Modules

| Module | File | Description |
|--------|------|-------------|
| [Engine](engine.md) | `src/Engine.pbi` | App lifecycle, route registration, middleware, error handlers |
| [Router](router.md) | `src/Router.pbi` | Radix trie router — Insert and Match |
| [Context](context.md) | `src/Context.pbi` | Per-request lifecycle: Advance, Abort, Param, KV store |
| [Binding](binding.md) | `src/Binding.pbi` | Request data extraction: Param, Query, PostForm, JSON |
| [Rendering](rendering.md) | `src/Rendering.pbi` | Response writing: JSON, HTML, Text, Redirect, File, Render |
| [Group](group.md) | `src/Group.pbi` | Route groups with shared prefix and middleware |
| [Middleware](middleware.md) | `src/Middleware/*.pbi` | Logger, Recovery, Cookie, Session, BasicAuth, CSRF |
| [DB / DBConnect](db.md) | `src/DB/SQLite.pbi`, `src/DB/Connect.pbi` | SQLite adapter, migration runner, and multi-driver DSN factory (PostgreSQL, MySQL) |
| [Config](config.md) | `src/Config.pbi` | .env loader and runtime key/value store |
| [Log](log.md) | `src/Log.pbi` | Leveled logger (Debug/Info/Warn/Error) |

## Quick Start

```purebasic
EnableExplicit
XIncludeFile "src/PureSimple.pb"

; Load config
Config::Load(".env")
Protected port.i = Config::GetInt("PORT", 8080)

; Global middleware
Engine::Use(@Logger::Middleware())
Engine::Use(@Recovery::Middleware())

; Routes
Engine::GET("/",        @IndexHandler())
Engine::GET("/health",  @HealthHandler())

Engine::Run(port)

Procedure IndexHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"hello\":\"world\"}")
EndProcedure

Procedure HealthHandler(*C.RequestContext)
  Rendering::Text(*C, "OK")
EndProcedure
```

## Request Lifecycle

```
HTTP request arrives at PureSimpleHTTPServer
  → dispatch callback invoked with raw method + path + headers + body
  → Router::Match(method, path) → route handler + params
  → Engine::CombineHandlers or Group::CombineHandlers
      builds flat handler array: [global MW...] [group MW...] [route handler]
  → Ctx::Init populates RequestContext
  → Ctx::Dispatch calls handlers[0]
  → Each middleware calls Ctx::Advance to pass control to the next handler
  → Route handler writes response via Rendering::*
  → PureSimpleHTTPServer sends StatusCode + ContentType + ResponseBody
```

## Handler Signature

Every route handler and middleware follows the same signature:

```purebasic
Prototype.i PS_HandlerFunc(*C.RequestContext)

Procedure MyHandler(*C.RequestContext)
  ; read request
  Protected id.s = Binding::Param(*C, "id")
  ; write response
  Rendering::JSON(*C, ~"{\"id\":\"" + id + ~"\"}")
EndProcedure
```

Pass its address with `@MyHandler()` when registering routes or middleware.

# Engine

`src/Engine.pbi` — Top-level application API.

## Route Registration

```purebasic
Engine::GET(Pattern.s, Handler.i)
Engine::POST(Pattern.s, Handler.i)
Engine::PUT(Pattern.s, Handler.i)
Engine::PATCH(Pattern.s, Handler.i)
Engine::DELETE(Pattern.s, Handler.i)
Engine::Any(Pattern.s, Handler.i)   ; registers all five methods
```

Patterns support:
- Literal segments: `/users/profile`
- Named params: `/users/:id`
- Wildcards: `/static/*path`

## Middleware

```purebasic
Engine::Use(Handler.i)              ; register global middleware
Engine::ResetMiddleware()           ; clear all middleware + error handlers (tests)
```

Global middleware is prepended to every request's handler chain by
`CombineHandlers` / `AppendGlobalMiddleware`. Execution order follows
registration order.

## Error Handlers

```purebasic
Engine::SetNotFoundHandler(Handler.i)
Engine::HandleNotFound(*C.RequestContext)

Engine::SetMethodNotAllowedHandler(Handler.i)
Engine::HandleMethodNotAllowed(*C.RequestContext)
```

When no handler is registered, default responses are written:
- 404: `"404 Not Found"` (`text/plain`)
- 405: `"405 Method Not Allowed"` (`text/plain`)

## Run Mode

```purebasic
Engine::SetMode("debug")     ; "debug" (default) | "release" | "test"
Engine::Mode()               ; returns current mode string
```

## App Lifecycle

```purebasic
Engine::NewApp()             ; stub — returns 0 (PureSimpleHTTPServer integration TBD)
Engine::Run(Port.i)          ; stub — returns #False (PureSimpleHTTPServer integration TBD)
```

## Internal (used by Group module)

```purebasic
Engine::CombineHandlers(*C.RequestContext, RouteHandler.i)
Engine::AppendGlobalMiddleware(*C.RequestContext)
```

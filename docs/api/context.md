# Context

`src/Context.pbi` — Per-request lifecycle and data access.

## Lifecycle

```purebasic
Ctx::Init(*C.RequestContext, ContextID.i)
```

Resets all fields of `*C` to zero/empty values and assigns the `ContextID`.
Called once per request before dispatching.

```purebasic
Ctx::AddHandler(*C.RequestContext, Handler.i)
Ctx::Dispatch(*C.RequestContext)
Ctx::Advance(*C.RequestContext)
```

`Dispatch` calls `handlers[0]`. Each middleware should call `Ctx::Advance` to
invoke the next handler in the chain. `Advance` is the Gin/Chi "Next" — the
name `Next` is a reserved PureBasic keyword.

## Abort

```purebasic
Ctx::Abort(*C.RequestContext)
Ctx::IsAborted(*C.RequestContext)            ; returns #True if aborted

Ctx::AbortWithStatus(*C.RequestContext, StatusCode.i)
Ctx::AbortWithError(*C.RequestContext, StatusCode.i, Message.s)
```

`Abort` stops the chain — subsequent `Advance` calls are no-ops. Use
`AbortWithError` for quick error responses from middleware:

```purebasic
Procedure AuthMiddleware(*C.RequestContext)
  If Not IsAuthorized(*C)
    Ctx::AbortWithError(*C, 401, "Unauthorized")
    ProcedureReturn
  EndIf
  Ctx::Advance(*C)
EndProcedure
```

## Route Parameters

```purebasic
Ctx::Param(*C.RequestContext, Name.s)    ; returns "" if not found
```

Named parameters captured from the route pattern (e.g. `/users/:id`).

## KV Store

```purebasic
Ctx::Set(*C.RequestContext, Key.s, Val.s)
Ctx::Get(*C.RequestContext, Key.s)       ; returns "" if not found
```

Per-request string store. Used to pass data between middleware and handlers,
and as template variables for `Rendering::Render`.

```purebasic
; Middleware sets a value
Procedure AuthMW(*C.RequestContext)
  Ctx::Set(*C, "user_id", "42")
  Ctx::Advance(*C)
EndProcedure

; Handler reads it
Procedure ProfileHandler(*C.RequestContext)
  Protected uid.s = Ctx::Get(*C, "user_id")
  Rendering::JSON(*C, ~"{\"id\":\"" + uid + ~"\"}")
EndProcedure
```

## RequestContext Fields

Key fields available directly on `*C`:

| Field | Type | Set by |
|-------|------|--------|
| `Method` | `.s` | HTTP server dispatch |
| `Path` | `.s` | HTTP server dispatch |
| `Body` | `.s` | HTTP server dispatch |
| `QueryString` | `.s` | HTTP server dispatch |
| `Cookie` | `.s` | HTTP server dispatch (raw Cookie header) |
| `Authorization` | `.s` | HTTP server dispatch |
| `StatusCode` | `.i` | Rendering procedures |
| `ResponseBody` | `.s` | Rendering procedures |
| `ContentType` | `.s` | Rendering procedures |
| `Location` | `.s` | `Rendering::Redirect` |
| `SetCookies` | `.s` | `Cookie::Set` (Chr(10)-delimited) |
| `SessionID` | `.s` | `Session::Middleware` |
| `SessionKeys` | `.s` | `Session::Middleware` |
| `SessionVals` | `.s` | `Session::Middleware` |

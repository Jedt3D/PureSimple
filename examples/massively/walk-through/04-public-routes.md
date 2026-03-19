# 04 — Public Routes

## Route table

| Method | Pattern | Handler | What it does |
|--------|---------|---------|-------------|
| GET | `/` | `IndexHandler` | Lists all published posts |
| GET | `/post/:slug` | `PostHandler` | Renders a single post |
| GET | `/contact` | `ContactGetHandler` | Shows the contact form |
| POST | `/contact` | `ContactPostHandler` | Saves submission, redirects |
| GET | `/contact/ok` | `ContactOkHandler` | Thank-you page |
| GET | `/health` | `HealthHandler` | JSON health check |

## Handler signature

Every handler has the same signature:

```purebasic
Procedure MyHandler(*C.RequestContext)
  ; ...
EndProcedure
```

`*C` is a pointer to the per-request context. It carries the raw HTTP data
(method, path, headers, body) and the KV store used to pass data to templates.

## Route registration

```purebasic
Engine::GET("/", @IndexHandler())
Engine::GET("/post/:slug", @PostHandler())
```

`@Handler()` is PureBasic syntax for taking the address of a procedure.
The router stores this as a function pointer.

> **Note**: `@Module::Proc()` does **not** work at the program level when
> `EnableExplicit` is active. Wrap module middleware in local procedures:
>
> ```purebasic
> Procedure _LoggerMW(*C.RequestContext)
>   Logger::Middleware(*C)
> EndProcedure
>
> Engine::Use(@_LoggerMW())
> ```

## Named parameters

`:slug` in the route pattern binds the matching path segment. Retrieve it with:

```purebasic
Protected slug.s = Binding::Param(*C, "slug")
```

`Binding::Param` delegates to `Ctx::Param`, which looks up the named segment
stored by the router when the route was matched.

## SetSiteVars helper

Every public handler calls `SetSiteVars(*C)` first. This queries `site_settings`
and calls `Ctx::Set` for `site_name` and `tagline`, making them available in
every template.

```purebasic
Procedure SetSiteVars(*C.RequestContext)
  ; ... query DB, then:
  Ctx::Set(*C, "site_name", SafeVal(siteName))
  Ctx::Set(*C, "tagline",   SafeVal(tagline))
EndProcedure
```

## The health endpoint

```purebasic
Procedure HealthHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"status\":\"ok\"}")
EndProcedure
```

The `~"..."` prefix enables escape sequences in PureBasic strings.
This endpoint is used by the deploy script's health check and by monitoring.

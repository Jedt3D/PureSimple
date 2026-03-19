# Rendering

`src/Rendering.pbi` — Write HTTP responses from handlers.

## JSON

```purebasic
Rendering::JSON(*C.RequestContext, Body.s, Status.i = 200)
```

Sets `ContentType = "application/json"`, `StatusCode`, and `ResponseBody`.

```purebasic
Rendering::JSON(*C, ~"{\"id\":1,\"name\":\"Alice\"}")
Rendering::JSON(*C, ~"{\"error\":\"not found\"}", 404)
```

## HTML

```purebasic
Rendering::HTML(*C.RequestContext, Body.s, Status.i = 200)
```

Sets `ContentType = "text/html"`.

## Text

```purebasic
Rendering::Text(*C.RequestContext, Body.s, Status.i = 200)
```

Sets `ContentType = "text/plain"`.

## Status Only

```purebasic
Rendering::Status(*C.RequestContext, Status.i)
```

Sets `StatusCode` without touching the body (e.g. for `204 No Content`).

## Redirect

```purebasic
Rendering::Redirect(*C.RequestContext, URL.s, Status.i = 302)
```

Sets `*C\Location` and the status code. Typical values: `302` (temporary),
`301` (permanent).

```purebasic
Rendering::Redirect(*C, "/login")
Rendering::Redirect(*C, "https://example.com", 301)
```

## File

```purebasic
Rendering::File(*C.RequestContext, Path.s)
```

Reads a file from disk and serves it as the response body. Sets
`ContentType = "text/plain"` and `StatusCode = 200`. If the file does not
exist, writes a `404 Not Found` response instead.

## Template Rendering

```purebasic
Rendering::Render(*C.RequestContext, TemplateName.s, TemplatesDir.s = "templates/")
```

Renders a Jinja template using PureJinja. Template variables come from the
request KV store (populated via `Ctx::Set`).

```purebasic
Procedure ProfileHandler(*C.RequestContext)
  Ctx::Set(*C, "username", "alice")
  Ctx::Set(*C, "role",     "admin")
  Rendering::Render(*C, "profile.html")   ; reads templates/profile.html
EndProcedure
```

Template (`templates/profile.html`):
```html
<h1>Hello, {{ username }}!</h1>
<p>Role: {{ role }}</p>
```

`Render` creates a PureJinja environment, calls `SetTemplatePath`, renders the
template, then frees all resources. On render failure the response body will
be the PureJinja error string.

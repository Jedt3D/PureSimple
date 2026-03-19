# Binding

`src/Binding.pbi` — Extract data from the incoming request.

## Route Parameters

```purebasic
Binding::Param(*C.RequestContext, Name.s)   ; delegates to Ctx::Param
```

Returns the value of a named route segment (e.g. `:id` in `/users/:id`).

## Query String

```purebasic
Binding::Query(*C.RequestContext, Name.s)
```

Lazy-parsed from `*C\QueryString`. Decodes `+` → space and `%XX` sequences.
Results are cached in `*C\QueryKeys`/`*C\QueryVals` after the first call.

```purebasic
; URL: GET /search?q=hello+world&page=2
q    = Binding::Query(*C, "q")     ; "hello world"
page = Binding::Query(*C, "page")  ; "2"
```

## Form Data

```purebasic
Binding::PostForm(*C.RequestContext, Field.s)
```

Parses `*C\Body` as `application/x-www-form-urlencoded`. URL-decodes values.
Lazily parsed and cached in `*C\FormKeys`/`*C\FormVals`.

```purebasic
; POST body: username=alice&password=s3cr3t
user = Binding::PostForm(*C, "username")
pass = Binding::PostForm(*C, "password")
```

## JSON Body

```purebasic
Binding::BindJSON(*C.RequestContext)                     ; parse *C\Body as JSON
Binding::JSONString(*C.RequestContext, Key.s)            ; get string field
Binding::JSONInteger(*C.RequestContext, Key.s)           ; get integer field
Binding::JSONBool(*C.RequestContext, Key.s)              ; get boolean field (0/#True)
Binding::ReleaseJSON(*C.RequestContext)                  ; free JSON handle
```

`BindJSON` stores a JSON handle in `*C\JSONHandle`. Always call `ReleaseJSON`
when done, or it will leak. `ReleaseJSON` is named to avoid shadowing the
PureBasic built-in `FreeJSON`.

```purebasic
Procedure CreateUser(*C.RequestContext)
  Binding::BindJSON(*C)
  Protected name.s  = Binding::JSONString(*C, "name")
  Protected age.i   = Binding::JSONInteger(*C, "age")
  Protected admin.i = Binding::JSONBool(*C, "admin")
  Binding::ReleaseJSON(*C)
  ; ...
EndProcedure
```

Returns safe defaults (`""` / `0` / `#False`) if `JSONHandle` is 0 or the key
is absent. Invalid JSON sets `JSONHandle = 0` and leaves `StatusCode = 400`.

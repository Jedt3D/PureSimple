# 06 — Contact Form

## Two-handler pattern: GET + POST on the same path

```purebasic
Engine::GET("/contact",  @ContactGetHandler())
Engine::POST("/contact", @ContactPostHandler())
```

GET serves the blank form. POST processes it.

## GET handler

```purebasic
Procedure ContactGetHandler(*C.RequestContext)
  SetSiteVars(*C)
  Ctx::Set(*C, "active_page", "contact")
  Rendering::Render(*C, "contact.html", _tplDir)
EndProcedure
```

## POST handler

```purebasic
Procedure ContactPostHandler(*C.RequestContext)
  Protected name.s    = SafeVal(Trim(Binding::PostForm(*C, "name")))
  Protected email.s   = SafeVal(Trim(Binding::PostForm(*C, "email")))
  Protected message.s = SafeVal(Trim(Binding::PostForm(*C, "message")))

  ; Validation
  If name = "" Or email = "" Or message = ""
    SetSiteVars(*C)
    Ctx::Set(*C, "error", "Please fill in all fields.")
    Rendering::Render(*C, "contact.html", _tplDir)
    ProcedureReturn
  EndIf

  ; Save to DB
  DB::BindStr(_db, 0, name)
  DB::BindStr(_db, 1, email)
  DB::BindStr(_db, 2, message)
  DB::BindStr(_db, 3, NowStr())
  DB::Exec(_db, "INSERT INTO contacts (name, email, message, submitted_at) VALUES (?, ?, ?, ?)")

  ; Redirect to thank-you page
  Rendering::Redirect(*C, "/contact?ok=1")
EndProcedure
```

## Key concepts

### `Binding::PostForm`

Parses `*C\Body` as a URL-encoded form (the `Content-Type: application/x-www-form-urlencoded`
payload sent by HTML forms). Returns the value for the named field.

```purebasic
name.s = Binding::PostForm(*C, "name")
```

### Validation on POST

If validation fails, re-render the form with an error message — do **not**
redirect. The user keeps their input and sees the error immediately.

```html
{% if error %}
<div class="box">{{ error }}</div>
{% endif %}
```

### Post-Redirect-Get (PRG)

After a successful POST, redirect to a GET endpoint:

```purebasic
Rendering::Redirect(*C, "/contact?ok=1")
```

This prevents form resubmission on browser refresh.

### `Trim` + `SafeVal`

Always trim whitespace and strip tabs from user input before storing:

```purebasic
name.s = SafeVal(Trim(Binding::PostForm(*C, "name")))
```

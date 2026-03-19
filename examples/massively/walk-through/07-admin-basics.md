# 07 — Admin Basics

## RouterGroup

A `RouterGroup` bundles a URL prefix with shared middleware. All routes
registered on the group automatically get the prefix and pass through the
group's middleware before the route handler.

```purebasic
; Wrapper required: @Module::Proc() doesn't work at program level with EnableExplicit
Procedure _BasicAuthMW(*C.RequestContext)
  BasicAuth::Middleware(*C)
EndProcedure

Define adminGrp.PS_RouterGroup
Group::Init(@adminGrp, "/admin")
Group::Use(@adminGrp, @_BasicAuthMW())

Group::GET(@adminGrp, "/",      @AdminDashHandler())
Group::GET(@adminGrp, "/posts", @AdminPostsHandler())
```

This registers `GET /admin/` and `GET /admin/posts`, both protected by
`BasicAuth::Middleware`.

## `Define` vs `Protected` for groups

`PS_RouterGroup` is a structure. When declared at the top level of a program
(outside a procedure), use `Define`:

```purebasic
Define adminGrp.PS_RouterGroup
```

Inside a procedure, use `Protected`:

```purebasic
Protected adminGrp.PS_RouterGroup
```

## BasicAuth middleware

```purebasic
BasicAuth::SetCredentials(
  Config::Get("ADMIN_USER", "admin"),
  Config::Get("ADMIN_PASS", "changeme")
)
```

`BasicAuth::Middleware` reads the `Authorization` header, decodes the Base64
credentials, and compares against the configured user/password.

- On success: stores `_auth_user` in the KV store and calls `Ctx::Advance`.
- On failure: writes `401 Unauthorized` and calls `Ctx::Abort`.

The browser automatically shows a credentials dialog when it receives a 401
with a `WWW-Authenticate: Basic` header.

## Handler chain for a group route

When `GET /admin/posts` is matched, the handler chain is:

```
Logger::Middleware          (global)
Recovery::Middleware        (global)
BasicAuth::Middleware       (group)
AdminPostsHandler           (route)
```

Each middleware calls `Ctx::Advance(*C)` to continue the chain.

## Reading config from `.env`

```purebasic
Config::Load("examples/massively/.env")
adminUser.s = Config::Get("ADMIN_USER", "admin")
adminPass.s = Config::Get("ADMIN_PASS", "changeme")
```

The second argument to `Config::Get` is the fallback value used when the key
is absent from the file.

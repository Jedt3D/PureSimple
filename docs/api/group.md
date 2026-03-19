# Group (Route Groups)

`src/Group.pbi` — Sub-routers with shared path prefix and middleware.

## Structure

```purebasic
Structure PS_RouterGroup
  Prefix.s
  MW.i[32]     ; group-level middleware (max 32)
  MWCount.i
EndStructure
```

## Procedures

```purebasic
Group::Init(*G.PS_RouterGroup, Prefix.s)
Group::Use(*G.PS_RouterGroup, Handler.i)

Group::GET(*G,    Pattern.s, Handler.i)
Group::POST(*G,   Pattern.s, Handler.i)
Group::PUT(*G,    Pattern.s, Handler.i)
Group::PATCH(*G,  Pattern.s, Handler.i)
Group::DELETE(*G, Pattern.s, Handler.i)
Group::Any(*G,    Pattern.s, Handler.i)

Group::SubGroup(*Parent.PS_RouterGroup, *Child.PS_RouterGroup, SubPrefix.s)
Group::CombineHandlers(*G.PS_RouterGroup, *C.RequestContext, RouteHandler.i)
```

## Example

```purebasic
; API group at /api/v1
Protected api.PS_RouterGroup
Group::Init(@api, "/api/v1")
Group::Use(@api, @AuthRequired())   ; middleware applied to all routes in group

Group::GET(@api,  "/users",     @ListUsers())
Group::POST(@api, "/users",     @CreateUser())
Group::GET(@api,  "/users/:id", @GetUser())

; Nested sub-group at /api/v1/admin
Protected admin.PS_RouterGroup
Group::SubGroup(@api, @admin, "/admin")
Group::Use(@admin, @AdminOnly())
Group::GET(@admin, "/dashboard", @Dashboard())
```

## Handler Chain

`Group::CombineHandlers` builds the chain in this order:

1. Global engine middleware (from `Engine::Use`)
2. Group middleware (from `Group::Use`)
3. Route handler

`SubGroup` copies parent middleware to the child, so inherited handlers execute
before child-only handlers. Adding middleware to the child after `SubGroup`
does not affect the parent.

## Dispatching

The application's dispatch callback (provided by PureSimpleHTTPServer) must
call `Group::CombineHandlers` (for group routes) or `Engine::CombineHandlers`
(for top-level routes) before calling `Ctx::Dispatch`.

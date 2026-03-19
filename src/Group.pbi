; Group.pbi — RouterGroup: sub-router with shared path prefix and middleware
;
; Usage:
;   Protected g.PS_RouterGroup
;   Group::Init(@g, "/api")
;   Group::Use(@g, @AuthMW())
;   Group::GET(@g, "/users", @UsersHandler())   ; registers GET /api/users
;
; Nesting:
;   Protected g2.PS_RouterGroup
;   Group::SubGroup(@g, @g2, "/v1")             ; prefix = /api/v1, inherits MW
;   Group::GET(@g2, "/items", @ItemsHandler())  ; registers GET /api/v1/items
;
; Dispatch:
;   Group::CombineHandlers(@g, @ctx, @RouteHandler())
;   ; → global MW + group MW + route handler, in that order

EnableExplicit

DeclareModule Group
  Declare     Init(*G.PS_RouterGroup, Prefix.s)
  Declare     Use(*G.PS_RouterGroup, Handler.i)
  Declare     GET(*G.PS_RouterGroup, Pattern.s, Handler.i)
  Declare     POST(*G.PS_RouterGroup, Pattern.s, Handler.i)
  Declare     PUT(*G.PS_RouterGroup, Pattern.s, Handler.i)
  Declare     PATCH(*G.PS_RouterGroup, Pattern.s, Handler.i)
  Declare     DELETE(*G.PS_RouterGroup, Pattern.s, Handler.i)
  Declare     Any(*G.PS_RouterGroup, Pattern.s, Handler.i)
  Declare     SubGroup(*Parent.PS_RouterGroup, *Child.PS_RouterGroup, SubPrefix.s)
  Declare     CombineHandlers(*G.PS_RouterGroup, *C.RequestContext, RouteHandler.i)
EndDeclareModule

Module Group
  UseModule Types

  ; ------------------------------------------------------------------
  ; Init — set group prefix and reset middleware count
  ; ------------------------------------------------------------------
  Procedure Init(*G.PS_RouterGroup, Prefix.s)
    *G\Prefix   = Prefix
    *G\MWCount  = 0
  EndProcedure

  ; ------------------------------------------------------------------
  ; Use — append a middleware handler to this group's chain
  ; ------------------------------------------------------------------
  Procedure Use(*G.PS_RouterGroup, Handler.i)
    If *G\MWCount < 32
      *G\MW[*G\MWCount] = Handler
      *G\MWCount + 1
    EndIf
  EndProcedure

  ; ------------------------------------------------------------------
  ; Route registration helpers (prefix + pattern → Router::Insert)
  ; ------------------------------------------------------------------
  Procedure GET(*G.PS_RouterGroup, Pattern.s, Handler.i)
    Router::Insert("GET", *G\Prefix + Pattern, Handler)
  EndProcedure

  Procedure POST(*G.PS_RouterGroup, Pattern.s, Handler.i)
    Router::Insert("POST", *G\Prefix + Pattern, Handler)
  EndProcedure

  Procedure PUT(*G.PS_RouterGroup, Pattern.s, Handler.i)
    Router::Insert("PUT", *G\Prefix + Pattern, Handler)
  EndProcedure

  Procedure PATCH(*G.PS_RouterGroup, Pattern.s, Handler.i)
    Router::Insert("PATCH", *G\Prefix + Pattern, Handler)
  EndProcedure

  Procedure DELETE(*G.PS_RouterGroup, Pattern.s, Handler.i)
    Router::Insert("DELETE", *G\Prefix + Pattern, Handler)
  EndProcedure

  Procedure Any(*G.PS_RouterGroup, Pattern.s, Handler.i)
    Protected full.s = *G\Prefix + Pattern
    Router::Insert("GET",    full, Handler)
    Router::Insert("POST",   full, Handler)
    Router::Insert("PUT",    full, Handler)
    Router::Insert("PATCH",  full, Handler)
    Router::Insert("DELETE", full, Handler)
  EndProcedure

  ; ------------------------------------------------------------------
  ; SubGroup — create a nested group inheriting parent prefix + MW
  ; ------------------------------------------------------------------
  Procedure SubGroup(*Parent.PS_RouterGroup, *Child.PS_RouterGroup, SubPrefix.s)
    Protected i.i
    *Child\Prefix  = *Parent\Prefix + SubPrefix
    *Child\MWCount = *Parent\MWCount
    For i = 0 To *Parent\MWCount - 1
      *Child\MW[i] = *Parent\MW[i]
    Next i
  EndProcedure

  ; ------------------------------------------------------------------
  ; CombineHandlers — build the full handler chain:
  ;   global engine middleware + group middleware + route handler
  ; ------------------------------------------------------------------
  Procedure CombineHandlers(*G.PS_RouterGroup, *C.RequestContext, RouteHandler.i)
    Protected i.i
    Engine::AppendGlobalMiddleware(*C)
    For i = 0 To *G\MWCount - 1
      Ctx::AddHandler(*C, *G\MW[i])
    Next i
    Ctx::AddHandler(*C, RouteHandler)
  EndProcedure

EndModule

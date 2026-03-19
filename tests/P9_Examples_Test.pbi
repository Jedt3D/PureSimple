; P9_Examples_Test.pbi — Smoke tests for example app patterns (P9)
;
; P9 is documentation + examples. These tests verify that the patterns
; shown in the examples and API docs compile and produce correct results
; using the framework as a unit-test harness (no live HTTP server needed).
;
; Covered patterns:
;   - Todo app: JSON CRUD request lifecycle
;   - Blog app: KV store for template vars, named param routing
;   - Config + Log integration (P8 building block used by examples)
;   - Engine::SetNotFoundHandler custom 404

; ---- Shared helper procedures ----------------------------------------------

Procedure P9Todo_ListHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"[{\"id\":1,\"title\":\"buy milk\"}]")
EndProcedure

Procedure P9Todo_CreateHandler(*C.RequestContext)
  Binding::BindJSON(*C)
  Protected title.s = Binding::JSONString(*C, "title")
  Binding::ReleaseJSON(*C)
  If title = ""
    Ctx::AbortWithError(*C, 400, ~"{\"error\":\"title required\"}")
    ProcedureReturn
  EndIf
  Rendering::JSON(*C, ~"{\"id\":2,\"title\":\"" + title + ~"\"}", 201)
EndProcedure

Procedure P9Todo_GetHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  Rendering::JSON(*C, ~"{\"id\":" + id + ~",\"title\":\"buy milk\"}")
EndProcedure

Procedure P9Todo_DeleteHandler(*C.RequestContext)
  Rendering::Status(*C, 204)
EndProcedure

Procedure P9Blog_HomeHandler(*C.RequestContext)
  Ctx::Set(*C, "site_name", "Test Blog")
  Ctx::Set(*C, "count", "3")
  Rendering::Text(*C, "Home: " + Ctx::Get(*C, "site_name"))
EndProcedure

Procedure P9Blog_PostHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")
  Rendering::Text(*C, "Post: " + slug)
EndProcedure

Procedure P9HealthHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"status\":\"ok\"}")
EndProcedure

Procedure P9_Custom404(*C.RequestContext)
  Rendering::Text(*C, "custom 404", 404)
EndProcedure

; ---- Tests -----------------------------------------------------------------

Procedure P9_Examples_Tests()
  Protected ctx.RequestContext
  Protected handler.i

  ; ---------------------------------------------------------------
  ; Todo API — GET /todos (list)
  ; ---------------------------------------------------------------
  Router::Insert("GET", "/todos", @P9Todo_ListHandler())

  Ctx::Init(@ctx, "GET", "/todos")
  handler = Router::Match("GET", "/todos", @ctx)
  Check(handler <> 0)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 200)
  CheckStr(ctx\ContentType, "application/json")
  Check(FindString(ctx\ResponseBody, "buy milk") > 0)

  ; ---------------------------------------------------------------
  ; Todo API — POST /todos (create, valid JSON)
  ; ---------------------------------------------------------------
  Router::Insert("POST", "/todos", @P9Todo_CreateHandler())

  Ctx::Init(@ctx, "POST", "/todos")
  ctx\Body = ~"{\"title\":\"write docs\"}"
  handler = Router::Match("POST", "/todos", @ctx)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 201)
  Check(FindString(ctx\ResponseBody, "write docs") > 0)

  ; ---------------------------------------------------------------
  ; Todo API — POST /todos (create, missing title → 400)
  ; ---------------------------------------------------------------
  Ctx::Init(@ctx, "POST", "/todos")
  ctx\Body = "{}"
  handler = Router::Match("POST", "/todos", @ctx)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 400)
  Check(FindString(ctx\ResponseBody, "title required") > 0)

  ; ---------------------------------------------------------------
  ; Todo API — GET /todos/:id (named param)
  ; ---------------------------------------------------------------
  Router::Insert("GET", "/todos/:id", @P9Todo_GetHandler())

  Ctx::Init(@ctx, "GET", "/todos/42")
  handler = Router::Match("GET", "/todos/42", @ctx)
  Check(handler <> 0)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 200)
  Check(FindString(ctx\ResponseBody, "42") > 0)

  ; ---------------------------------------------------------------
  ; Todo API — DELETE /todos/:id (204 No Content)
  ; ---------------------------------------------------------------
  Router::Insert("DELETE", "/todos/:id", @P9Todo_DeleteHandler())

  Ctx::Init(@ctx, "DELETE", "/todos/7")
  handler = Router::Match("DELETE", "/todos/7", @ctx)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 204)

  ; ---------------------------------------------------------------
  ; Blog — GET /blog (home, KV store as template vars)
  ; ---------------------------------------------------------------
  Router::Insert("GET", "/blog", @P9Blog_HomeHandler())

  Ctx::Init(@ctx, "GET", "/blog")
  handler = Router::Match("GET", "/blog", @ctx)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 200)
  CheckStr(ctx\ResponseBody, "Home: Test Blog")

  ; ---------------------------------------------------------------
  ; Blog — GET /blog/post/:slug (named param)
  ; ---------------------------------------------------------------
  Router::Insert("GET", "/blog/post/:slug", @P9Blog_PostHandler())

  Ctx::Init(@ctx, "GET", "/blog/post/hello-world")
  handler = Router::Match("GET", "/blog/post/hello-world", @ctx)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 200)
  CheckStr(ctx\ResponseBody, "Post: hello-world")

  ; ---------------------------------------------------------------
  ; Health check route
  ; ---------------------------------------------------------------
  Router::Insert("GET", "/ex-health", @P9HealthHandler())

  Ctx::Init(@ctx, "GET", "/ex-health")
  handler = Router::Match("GET", "/ex-health", @ctx)
  Engine::CombineHandlers(@ctx, handler)
  Ctx::Dispatch(@ctx)
  CheckEqual(ctx\StatusCode, 200)
  Check(FindString(ctx\ResponseBody, "ok") > 0)

  ; ---------------------------------------------------------------
  ; Config + Log integration (P8 building block used by examples)
  ; ---------------------------------------------------------------
  Config::Reset()
  Config::Set("PORT", "9090")
  Config::Set("MODE", "test")
  CheckEqual(Config::GetInt("PORT", 8080), 9090)
  CheckStr(Config::Get("MODE", "debug"), "test")

  Engine::SetMode(Config::Get("MODE", "debug"))
  CheckStr(Engine::Mode(), "test")
  Engine::SetMode("debug")   ; restore

  ; ---------------------------------------------------------------
  ; Custom 404 pattern (used by blog for missing post slugs)
  ; ---------------------------------------------------------------
  Engine::SetNotFoundHandler(@P9_Custom404())
  Ctx::Init(@ctx, "GET", "/totally/missing")
  Engine::HandleNotFound(@ctx)
  CheckEqual(ctx\StatusCode, 404)
  Check(FindString(ctx\ResponseBody, "custom") > 0)
  Engine::ResetMiddleware()   ; clean up

EndProcedure

P9_Examples_Tests()

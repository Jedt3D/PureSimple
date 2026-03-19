# Router

`src/Router.pbi` — Radix trie-based HTTP router.

> Most applications interact with the router indirectly through `Engine::GET`,
> `Engine::POST`, etc. Direct use of `Router::Insert` and `Router::Match` is
> needed only when building custom dispatch callbacks.

## Insert

```purebasic
Router::Insert(Method.s, Pattern.s, Handler.i)
```

Registers a handler for the given HTTP method and URL pattern.

- `Method` must be uppercase: `"GET"`, `"POST"`, `"PUT"`, `"PATCH"`, `"DELETE"`
- `Pattern` supports:
  - **Literal**: `/users/profile`
  - **Named param**: `/users/:id` — captured as `id` in the context
  - **Wildcard**: `/static/*path` — captures everything from that segment onward

Patterns are stored in a per-method trie. Segment priority:
1. Exact match (fastest)
2. Named param (`:name`)
3. Wildcard (`*name`)

## Match

```purebasic
Router::Match(Method.s, Path.s, *C.RequestContext)
```

Walks the trie and populates `*C\ParamKeys`/`*C\ParamVals` with captured
parameters. Returns the handler address, or `0` if:
- No route matches (`→ Engine::HandleNotFound`)
- Route exists but not for this method (`→ Engine::HandleMethodNotAllowed`)

## Pattern Examples

```purebasic
Router::Insert("GET",    "/",               @HomeHandler())
Router::Insert("GET",    "/users",          @ListUsers())
Router::Insert("GET",    "/users/:id",      @GetUser())
Router::Insert("POST",   "/users",          @CreateUser())
Router::Insert("DELETE", "/users/:id",      @DeleteUser())
Router::Insert("GET",    "/files/*path",    @ServeFile())
```

```
GET /users/42    → GetUser,  id="42"
GET /files/a/b   → ServeFile, path="a/b"
GET /users       → ListUsers (exact beats param)
```

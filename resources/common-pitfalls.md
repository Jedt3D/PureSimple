# PureBasic Common Pitfalls

A growing list of PureBasic gotchas discovered while building PureSimple.
Add new entries at the bottom as they are discovered each phase.

---

## File existence — use `FileSize`, not `FileExists`

```purebasic
; WRONG — FileExists() does not exist in PureBasic
If FileExists("config.env") ...

; RIGHT
If FileSize("config.env") >= 0 ...
```

`FileSize()` returns -1 if the path does not exist, ≥ 0 for files,
and a negative value for directories on some platforms — check
`DirectoryEntryType()` if you need to distinguish files from directories.

---

## `Dim a(N)` creates N+1 elements

```purebasic
Dim items(9)   ; creates elements 0..9 → 10 elements, NOT 9
```

The argument to `Dim` is the **maximum index**, not the count.
To size an array to exactly `N` elements: `Dim items(N - 1)`.

---

## `XIncludeFile` vs `IncludeFile`

| Directive | Behaviour |
|-----------|-----------|
| `IncludeFile` | Includes unconditionally — duplicate definitions if included twice |
| `XIncludeFile` | Guard-included — safe to appear in multiple files |

**Always use `XIncludeFile`** in framework modules. Use `IncludeFile`
only for the top-level entry point where you are certain of include order.

---

## `EnableExplicit` is mandatory

Without `EnableExplicit`, undeclared variables silently default to 0/empty
string, hiding typos and logic errors. Every `.pb` and `.pbi` file must
start with `EnableExplicit`.

---

## `.i` type is pointer-sized (4 bytes on x86, 8 bytes on x64)

```purebasic
; Safe for IDs, handles, loop counters, booleans
Protected handle.i
Protected id.i = CreateImage(#PB_Any, 100, 100)

; Use .l (32-bit) or .q (64-bit) when you need a fixed-size integer
Protected counter.l   ; always 32-bit
```

Mixing `.i` with `.l` in structures passed to external DLLs or
binary file I/O will cause misalignment on 64-bit builds.

---

## `StringField` is 1-based, not 0-based

```purebasic
; WRONG — returns empty string
first = StringField("a,b,c", 0, ",")

; RIGHT
first = StringField("a,b,c", 1, ",")   ; → "a"
```

---

## Procedure address syntax: `@MyProc()` (with parentheses)

```purebasic
; WRONG
addr = @MyProc

; RIGHT
addr = @MyProc()
```

PureBasic requires the `()` when taking the address of a procedure
with `@`. Omitting them compiles silently but returns wrong/zero values.

---

## `-cl` flag required for console output

```bash
# WRONG — PrintN() output invisible in GUI mode
pbcompiler tests/run_all.pb -o run_all

# RIGHT — compile as console binary
pbcompiler tests/run_all.pb -cl -o run_all
```

Without `-cl`, the binary is a GUI application; `PrintN()` and `Print()`
produce no visible output and the process exits silently.

---

## Always capture `#PB_Any` return values

```purebasic
; WRONG — ID lost, resource leaks
CreateImage(#PB_Any, 100, 100)

; RIGHT
Protected img.i = CreateImage(#PB_Any, 100, 100)
If img = 0
  ; handle failure
EndIf
```

`#PB_Any` tells PureBasic to auto-assign an ID. If you discard the
return value you can never free the resource and can't check for
allocation failure.

---

## Thread-safety requires `-t` compiler flag

Any code that uses `CreateThread()`, `Mutex*()`, or `Semaphore*()` must
be compiled with the `-t` (threadsafe) flag:

```bash
pbcompiler src/main.pb -t -o app
```

Without `-t`, the runtime library is not thread-safe and data races
are silently introduced.

---

## String escape sequences need `~"..."` prefix

```purebasic
; WRONG — \n is NOT a newline in regular strings
msg.s = "line1\nline2"

; RIGHT — tilde prefix enables C-style escapes
msg.s = ~"line1\nline2"
```

Supported escapes: `\n`, `\t`, `\r`, `\\`, `\"`, `\a`, `\b`, `\f`.

---

## Module bodies cannot see main-code globals — use `DeclareModule` + `UseModule`

PureBasic module bodies are complete black boxes. Procedures, variables, and
**structures** defined outside a module are NOT accessible inside a `Module`
body, even when declared `Global`.

```purebasic
; WRONG — RequestContext is "global" but Module body can't see it
Structure RequestContext : ... : EndStructure   ; main-code global

Module Router
  Procedure.i Match(*Ctx.RequestContext)  ; ERROR: Structure not found
  EndProcedure
EndModule
```

**Solution**: wrap shared types in their own `DeclareModule`/`Module`, then
`UseModule` inside the consuming modules.

```purebasic
; Types.pbi
DeclareModule Types
  Structure RequestContext : ... : EndStructure
EndDeclareModule
Module Types : EndModule   ; no runtime code needed

; Router.pbi
Module Router
  UseModule Types   ; imports RequestContext, etc. into this module's scope
  Procedure.i Match(*Ctx.RequestContext)   ; OK
  EndProcedure
EndModule

; Main code — UseModule at program level for test files and entry points
UseModule Types
myCtx.RequestContext   ; accessible without Types:: prefix
```

---

## `Next` is a reserved PureBasic keyword — can't use it as a procedure name

`Next` closes a `For…Next` loop in PureBasic and cannot be redeclared as a
procedure, even inside a module.

```purebasic
; WRONG — compiler error: "A procedure can't have the same name as a keyword"
Procedure Next(*C.RequestContext) ...

; RIGHT — use an alternative name
Procedure Advance(*C.RequestContext) ...  ; PureSimple uses Ctx::Advance
```

Other loop-related keywords to avoid: `Break`, `Continue`, `Until`, `Wend`.

---

## `@Module::Proc()` cannot be used in `Global` variable initializers

```purebasic
; WRONG — evaluates to 0 at runtime
Global handler.i = @Logger::Middleware()

; RIGHT — capture via a thin wrapper procedure
Procedure LoggerMW(*C.RequestContext)
  Logger::Middleware(*C)
EndProcedure
; then use: @LoggerMW()
```

Module procedure addresses cannot be resolved in `Global` declaration initialisers.
Wrap module procedures in plain procedures and take `@` of those instead.

---

## `OnErrorGoto` does not catch OS signals on macOS arm64

`OnErrorGoto(?label)` uses `setjmp`/`longjmp` to intercept PureBasic-runtime-detected errors.
On macOS arm64, OS-level signals (SIGSEGV from null-pointer, SIGHUP from `RaiseError(N)`)
reach the process before PureBasic's checkpoint fires and terminate the process.

```purebasic
; RaiseError(1) sends signal 1 (SIGHUP) on macOS arm64 — exit 129, not caught
RaiseError(1)

; Null-pointer write also crashes before OnErrorGoto fires on macOS arm64
Protected *p.MyStruct = 0
*p\field = 1   ; SIGSEGV, not caught by OnErrorGoto on arm64
```

Recovery middleware using `OnErrorGoto` works on Linux and Windows where PureBasic
intercepts these signals. On macOS arm64, only PureBasic-specific runtime errors
(array bounds with `-d`, etc.) are reliably catchable.

---

## Module procedure name must not shadow a PureBasic built-in

```purebasic
; WRONG — inside Module Binding, FreeJSON(*C) shadows the built-in FreeJSON(json.i)
; Calls to FreeJSON(someInteger) inside the module become ambiguous/recursive
Module Binding
  Procedure FreeJSON(*C.RequestContext)   ; shadows built-in FreeJSON!
    FreeJSON(*C\JSONHandle)               ; calls itself, NOT the built-in
  EndProcedure
EndModule

; RIGHT — use a distinct name
Module Binding
  Procedure ReleaseJSON(*C.RequestContext)
    FreeJSON(*C\JSONHandle)               ; unambiguously calls PB built-in
  EndProcedure
EndModule
```

Any module procedure whose name matches a PureBasic built-in will shadow it
within that module body. Choose distinct names (e.g. `ReleaseJSON`, `CloseDB`).

---

## `JinjaEnv::RenderString` vs `JinjaEnv::RenderTemplate`

Both are valid PureJinja high-level API entry points:

- `RenderString(*env, templateStr.s, vars())` — render from an inline string
- `RenderTemplate(*env, fileName.s, vars())` — load from disk and render

`RenderTemplate` requires `SetTemplatePath(*env, "templates/")` first.
Both handle Tokenize → Parse → Render internally. Use `RenderTemplate` for
file-based templates in production; use `RenderString` for unit tests.

---

## `Ctx::Set` KV store keys must not contain `Chr(9)` (tab)

The KV store uses `Chr(9)` as a field delimiter. Keys or values containing
a tab character will corrupt the store. Use only printable characters in
template variable names and string values passed via `Ctx::Set`.

```purebasic
; WRONG — tab in key corrupts the KV store
Ctx::Set(@ctx, "my" + Chr(9) + "key", "value")

; RIGHT — plain alphanumeric or snake_case keys
Ctx::Set(@ctx, "my_key", "value")
```

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

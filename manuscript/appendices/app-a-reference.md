# Appendix A: PureBasic Quick Reference for Web Developers

This appendix is a desk reference for developers coming to PureBasic from Go, Python, C, or JavaScript. Keep it open while reading framework code. Everything here fits on a mental index card once you have written a few handlers.

---

## A.1 Language Comparison Table

The table below maps the concepts you already know to their PureBasic equivalents. Where PureBasic does something differently, the "Notes" column explains why.

| Concept | PureBasic | Go | Python | C |
|---|---|---|---|---|
| **Integer type** | `.i` (pointer-sized) | `int` | `int` | `intptr_t` |
| **32-bit integer** | `.l` (Long) | `int32` | N/A | `int32_t` |
| **64-bit integer** | `.q` (Quad) | `int64` | N/A | `int64_t` |
| **Float** | `.f` (32-bit) | `float32` | N/A | `float` |
| **Double** | `.d` (64-bit) | `float64` | `float` | `double` |
| **Byte** | `.b` | `byte` | N/A | `char` |
| **Word (16-bit)** | `.w` | `int16` | N/A | `int16_t` |
| **String** | `.s` | `string` | `str` | `char*` |
| **Boolean** | `.i` (`#True`/`#False`) | `bool` | `bool` | `_Bool` / `int` |
| **Struct** | `Structure...EndStructure` | `type struct` | `@dataclass` | `struct` |
| **Hash map** | `NewMap name.type()` | `map[K]V` | `dict` | N/A (roll your own) |
| **Linked list** | `NewList name.type()` | `list.List` | `list` | N/A (roll your own) |
| **Array** | `Dim name.type(N)` | `[N]type` | `list` | `type name[N]` |
| **Function** | `Procedure Name()` | `func Name()` | `def name():` | `void name()` |
| **Return value** | `ProcedureReturn val` | `return val` | `return val` | `return val` |
| **Function pointer** | `Prototype.i Fn(*arg)` | `type Fn func(arg)` | callable | `typedef int (*Fn)(arg)` |
| **Address-of function** | `@MyProc()` | N/A (closures) | N/A | `&myFunc` |
| **Module / package** | `DeclareModule...Module` | `package` | `import module` | `#include` |
| **Import module** | `UseModule Name` | `import "pkg"` | `from pkg import *` | N/A |
| **Error handling** | Return code + `OnErrorGoto` | `if err != nil` | `try/except` | Return code |
| **String escape** | `~"hello\n"` | `"hello\n"` | `"hello\n"` | `"hello\n"` |
| **String concat** | `a + b` | `a + b` | `a + b` | `strcat()` |
| **Explicit vars** | `EnableExplicit` | Implicit (`:=`) | N/A | Implicit |
| **Scope qualifier** | `Protected` / `Global` | Package-level | `global` | `static` / `extern` |
| **Loop (for)** | `For i = 0 To N ... Next` | `for i := 0; i <= N; i++` | `for i in range(N+1):` | `for (int i=0; i<=N; i++)` |
| **Loop (while)** | `While cond ... Wend` | `for cond { }` | `while cond:` | `while (cond) { }` |
| **Conditional** | `If ... ElseIf ... Else ... EndIf` | `if ... else if ... else` | `if ... elif ... else:` | `if ... else if ... else` |
| **Switch** | `Select val ... Case ... Default ... EndSelect` | `switch val` | `match val:` (3.10+) | `switch (val)` |
| **Include file** | `XIncludeFile "file.pbi"` | `import "pkg"` | `import module` | `#include "file.h"` |
| **Constants** | `#Name = value` | `const Name = value` | `NAME = value` | `#define NAME value` |
| **Null pointer** | `0` or `#Null` | `nil` | `None` | `NULL` |
| **Print to stdout** | `PrintN("text")` | `fmt.Println("text")` | `print("text")` | `printf("text\n")` |
| **Compilation** | `pbcompiler file.pb` | `go build file.go` | Interpreted | `gcc file.c` |

**Compiler paths by platform:**

| Platform | `PUREBASIC_HOME` | Compiler path |
|---|---|---|
| macOS | `/Applications/PureBasic.app/Contents/Resources` | `$PUREBASIC_HOME/compilers/pbcompiler` |
| Linux | `/usr/local/purebasic` (typical) | `$PUREBASIC_HOME/compilers/pbcompiler` |
| Windows (CMD) | `C:\Program Files\PureBasic` | `"%PUREBASIC_HOME%\Compilers\pbcompiler.exe"` |
| Windows (PowerShell) | `C:\Program Files\PureBasic` | `& "$env:PUREBASIC_HOME\Compilers\pbcompiler.exe"` |

---

## A.2 Standard Library Cheat Sheet

### String Functions

| Function | Purpose | Example |
|---|---|---|
| `Len(s)` | String length | `Len("hello")` = 5 |
| `Left(s, n)` | First n characters | `Left("hello", 3)` = `"hel"` |
| `Right(s, n)` | Last n characters | `Right("hello", 3)` = `"llo"` |
| `Mid(s, start, len)` | Substring (1-based) | `Mid("hello", 2, 3)` = `"ell"` |
| `FindString(s, sub)` | Find substring (1-based, 0 = not found) | `FindString("hello", "ll")` = 3 |
| `ReplaceString(s, old, new)` | Replace all occurrences | `ReplaceString("aab", "a", "x")` = `"xxb"` |
| `UCase(s)` | Uppercase | `UCase("hello")` = `"HELLO"` |
| `LCase(s)` | Lowercase | `LCase("HELLO")` = `"hello"` |
| `Trim(s)` | Strip leading/trailing whitespace | `Trim("  hi  ")` = `"hi"` |
| `LTrim(s)` | Strip leading whitespace | `LTrim("  hi")` = `"hi"` |
| `RTrim(s)` | Strip trailing whitespace | `RTrim("hi  ")` = `"hi"` |
| `StringField(s, index, delim)` | Split and get Nth field (1-based) | `StringField("a,b,c", 2, ",")` = `"b"` |
| `CountString(s, sub)` | Count occurrences | `CountString("abab", "ab")` = 2 |
| `Str(n)` | Integer to string | `Str(42)` = `"42"` |
| `StrD(d, decimals)` | Double to string | `StrD(3.14, 2)` = `"3.14"` |
| `Val(s)` | String to integer | `Val("42")` = 42 |
| `ValD(s)` | String to double | `ValD("3.14")` = 3.14 |
| `Chr(n)` | Character code to string | `Chr(65)` = `"A"` |
| `Asc(s)` | First character to code | `Asc("A")` = 65 |
| `Space(n)` | n space characters | `Space(5)` = `"     "` |

### File Functions

| Function | Purpose | Example |
|---|---|---|
| `FileSize(path)` | File size in bytes (-1 = not found, -2 = directory) | `If FileSize("app.db") >= 0` |
| `ReadFile(id, path)` | Open for reading | `f = ReadFile(#PB_Any, "data.txt")` |
| `CreateFile(id, path)` | Create/overwrite for writing | `f = CreateFile(#PB_Any, "out.txt")` |
| `OpenFile(id, path)` | Open for read+write | `f = OpenFile(#PB_Any, "log.txt")` |
| `CloseFile(f)` | Close file handle | `CloseFile(f)` |
| `ReadString(f)` | Read one line | `line.s = ReadString(f)` |
| `WriteStringN(f, s)` | Write line + newline | `WriteStringN(f, "hello")` |
| `WriteString(f, s)` | Write without newline | `WriteString(f, "data")` |
| `Eof(f)` | End of file? | `While Not Eof(f) ... Wend` |
| `Lof(f)` | File length in bytes | `size = Lof(f)` |
| `FileSeek(f, pos)` | Seek to byte offset | `FileSeek(f, Lof(f))` |
| `GetCurrentDirectory()` | Current working directory | `cwd.s = GetCurrentDirectory()` |
| `GetTemporaryDirectory()` | OS temp directory | `tmp.s = GetTemporaryDirectory()` |

### JSON Functions

| Function | Purpose | Example |
|---|---|---|
| `ParseJSON(id, text)` | Parse JSON string | `j = ParseJSON(#PB_Any, body)` |
| `JSONValue(j)` | Root value handle | `*root = JSONValue(j)` |
| `GetJSONString(*val)` | Get string from value | `name.s = GetJSONString(*val)` |
| `GetJSONInteger(*val)` | Get integer from value | `age.i = GetJSONInteger(*val)` |
| `GetJSONDouble(*val)` | Get double from value | `score.d = GetJSONDouble(*val)` |
| `GetJSONBoolean(*val)` | Get boolean from value | `ok.i = GetJSONBoolean(*val)` |
| `JSONObjectMember(*obj, key)` | Get member by key | `*name = JSONObjectMember(*root, "name")` |
| `JSONArraySize(*arr)` | Array element count | `n = JSONArraySize(*arr)` |
| `GetJSONElement(*arr, idx)` | Array element by index | `*elem = GetJSONElement(*arr, 0)` |
| `FreeJSON(j)` | Free parsed JSON | `FreeJSON(j)` |
| `CreateJSON(id)` | Create empty JSON | `j = CreateJSON(#PB_Any)` |
| `SetJSONString(*val, s)` | Set string value | `SetJSONString(*val, "hello")` |
| `SetJSONInteger(*val, n)` | Set integer value | `SetJSONInteger(*val, 42)` |
| `ComposeJSON(j)` | Render JSON to string | `result.s = ComposeJSON(j)` |

### Cryptography and Hashing

| Function | Purpose | Example |
|---|---|---|
| `Fingerprint(mem, size, type)` | Hash memory buffer | `Fingerprint(*buf, sz, #PB_Cipher_SHA2)` |
| `StringFingerprint(s, type)` | Hash string | `StringFingerprint("pass", #PB_Cipher_SHA2, 256)` |
| `Base64Encoder(*in, inLen, *out, outLen)` | Base64 encode | `Base64Encoder(*src, sz, *dst, dstSz)` |
| `Base64Decoder(*in, inLen, *out, outLen)` | Base64 decode | `Base64Decoder(*src, sz, *dst, dstSz)` |

### Date and Time

| Function | Purpose | Example |
|---|---|---|
| `Date()` | Current Unix timestamp | `now.i = Date()` |
| `FormatDate(fmt, date)` | Format date | `FormatDate("%yyyy-%mm-%dd", Date())` |
| `Year(date)` | Extract year | `y = Year(Date())` |
| `Month(date)`, `Day(date)` | Extract month/day | `m = Month(Date())` |
| `ElapsedMilliseconds()` | Monotonic timer | `start = ElapsedMilliseconds()` |
| `Delay(ms)` | Sleep | `Delay(1000)` (sleep 1 second) |

### Memory and System

| Function | Purpose | Example |
|---|---|---|
| `AllocateMemory(size)` | Allocate bytes | `*buf = AllocateMemory(1024)` |
| `FreeMemory(*buf)` | Free allocation | `FreeMemory(*buf)` |
| `PokeS(*mem, s)` | Write string to memory | `PokeS(*buf, "hello")` |
| `PeekS(*mem)` | Read string from memory | `s.s = PeekS(*buf)` |
| `CopyMemory(*src, *dst, size)` | Copy bytes | `CopyMemory(*a, *b, 100)` |
| `Random(max)` | Random integer 0..max | `n = Random(100)` |
| `RandomSeed(seed)` | Seed the RNG | `RandomSeed(Date())` |

---

## A.3 Common Gotchas Table

These are the mistakes that trip up every PureBasic newcomer. The "PureBasic Gotcha" callout boxes throughout the book reference this table. Each entry has been discovered through real project work on the PureSimple framework.

| # | Gotcha | What you expect | What actually happens | Fix |
|---|---|---|---|---|
| 1 | **`FileExists()` does not exist** | A function to check if a file exists | Compiler error: unknown function | Use `FileSize(path) >= 0` instead. Returns -1 for "not found", -2 for "is a directory". |
| 2 | **`Dim a(N)` creates N+1 elements** | `Dim a(5)` creates 5 elements | Creates 6 elements (indices 0 through 5 inclusive) | Use `Dim a(N-1)` if you want exactly N elements. |
| 3 | **`.i` type is pointer-sized** | `.i` is always 4 bytes | 4 bytes on x86, 8 bytes on x64 | Use `.l` for fixed 32-bit, `.q` for fixed 64-bit. Use `.i` for handles, IDs, and loop counters. |
| 4 | **`Next` is a reserved keyword** | Use `Next()` as a procedure name | Compiler error: `Next` closes `For...Next` loops | PureSimple uses `Advance` instead. Plan your names around the reserved word list. |
| 5 | **`Default` is a reserved keyword** | Use `Default` as a parameter name | Compiler error: `Default` is part of `Select...Case...Default` | Use `DefaultVal`, `Fallback`, or any non-reserved name. |
| 6 | **Module bodies cannot see globals** | Access main-code structures inside a `Module` | Compiler error: structure not found | Wrap shared types in a `DeclareModule` (e.g., `Types` module). Use `UseModule Types` in consumers. |
| 7 | **`EnableExplicit` is required** | Variables auto-declare on first use | Typos silently create new variables with zero/empty values | Add `EnableExplicit` to every file. No exceptions. |
| 8 | **`FreeJSON` is a built-in** | Define your own `FreeJSON` procedure in a module | Name collision or shadowing | PureSimple uses `ReleaseJSON` to avoid the conflict. |
| 9 | **Escape strings need `~` prefix** | `"\n"` produces a newline | Produces a literal backslash followed by `n` | Write `~"\n"` for escape sequences. Only `~`-prefixed strings interpret `\n`, `\t`, etc. |
| 10 | **`@Proc()` needs parentheses** | `@MyHandler` gets the address | Compiler error or wrong address | Always write `@MyHandler()` with empty parentheses. |
| 11 | **`@Module::Proc()` in `Global` initialisers** | Take address of a module procedure in a `Global` variable initialiser | Evaluates to 0 because module procedure addresses are not resolved during `Global` initialisation. It works fine in program-level calls (e.g., `Engine::Use(@Logger::Middleware())`). | Wrap in a plain procedure and use its address instead: `Procedure GetAddr() : ProcedureReturn @Module::Proc() : EndProcedure` then `Global handler.i = GetAddr()`. |
| 12 | **Fixed-size struct arrays differ from `Dim`** | `arr.i[32]` in a `Structure` creates 32+1 elements | Creates exactly 32 elements (indices 0 through 31) | Remember: `Dim a(N)` = N+1 elements; `arr.type[N]` in a struct = exactly N elements. The two use opposite conventions. |

---

## A.4 Type Size Quick Reference

| Type | Suffix | Size (bytes) | Range | Typical use |
|---|---|---|---|---|
| Byte | `.b` | 1 | -128 to 127 | Flags, small counters |
| ASCII | `.a` | 1 | 0 to 255 | Unsigned byte values |
| Word | `.w` | 2 | -32768 to 32767 | Small integers |
| Unicode | `.u` | 2 | 0 to 65535 | UTF-16 character |
| Long | `.l` | 4 | -2^31 to 2^31-1 | Fixed 32-bit integer |
| Integer | `.i` | 4 or 8 | Platform-dependent | Handles, IDs, pointers, loop counters |
| Quad | `.q` | 8 | -2^63 to 2^63-1 | Large integers, timestamps |
| Float | `.f` | 4 | ~7 decimal digits | Single-precision float |
| Double | `.d` | 8 | ~15 decimal digits | Double-precision float |
| String | `.s` | Variable | N/A | Text (UTF-16 internally) |

---

## A.5 Operator Reference

| Operator | Purpose | Example |
|---|---|---|
| `+` | Addition / string concatenation | `a + b`, `"hello" + " world"` |
| `-` | Subtraction | `a - b` |
| `*` | Multiplication | `a * b` |
| `/` | Division | `a / b` |
| `%` | Modulo | `a % b` |
| `=` | Assignment / equality test | `a = 5`, `If a = 5` |
| `<>` | Not equal | `If a <> b` |
| `<`, `>`, `<=`, `>=` | Comparison | `If a > b` |
| `And` | Logical/bitwise AND | `If a And b` |
| `Or` | Logical/bitwise OR | `If a Or b` |
| `Not` | Logical/bitwise NOT | `If Not ok` |
| `XOr` | Bitwise XOR | `result = a XOr b` |
| `<<` | Left shift | `val << 2` |
| `>>` | Right shift | `val >> 2` |
| `@` | Address of procedure | `@MyHandler()` |
| `*` | Pointer dereference prefix | `*ctx.RequestContext` |
| `\` | Structure field access | `*ctx\Method` |
| `#` | Constant prefix | `#PB_Any`, `#True` |

---

## A.6 Control Flow Quick Reference

```purebasic
; If / ElseIf / Else
If condition
  ; ...
ElseIf other
  ; ...
Else
  ; ...
EndIf

; Select / Case (switch)
Select value
  Case 1
    ; ...
  Case 2, 3
    ; ...
  Case 4 To 10
    ; ...
  Default
    ; ...
EndSelect

; For / Next
For i = 0 To 10
  ; i goes 0, 1, 2, ..., 10 (inclusive)
Next

; For / Next with Step
For i = 0 To 100 Step 10
  ; i goes 0, 10, 20, ..., 100
Next

; While / Wend
While condition
  ; ...
Wend

; Repeat / Until
Repeat
  ; ...
Until condition

; ForEach (for lists and maps)
ForEach myList()
  ; myList() is current element
Next
ForEach myMap()
  ; MapKey(myMap()) is current key
  ; myMap() is current value
Next
```

---

## A.7 Module Pattern Quick Reference

```purebasic
; Declaring a module (public interface)
DeclareModule MyModule
  ; Public constants
  #Version = 1

  ; Public structure
  Structure Config
    Port.i
    Name.s
  EndStructure

  ; Public procedure declarations
  Declare Init(port.i)
  Declare.s GetName()
EndDeclareModule

; Implementing the module (private body)
Module MyModule
  ; Private module-level variable
  Global g_Port.i
  Global g_Name.s

  Procedure Init(port.i)
    g_Port = port
    g_Name = "MyApp"
  EndProcedure

  Procedure.s GetName()
    ProcedureReturn g_Name
  EndProcedure
EndModule

; Using the module
MyModule::Init(8080)
name.s = MyModule::GetName()

; Or with UseModule
UseModule MyModule
Init(8080)
name.s = GetName()
UnuseModule MyModule
```

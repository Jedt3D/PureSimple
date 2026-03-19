# Appendix D: Compiler Flags Reference

The PureBasic compiler (`pbcompiler`) is invoked from the command line. On macOS, the typical path is:

```
/Applications/PureBasic.app/Contents/Resources/compilers/pbcompiler
```

Set the `PUREBASIC_HOME` environment variable to simplify the command:

```bash
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"
$PUREBASIC_HOME/compilers/pbcompiler <flags> <source.pb>
```

On Linux, PureBasic is typically installed to `/usr/local/purebasic/` or `~/purebasic/`. On Windows, the default is `C:\Program Files\PureBasic\`.

---

## D.1 Essential Flags

These are the flags used throughout this book. Every PureSimple developer should know them.

| Flag | Description | When to use | Example |
|---|---|---|---|
| `-cl` | Console application | **Required** for web servers and test runners. Without it, PureBasic produces a GUI binary that cannot write to stdout. | `pbcompiler main.pb -cl -o app` |
| `-o <name>` | Output binary name | Always. Without it, the binary name is derived from the source file name. | `pbcompiler main.pb -cl -o myapp` |
| `-z` | Enable C optimiser | Production/release builds. Produces faster, smaller binaries but compilation takes longer. | `pbcompiler main.pb -cl -z -o app` |
| `-k` | Syntax check only | During development for fast feedback. No binary is produced. About 10x faster than a full compile. | `pbcompiler main.pb -k` |
| `-t` | Thread-safe mode | When your application uses threads. Required for any concurrent code. | `pbcompiler main.pb -cl -t -o app` |
| `-dl` | Shared library / DLL | When building a shared library (`.so` / `.dylib` / `.dll`). Source must contain `ProcedureDLL` entries. | `pbcompiler plugin.pb -dl -o plugin.so` |

---

## D.2 All Flags Reference

| Flag | Description | Notes |
|---|---|---|---|
| `-cl` | Console application | Enables `OpenConsole()`, `PrintN()`, stdin/stdout. Without this flag, output goes to the GUI debug window instead of the terminal. |
| `-o <path>` | Output file path | Name or full path for the resulting binary. On Linux/macOS, the binary has no extension by default. |
| `-z` | C optimiser | Passes optimisation flags to the underlying C compiler. Increases compile time but produces measurably faster code. |
| `-k` | Syntax check | Parses and type-checks the source without generating a binary. Useful for CI/CD pipelines and editor integrations. |
| `-t` | Thread-safe mode | Links against thread-safe versions of the PureBasic runtime. Required if you call `CreateThread()` anywhere. |
| `-dl` | Shared library | Produces a `.so` (Linux), `.dylib` (macOS), or `.dll` (Windows) instead of an executable. |
| `-e <path>` | Executable path | Alternative to `-o`. Sets the output executable path. |
| `-r <path>` | Resident file | Include a `.res` resident file (pre-compiled constant and structure definitions). |
| `-q` | Quiet mode | Suppresses non-error compiler output. Useful in CI scripts where you only want to see failures. |
| `-v` | Version | Print the compiler version number and exit. |
| `-h` | Help | Print usage information and exit. |
| `-d <name>=<val>` | Define constant | Sets a compiler constant before compilation. Equivalent to `#name = val` in source. |
| `-u` | Unicode mode | Enable Unicode string handling. This is the default in PureBasic 6.x. |
| `-a` | ASCII mode | Force ASCII string handling (legacy). Not recommended for web applications. |
| `-p` | Purifier | Enable the memory purifier. Catches out-of-bounds access and use-after-free at the cost of runtime performance. Development/debugging only. |
| `-x` | Enable OnError | Enable `OnErrorGoto` / `OnErrorResume` support. Required for the Recovery middleware to work. |

---

## D.3 Common Command Combinations

### Development Build

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -o app
```

Fast compile, no optimisation. Good for the edit-compile-test loop.

### Syntax Check

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -k
```

Check for syntax and type errors without producing a binary. The fastest feedback loop.

### Release Build

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -z -o app
```

Full optimisation enabled. Use for production deployments.

### Test Runner

```bash
$PUREBASIC_HOME/compilers/pbcompiler tests/run_all.pb -cl -o run_all
./run_all
```

Compile the test harness as a console application, then run it.

### Thread-Safe Build

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -t -o app
```

Required when PureSimpleHTTPServer uses threads for handling concurrent connections.

### Shared Library

```bash
$PUREBASIC_HOME/compilers/pbcompiler plugin.pb -dl -o plugin.so
```

Build a shared library for use as a plugin or FFI target.

### Debug with Purifier

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -p -o app_debug
./app_debug
```

Catches memory errors at runtime. Slow, but invaluable for tracking down crashes.

### Define a Constant

```bash
$PUREBASIC_HOME/compilers/pbcompiler main.pb -cl -d VERSION='"1.0.0"' -o app
```

The constant `#VERSION` is available in source code as `"1.0.0"`.

---

## D.4 Compiler Constants

PureBasic provides built-in constants that are available at compile time. These are useful for conditional compilation and diagnostic output.

| Constant | Type | Description |
|---|---|---|
| `#PB_Compiler_OS` | Integer | Operating system: `#PB_OS_Windows`, `#PB_OS_Linux`, `#PB_OS_MacOS` |
| `#PB_Compiler_Processor` | Integer | CPU architecture: `#PB_Processor_x86`, `#PB_Processor_x64`, `#PB_Processor_arm64` |
| `#PB_Compiler_Home` | String | PureBasic installation directory |
| `#PB_Compiler_File` | String | Current source file path |
| `#PB_Compiler_Line` | Integer | Current source line number |
| `#PB_Compiler_Procedure` | String | Current procedure name |
| `#PB_Compiler_Module` | String | Current module name |
| `#PB_Compiler_Date` | Integer | Compilation date (Unix timestamp) |
| `#PB_Compiler_Version` | Integer | Compiler version number (e.g., 630 for v6.30) |
| `#PB_Compiler_Unicode` | Boolean | `#True` if compiled in Unicode mode |
| `#PB_Compiler_Thread` | Boolean | `#True` if compiled with `-t` flag |
| `#PB_Compiler_Debugger` | Boolean | `#True` if compiled with debugger enabled |
| `#PB_Compiler_Backend` | Integer | `#PB_Backend_C` for the C backend |

### Cross-Platform Compilation Example

```purebasic
CompilerSelect #PB_Compiler_OS
  CompilerCase #PB_OS_MacOS
    #PathSep = "/"
    #CompilerPath = "/Applications/PureBasic.app/Contents/Resources/compilers/"
  CompilerCase #PB_OS_Linux
    #PathSep = "/"
    #CompilerPath = "/usr/local/purebasic/compilers/"
  CompilerCase #PB_OS_Windows
    #PathSep = "\"
    #CompilerPath = "C:\Program Files\PureBasic\Compilers\"
CompilerEndSelect
```

### Diagnostic Output Example

```purebasic
Procedure LogError(msg.s)
  PrintN("[ERROR] " + msg)
  PrintN("  File: " + #PB_Compiler_File)
  PrintN("  Line: " + Str(#PB_Compiler_Line))
  PrintN("  Proc: " + #PB_Compiler_Procedure)
EndProcedure
```

---

## D.5 Include Directives

These are not compiler flags, but they control what source files are included in the compilation unit. They are used extensively throughout PureSimple.

| Directive | Description |
|---|---|
| `XIncludeFile "path.pbi"` | Include a file. If already included, skip it (prevents duplicate definitions). **Always use this.** |
| `IncludeFile "path.pbi"` | Include a file unconditionally. If included twice, causes duplicate definition errors. |
| `IncludePath "path/"` | Set the base path for subsequent `IncludeFile` / `XIncludeFile` directives. |
| `IncludeBinary "path"` | Embed a binary file (image, data) into the executable. |

### Why XIncludeFile

When module A includes `Types.pbi` and module B also includes `Types.pbi`, using `IncludeFile` in both causes a "structure already declared" error. `XIncludeFile` tracks which files have been included and silently skips duplicates. Every `.pbi` file in PureSimple uses `XIncludeFile`.

---

## D.6 Quick Reference Card

Copy this to a sticky note on your monitor.

```
Development:    pbcompiler main.pb -cl -o app
Syntax check:   pbcompiler main.pb -k
Release:        pbcompiler main.pb -cl -z -o app
Tests:          pbcompiler tests/run_all.pb -cl -o run_all && ./run_all
Thread-safe:    pbcompiler main.pb -cl -t -o app
Debug memory:   pbcompiler main.pb -cl -p -o app_debug
```

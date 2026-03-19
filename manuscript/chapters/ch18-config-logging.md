# Chapter 18: Configuration and Logging

*Twelve-factor config and logs that tell you what happened at 3 AM.*

---

**After reading this chapter you will be able to:**

- Load configuration from `.env` files and retrieve values with type-safe fallbacks
- Override configuration at runtime for testing and development
- Set application run modes (debug, release, test) and understand their effect on behaviour
- Configure levelled logging with output directed to stdout or a file
- Apply twelve-factor app principles to PureSimple applications

---

## 18.1 The Problem with Hard-Coded Values

Every web application needs configuration. Port numbers, database paths, API keys, run modes -- these values change between your laptop, your staging server, and your production machine. You could hard-code them, of course. You could also tattoo your WiFi password on your forehead. Both approaches work right up until you need to change something.

The twelve-factor app methodology, originally codified by Heroku engineers, offers a cleaner answer: store configuration in the environment. Each deployment gets its own `.env` file. The code reads from it. The binary stays the same everywhere. This is the pattern PureSimple follows.

PureSimple's configuration system lives in two modules. `Config` handles key-value storage and `.env` file parsing. `Log` provides levelled logging with configurable output. Together, they give you the operational visibility you need without coupling your code to a specific deployment environment.

## 18.2 The Config Module

The `Config` module is a thin wrapper around a PureBasic `NewMap` -- a hash map from string keys to string values. It reads `.env` files, stores values in memory, and provides typed accessors with fallback defaults. The entire module is under 110 lines. There is no YAML parser. There is no TOML parser. There is no argument about whether tabs or spaces are significant. It reads `KEY=value` lines from a file, and that is all it does.

```purebasic
; Listing 18.1 -- The Config module's public interface
DeclareModule Config
  Declare.i Load(Path.s)
  Declare.s Get(Key.s, Fallback.s = "")
  Declare.i GetInt(Key.s, Fallback.i = 0)
  Declare   Set(Key.s, Val.s)
  Declare.i Has(Key.s)
  Declare   Reset()
EndDeclareModule
```

Six procedures. That is the entire configuration API. `Load` reads a file. `Get` and `GetInt` retrieve values. `Set` overrides a value at runtime. `Has` checks for key existence. `Reset` clears everything. If you have used Go's `os.Getenv` with a helper function for defaults, you already know this pattern. If you have used Python's `python-dotenv`, same idea -- except this one compiles to machine code and has no transitive dependencies.

### Loading a .env File

The `.env` file format is deliberately simple:

```
# .env -- application configuration
# Lines starting with # are comments
PORT=8080
MODE=release
DB_PATH=data/production.db
APP_NAME=PureSimple
EMPTY_VAL=
MAX_CONN=25
```

Blank lines and comment lines (starting with `#`) are skipped. Every other line is split on the first `=` sign. The key is trimmed, the value is trimmed, and the pair is stored in the map. Keys are case-sensitive. Values are always strings internally -- `GetInt` converts them with `Val()` at retrieval time.

```purebasic
; Listing 18.2 -- Loading configuration and reading values
Config::Load(".env")

; String value with fallback
Protected mode.s = Config::Get("MODE", "debug")

; Integer value with fallback
Protected port.i = Config::GetInt("PORT", 8080)

; Check if a key exists before reading
If Config::Has("DB_PATH")
  Protected dbPath.s = Config::Get("DB_PATH")
EndIf
```

The `Load` procedure returns `#True` on success and `#False` if the file cannot be opened. This is a deliberate design choice. A missing `.env` file is not necessarily an error -- your application might rely entirely on compiled defaults during development. The caller decides whether a missing file is fatal.

> **Tip:** Never commit your `.env` file to version control. Add `.env` to your `.gitignore` and provide a `.env.example` file with placeholder values instead. Your production secrets belong on your production server, not in your Git history.

### How Load Works Internally

The implementation uses PureBasic's file I/O primitives: `ReadFile`, `ReadString`, and `Eof`. It checks for file existence using `FileSize(Path) < 0` -- the canonical PureBasic idiom, since there is no `FileExists()` function. I once spent fifteen minutes looking for `FileExists()` in the documentation before discovering it does not exist. The function, I mean. The file was fine.

```purebasic
; Listing 18.3 -- From src/Config.pbi: the Load procedure
Procedure.i Load(Path.s)
  Protected fh.i, line.s, eq.i, key.s, val.s
  If FileSize(Path) < 0
    ProcedureReturn #False
  EndIf
  fh = ReadFile(#PB_Any, Path)
  If fh = 0
    ProcedureReturn #False
  EndIf
  While Not Eof(fh)
    line = Trim(ReadString(fh))
    If Len(line) = 0 Or Left(line, 1) = "#"
      Continue
    EndIf
    eq = FindString(line, "=")
    If eq > 0
      key = Trim(Left(line, eq - 1))
      val = Trim(Mid(line, eq + 1))
      If key <> ""
        _C(key) = val
      EndIf
    EndIf
  Wend
  CloseFile(fh)
  ProcedureReturn #True
EndProcedure
```

Notice the split logic: `FindString(line, "=")` returns the position of the first `=` sign. Everything before it is the key, everything after it is the value. This means values can contain `=` signs without ambiguity -- `SECRET=abc=def` stores `"abc=def"` under the key `"SECRET"`. Keys cannot contain `=` signs, but if you are putting equals signs in your key names, configuration is not your most pressing problem.

> **PureBasic Gotcha:** `FindString` returns 0 when the substring is not found, not -1. PureBasic strings are 1-indexed, so position 0 means "not found." Lines without an `=` sign are silently skipped.

### Runtime Overrides and Reset

`Config::Set` writes directly to the internal map, overwriting any existing value for that key. This is useful during testing, where you need to simulate different configurations without writing temporary files to disk.

`Config::Reset` clears the entire map. Between test suites, you should call `Config::Reset()` to ensure one suite's configuration does not bleed into the next. Shared mutable state is the number one source of flaky tests, and configuration is shared mutable state with a business card and a corner office.

```purebasic
; Listing 18.4 -- Runtime overrides in test code
Config::Reset()
Config::Set("PORT", "3000")
Config::Set("MODE", "test")
CheckEqual(Config::GetInt("PORT"), 3000)
CheckStr(Config::Get("MODE"), "test")
Config::Reset()   ; clean slate for the next suite
```

> **Compare:** Go developers typically use `os.Setenv` and `os.Getenv`, or a library like Viper that supports YAML, TOML, JSON, environment variables, and remote config servers. PureSimple's `Config` module is closer to `godotenv` -- it does one thing (read `.env` files) and does it well. If you need hierarchical config with inheritance and hot-reloading, you are building a different kind of application than PureSimple targets.

## 18.3 Run Modes

PureSimple supports three run modes: `"debug"`, `"release"`, and `"test"`. The default is `"debug"`. You set the mode with `Engine::SetMode` and read it with `Engine::Mode`.

```purebasic
; Listing 18.5 -- Setting and reading the run mode
Engine::SetMode("release")
CheckStr(Engine::Mode(), "release")

Engine::SetMode("test")
CheckStr(Engine::Mode(), "test")

Engine::SetMode("debug")  ; restore default
```

The mode is stored as a simple global string inside the Engine module. It does not automatically change behaviour -- it is a flag that your middleware and handlers can check. The Logger middleware, for example, might suppress debug-level output in release mode. The Recovery middleware might show stack traces in debug mode but return a generic error page in release mode.

The systemd service file sets the mode via an environment variable:

```ini
; Listing 18.6 -- From deploy/puresimple.service
Environment=PURESIMPLE_MODE=release
```

Your application startup code reads this and applies it:

```purebasic
; Listing 18.7 -- Applying mode from config
Config::Load(".env")
Engine::SetMode(Config::Get("PURESIMPLE_MODE", "debug"))
```

> **Tip:** Keep mode handling simple. Three modes are enough. "debug" for development, "release" for production, "test" for automated tests. If you find yourself adding modes like "staging-with-extra-logging-on-tuesdays", step back and use log levels instead.

## 18.4 The Log Module

Logging is the art of writing messages that you will desperately wish you had written more of, three months from now, at 3 AM, when production is down and you have no idea why. The `Log` module provides four severity levels and two output targets.

```purebasic
; Listing 18.8 -- The Log module's public interface
DeclareModule Log
  #LevelDebug = 0
  #LevelInfo  = 1
  #LevelWarn  = 2
  #LevelError = 3

  Declare   SetLevel(Level.i)
  Declare   SetOutput(Filename.s)
  Declare   Dbg(Msg.s)
  Declare   Info(Msg.s)
  Declare   Warn(Msg.s)
  Declare   Error(Msg.s)
EndDeclareModule
```

The four levels form a hierarchy. Setting the level to `#LevelWarn` suppresses both `Dbg` and `Info` messages. Setting it to `#LevelDebug` shows everything. The default level is `#LevelInfo`, which means debug messages are suppressed unless you explicitly lower the threshold.

### Log Output Format

Every log line follows the same format:

```
[2026-03-20 14:32:01] [INFO] Server starting on :8080
[2026-03-20 14:32:01] [DEBUG] Loaded 10 migrations
[2026-03-20 14:32:05] [WARN] Slow query: 1.2s on /api/posts
[2026-03-20 14:32:07] [ERROR] Database connection failed
```

The timestamp comes from `FormatDate` applied to `Date()`. The level tag is a fixed-width string. The message is whatever you pass in. This format is easy to read, easy to grep, and easy to pipe into any log aggregation tool that understands plain text -- which is all of them.

```purebasic
; Listing 18.9 -- Using log levels in application code
Log::SetLevel(Log::#LevelDebug)
Log::Dbg("Loading configuration from .env")
Log::Info("Server starting on port " + Str(port))
Log::Warn("No DB_PATH configured, using in-memory")
Log::Error("Failed to bind to port " + Str(port))
```

### File Output

By default, `Log` writes to stdout using `PrintN`. To redirect output to a file, call `SetOutput` with a file path. Pass an empty string to switch back to stdout.

```purebasic
; Listing 18.10 -- Directing log output to a file
Log::SetOutput("logs/app.log")
Log::Info("This goes to the file")
Log::SetOutput("")
Log::Info("This goes to stdout")
```

The file output implementation appends to an existing file (using `OpenFile` and `FileSeek` to the end) or creates a new one if the file does not exist yet. Each log call opens the file, writes one line, and closes it. This is not the fastest approach -- a buffered writer would be more efficient -- but it guarantees that every log line is flushed to disk immediately. When your server crashes, you want the last log line to be on disk, not sitting in a buffer somewhere, contemplating the meaning of existence.

> **Under the Hood:** The `_Write` helper procedure checks `FileSize(_Output) >= 0` to decide between `OpenFile` (append) and `CreateFile` (new file). This is the same `FileSize` pattern used throughout PureBasic for file existence checks. The file handle is obtained with `#PB_Any` to avoid ID conflicts.

### What to Log at Each Level

Choosing the right log level is more art than science, but here are practical guidelines:

| Level | Use for | Examples |
|-------|---------|----------|
| **DEBUG** | Verbose detail for development | "Loaded 10 routes", "Config key DB_PATH = data/app.db" |
| **INFO** | Normal operations worth recording | "Server started on :8080", "Migration 003 applied" |
| **WARN** | Something unexpected but not fatal | "Slow query (1.2s)", "Missing optional config key" |
| **ERROR** | Something broke and needs attention | "Database connection failed", "Template not found" |

In production, set the level to `#LevelInfo` or `#LevelWarn`. In development, set it to `#LevelDebug`. In tests, set it to `#LevelError` to keep test output clean -- or redirect to a temporary file and assert on its contents, as the P8 test suite does.

> **Warning:** Do not log sensitive data. Passwords, API keys, session tokens, and credit card numbers have no business appearing in log files. If you need to log a request body for debugging, redact sensitive fields first.

## 18.5 Putting Config and Log Together

In a typical PureSimple application, configuration and logging are the first things you set up. They run before routes are registered, before middleware is attached, and before the server starts listening.

```purebasic
; Listing 18.11 -- Typical application startup sequence
EnableExplicit
XIncludeFile "src/PureSimple.pb"

; 1. Load configuration
If Not Config::Load(".env")
  Log::Warn("No .env file found, using defaults")
EndIf

; 2. Set run mode
Engine::SetMode(Config::Get("MODE", "debug"))

; 3. Configure logging
If Engine::Mode() = "release"
  Log::SetLevel(Log::#LevelInfo)
  Log::SetOutput(Config::Get("LOG_FILE", "logs/app.log"))
Else
  Log::SetLevel(Log::#LevelDebug)
EndIf

; 4. Read application-specific config
Protected port.i = Config::GetInt("PORT", 8080)
Protected dbPath.s = Config::Get("DB_PATH", "data/app.db")

Log::Info("Starting in " + Engine::Mode() + " mode")
Log::Info("Port: " + Str(port))
Log::Info("Database: " + dbPath)

; 5. Register routes, middleware, etc.
; ... (rest of application setup)
```

This pattern follows the twelve-factor principle: the binary is the same everywhere; only the `.env` file changes between environments. Your development `.env` has `MODE=debug` and `PORT=3000`. Your production `.env` has `MODE=release` and `PORT=8080`. The binary does not care. It reads what it is given and behaves accordingly.

## 18.6 Testing Configuration

The P8 test suite demonstrates a thorough approach to testing the Config module. It loads a known `.env` file, verifies parsed values, tests fallback defaults, exercises runtime overrides, and confirms that `Reset` actually clears the store.

```purebasic
; Listing 18.12 -- From tests/P8_Config_Test.pbi: key assertions
Config::Reset()
result = Config::Load("tests/test.env")
Check(result)   ; file loaded successfully

; Verify known keys
CheckStr(Config::Get("PORT"),     "9090")
CheckStr(Config::Get("MODE"),     "release")
CheckStr(Config::Get("APP_NAME"), "PureSimple")

; Empty values are stored, not skipped
Check(Config::Has("EMPTY_VAL"))
CheckStr(Config::Get("EMPTY_VAL"), "")

; Comments must not appear as keys
Check(Not Config::Has(
  "# This line is a comment and should be ignored"))

; Fallback defaults
CheckStr(Config::Get("NONEXISTENT_KEY", "fallback"),
  "fallback")
CheckEqual(Config::GetInt("MISSING_INT", 42), 42)
```

The test also verifies that `Config::Load` returns `#False` for a nonexistent file, that `GetInt` correctly converts string values to integers, and that `Config::Set` can override loaded values at runtime. For the `Log` module, the test redirects output to a temporary file, writes messages at all four levels, and verifies the file was created with content.

> **Tip:** Always call `Config::Reset()` at the start of your config tests. Other test suites that ran before yours may have left values in the store. Defensive testing is not paranoia -- it is professionalism.

---

## Summary

Configuration and logging are the operational backbone of any web application. PureSimple's `Config` module provides a lightweight `.env` file parser with typed accessors and runtime overrides. The `Log` module offers four severity levels with output to stdout or file. Together with `Engine::SetMode`, they give you environment-specific behaviour without recompiling your binary. The pattern is simple: load config first, set the mode, configure logging, then start the application.

## Key Takeaways

- **Load once, read everywhere.** Call `Config::Load` at startup; use `Config::Get` and `Config::GetInt` with fallback defaults throughout your application.
- **Never commit `.env` files.** Use `.env.example` with placeholder values and keep real secrets on the server.
- **Log at the right level.** DEBUG for development verbosity, INFO for normal operations, WARN for recoverable problems, ERROR for things that need immediate attention.
- **Reset between tests.** Call `Config::Reset()` and restore `Log::SetLevel` / `Log::SetOutput` to defaults between test suites to prevent state leakage.

## Review Questions

1. Why does `Config::Load` return `#False` instead of raising an error when the `.env` file is missing? What are the advantages of this design?
2. What is the difference between `Log::#LevelInfo` and `Log::#LevelWarn`, and when would you choose one over the other as your production log level?
3. *Try it:* Create a `.env` file with `PORT`, `MODE`, and `LOG_FILE` keys. Write a short program that loads the config, sets the run mode, redirects log output to the configured file, and logs a startup message at each severity level. Verify that only messages at or above the configured level appear in the file.

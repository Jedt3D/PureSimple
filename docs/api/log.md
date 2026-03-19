# Log

`src/Log.pbi` — Leveled logger with optional file output.

## Log Levels

| Constant | Value | When to use |
|----------|-------|-------------|
| `Log::#LevelDebug` | 0 | Verbose development output |
| `Log::#LevelInfo`  | 1 | Normal operational messages (default) |
| `Log::#LevelWarn`  | 2 | Recoverable problems |
| `Log::#LevelError` | 3 | Failures that need attention |

## Configuration

```purebasic
Log::SetLevel(Log::#LevelWarn)        ; suppress Debug and Info messages
Log::SetOutput("logs/app.log")        ; write to file (appends; creates if absent)
Log::SetOutput("")                    ; write to stdout (default)
```

## Writing Messages

```purebasic
Log::Dbg("query took 5ms")            ; [DEBUG] — suppressed at Info level+
Log::Info("Server starting on :8080") ; [INFO]
Log::Warn("Rate limit approaching")   ; [WARN]
Log::Error("Database connection lost") ; [ERROR]
```

> **Note**: The debug procedure is named `Log::Dbg` (not `Log::Debug`) because
> `Debug` is a reserved PureBasic keyword.

## Output Format

```
[2026-03-20 14:32:01] [INFO]  Server starting on :8080
[2026-03-20 14:32:05] [WARN]  Rate limit approaching
[2026-03-20 14:32:09] [ERROR] Database connection lost
```

## File Output

When `SetOutput` is given a non-empty path:
- If the file exists, messages are **appended** (seek to `Lof`)
- If the file does not exist, it is **created**
- The file is opened and closed on each write (safe for single-threaded use)

## Common Pattern

```purebasic
; In your app bootstrap:
Config::Load(".env")
If Config::Get("MODE") = "release"
  Log::SetLevel(Log::#LevelInfo)
  Log::SetOutput("logs/app.log")
Else
  Log::SetLevel(Log::#LevelDebug)
  ; stdout is fine in debug mode
EndIf
```

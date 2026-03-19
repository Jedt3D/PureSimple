# Config

`src/Config.pbi` — `.env` file loader and runtime key/value configuration store.

## Loading a .env File

```purebasic
ok = Config::Load(".env")        ; #True on success, #False if file not found
```

`.env` format:
```
# Lines starting with # are comments — ignored
PORT=8080
MODE=release
APP_NAME=MyApp
DB_PATH=data/app.db
EMPTY_VALUE=
```

Rules:
- Lines are split on the **first** `=`; leading/trailing whitespace is trimmed
- Comment lines (`#`) and blank lines are skipped
- Keys are **case-sensitive**
- Re-loading overwrites existing keys

## Reading Values

```purebasic
val  = Config::Get("PORT")               ; "" if not set
val  = Config::Get("PORT", "8080")       ; fallback if not set
ival = Config::GetInt("PORT", 8080)      ; Val() conversion; fallback if not set
```

> **Note**: `GetInt` returns 0 for non-numeric strings. Use `Config::Has` if
> you need to distinguish "missing" from "value is zero".

## Writing Values

```purebasic
Config::Set("KEY", "value")     ; set or overwrite at runtime
Config::Has("KEY")              ; returns #True if key is present
```

## Resetting

```purebasic
Config::Reset()                 ; clear all values (used between tests)
```

## Common Pattern

```purebasic
If Not Config::Load(".env")
  Log::Warn("No .env file — using built-in defaults")
EndIf

Protected port.i = Config::GetInt("PORT", 8080)
Protected mode.s = Config::Get("MODE", "debug")
Protected db.s   = Config::Get("DB_PATH", "data/app.db")
```

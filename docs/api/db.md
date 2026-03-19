# DB (SQLite)

`src/DB/SQLite.pbi` — SQLite adapter and migration runner.

Requires PureBasic's built-in SQLite support (enabled via `UseSQLiteDatabase()`
inside the module).

## Opening and Closing

```purebasic
handle = DB::Open("app.db")       ; open or create file
handle = DB::Open(":memory:")     ; in-memory database (no persistence)
DB::Close(handle)
```

Returns 0 on failure. Always check before using.

## Executing SQL

```purebasic
; Non-SELECT (INSERT, UPDATE, DELETE, CREATE, DROP, …)
ok = DB::Exec(handle, "CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)")
ok = DB::Exec(handle, "INSERT INTO users VALUES (1, 'Alice')")

; Error after failure
If Not ok
  PrintN("DB error: " + DB::Error())
EndIf
```

## Querying

```purebasic
ok = DB::Query(handle, "SELECT id, name FROM users WHERE active = 1")
While DB::NextRow(handle)             ; iterate result set
  id   = DB::GetInt(handle, 0)        ; 0-based column index
  name = DB::GetStr(handle, 1)
  score = DB::GetFloat(handle, 2)
Wend
DB::Done(handle)                       ; free result set
```

`DB::NextRow` is named to avoid the reserved keyword `Next`.

## Parameter Binding

```purebasic
DB::BindStr(handle, 0, "Alice")        ; bind first ? placeholder (0-based)
DB::BindInt(handle, 1, 42)
DB::Query(handle, "SELECT * FROM users WHERE name = ? AND age > ?")
```

Binding must occur before the `Exec`/`Query` call that uses the placeholders.

## Column Accessors

```purebasic
DB::GetStr(handle, col)     ; returns "" if NULL
DB::GetInt(handle, col)     ; returns 0 if NULL
DB::GetFloat(handle, col)   ; returns 0.0 if NULL
```

All column indices are **0-based**.

## Error

```purebasic
msg = DB::Error()
```

Returns the last PureBasic database error string. `DatabaseError()` takes no
parameters — this is a PureBasic quirk (unlike most database APIs).

## Migrations

```purebasic
DB::AddMigration(1, "CREATE TABLE users (id INTEGER PRIMARY KEY, email TEXT)")
DB::AddMigration(2, "ALTER TABLE users ADD COLUMN name TEXT")
DB::AddMigration(3, "CREATE INDEX idx_users_email ON users (email)")

DB::Migrate(handle)     ; apply all pending migrations; idempotent

DB::ResetMigrations()   ; clear registered migrations (for tests)
```

`DB::Migrate` creates a `puresimple_migrations` tracking table on first run,
then applies each registered migration whose version number is not already
recorded. Running `Migrate` twice is safe — already-applied versions are
skipped.

Migrations run in **registration order** (not version-number order), so
register them in sequence in your application's initialisation code.

; P6_SQLite_Test.pbi — Tests for the DB::SQLite module

Global P6_db.i
Global P6_db2.i

; =================================================================
; Suite: DB::Open — in-memory database
; =================================================================
BeginSuite("P6 / DB — Open in-memory")

P6_db = DB::Open(":memory:")

CheckEqual(Bool(P6_db <> 0), 1)   ; handle is valid

; =================================================================
; Suite: DB::Exec — DDL and DML
; =================================================================
BeginSuite("P6 / DB — Exec DDL + DML")

CheckEqual(DB::Exec(P6_db, "CREATE TABLE t (id INTEGER, name TEXT)"), 1)
CheckEqual(DB::Exec(P6_db, "INSERT INTO t VALUES (1, 'Alice')"),       1)
CheckEqual(DB::Exec(P6_db, "INSERT INTO t VALUES (2, 'Bob')"),         1)
CheckEqual(DB::Exec(P6_db, "INSERT INTO t VALUES (3, 'Carol')"),       1)

; =================================================================
; Suite: DB::Query + NextRow + GetInt + GetStr
; =================================================================
BeginSuite("P6 / DB — Query rows")

CheckEqual(DB::Query(P6_db, "SELECT id, name FROM t ORDER BY id"), 1)

CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0),   1)
CheckStr(DB::GetStr(P6_db, 1),   "Alice")

CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0),   2)
CheckStr(DB::GetStr(P6_db, 1),   "Bob")

CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0),   3)
CheckStr(DB::GetStr(P6_db, 1),   "Carol")

CheckEqual(DB::NextRow(P6_db), 0)   ; no more rows
DB::Done(P6_db)

; =================================================================
; Suite: DB::GetFloat
; =================================================================
BeginSuite("P6 / DB — GetFloat")

CheckEqual(DB::Exec(P6_db, "CREATE TABLE prices (item TEXT, price REAL)"), 1)
CheckEqual(DB::Exec(P6_db, "INSERT INTO prices VALUES ('apple', 1.5)"),    1)

CheckEqual(DB::Query(P6_db, "SELECT price FROM prices"), 1)
CheckEqual(DB::NextRow(P6_db), 1)
; Compare as integer (1.5 * 2 = 3) to avoid floating-point equality issues
CheckEqual(Int(DB::GetFloat(P6_db, 0) * 2), 3)
DB::Done(P6_db)

; =================================================================
; Suite: DB::BindStr — parameterized string query
; =================================================================
BeginSuite("P6 / DB — BindStr parameterized query")

DB::BindStr(P6_db, 0, "Bob")
CheckEqual(DB::Query(P6_db, "SELECT id FROM t WHERE name = ?"), 1)
CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0), 2)
CheckEqual(DB::NextRow(P6_db), 0)
DB::Done(P6_db)

; =================================================================
; Suite: DB::BindInt — parameterized integer query
; =================================================================
BeginSuite("P6 / DB — BindInt parameterized query")

DB::BindInt(P6_db, 0, 3)
CheckEqual(DB::Query(P6_db, "SELECT name FROM t WHERE id = ?"), 1)
CheckEqual(DB::NextRow(P6_db), 1)
CheckStr(DB::GetStr(P6_db, 0), "Carol")
DB::Done(P6_db)

; =================================================================
; Suite: DB::Exec — invalid SQL returns #False + Error non-empty
; =================================================================
BeginSuite("P6 / DB — Exec error handling")

P6_db2 = DB::Open(":memory:")
CheckEqual(DB::Exec(P6_db2, "THIS IS NOT SQL"), 0)
CheckEqual(Bool(Len(DB::Error(P6_db2)) > 0), 1)
DB::Close(P6_db2)

; =================================================================
; Suite: DB::AddMigration + DB::Migrate — runs pending migrations
; =================================================================
BeginSuite("P6 / DB — Migrate runs pending migrations")

DB::ResetMigrations()
DB::AddMigration(1, "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, email TEXT)")
DB::AddMigration(2, "CREATE TABLE IF NOT EXISTS posts (id INTEGER PRIMARY KEY, title TEXT)")

CheckEqual(DB::Migrate(P6_db), 1)   ; migrations ran successfully

; Both tables should exist
CheckEqual(DB::Exec(P6_db, "INSERT INTO users VALUES (1, 'a@b.com')"),   1)
CheckEqual(DB::Exec(P6_db, "INSERT INTO posts VALUES (1, 'Hello')"),      1)

; puresimple_migrations should record 2 rows
CheckEqual(DB::Query(P6_db, "SELECT COUNT(*) FROM puresimple_migrations"), 1)
CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0), 2)
DB::Done(P6_db)

; =================================================================
; Suite: DB::Migrate — idempotent (no re-run on second call)
; =================================================================
BeginSuite("P6 / DB — Migrate is idempotent")

CheckEqual(DB::Migrate(P6_db), 1)   ; second call — all migrations already applied

; Row count must still be 2 (not 4)
CheckEqual(DB::Query(P6_db, "SELECT COUNT(*) FROM puresimple_migrations"), 1)
CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0), 2)
DB::Done(P6_db)

; =================================================================
; Suite: DB::Migrate — incremental (new migration added later)
; =================================================================
BeginSuite("P6 / DB — Migrate incremental")

DB::AddMigration(3, "ALTER TABLE users ADD COLUMN name TEXT")

CheckEqual(DB::Migrate(P6_db), 1)

; Now 3 rows in migrations table
CheckEqual(DB::Query(P6_db, "SELECT COUNT(*) FROM puresimple_migrations"), 1)
CheckEqual(DB::NextRow(P6_db), 1)
CheckEqual(DB::GetInt(P6_db, 0), 3)
DB::Done(P6_db)

; New column should be usable
CheckEqual(DB::Exec(P6_db, "UPDATE users SET name = 'Alice' WHERE id = 1"), 1)

; =================================================================
; Suite: DB::Close
; =================================================================
BeginSuite("P6 / DB — Close")

DB::Close(P6_db)   ; must not crash
Check(#True)       ; if we reach here, Close succeeded

DB::ResetMigrations()

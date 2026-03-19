; DB/SQLite.pbi — SQLite database adapter + migration runner
;
; Thin wrapper around PureBasic's built-in SQLite functions.
; All handles are #PB_Any IDs returned by OpenDatabase().
;
; Usage:
;   db = DB::Open(":memory:")          ; or a file path
;   DB::Exec(db, "CREATE TABLE ...")
;   DB::BindStr(db, 0, "Alice")
;   DB::Query(db, "SELECT * FROM t WHERE name = ?")
;   While DB::NextRow(db)
;     name$ = DB::GetStr(db, 0)
;   Wend
;   DB::Done(db)
;   DB::Close(db)
;
; Migration runner:
;   DB::AddMigration(1, "CREATE TABLE users (...)")
;   DB::AddMigration(2, "ALTER TABLE users ADD COLUMN bio TEXT")
;   DB::Migrate(db)   ; creates puresimple_migrations, runs pending migrations

EnableExplicit

UseSQLiteDatabase()

DeclareModule DB
  Declare.i Open(Path.s)
  Declare   Close(Handle.i)
  Declare.i Exec(Handle.i, SQL.s)
  Declare.i Query(Handle.i, SQL.s)
  Declare.i NextRow(Handle.i)
  Declare   Done(Handle.i)
  Declare.s GetStr(Handle.i, Col.i)
  Declare.i GetInt(Handle.i, Col.i)
  Declare.d GetFloat(Handle.i, Col.i)
  Declare   BindStr(Handle.i, Idx.i, Val.s)
  Declare   BindInt(Handle.i, Idx.i, Val.i)
  Declare.s Error(Handle.i)
  Declare   AddMigration(Version.i, SQL.s)
  Declare.i Migrate(Handle.i)
  Declare   ResetMigrations()
EndDeclareModule

Module DB
  UseModule Types

  #_MAX_MIG = 64
  Global Dim _MigVer.i(#_MAX_MIG)
  Global Dim _MigSQL.s(#_MAX_MIG)
  Global _MigCount.i = 0

  ; ------------------------------------------------------------------
  ; Open / Close
  ; ------------------------------------------------------------------

  ; Open a SQLite database at Path (use ":memory:" for in-memory).
  ; Returns a database handle (> 0) on success, 0 on failure.
  Procedure.i Open(Path.s)
    ProcedureReturn OpenDatabase(#PB_Any, Path, "", "")
  EndProcedure

  ; Close a database handle.
  Procedure Close(Handle.i)
    CloseDatabase(Handle)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Non-query execution (INSERT, UPDATE, DELETE, CREATE, ...)
  ; ------------------------------------------------------------------

  ; Execute a non-SELECT SQL statement.
  ; Returns #True on success, #False on error.
  Procedure.i Exec(Handle.i, SQL.s)
    ProcedureReturn DatabaseUpdate(Handle, SQL)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Query execution (SELECT)
  ; ------------------------------------------------------------------

  ; Execute a SELECT statement. Returns #True if rows are available.
  ; Call NextRow() to iterate; call Done() when finished.
  Procedure.i Query(Handle.i, SQL.s)
    ProcedureReturn DatabaseQuery(Handle, SQL)
  EndProcedure

  ; Advance to the next row. Returns #True if a row is available.
  Procedure.i NextRow(Handle.i)
    ProcedureReturn NextDatabaseRow(Handle)
  EndProcedure

  ; Finish and free the current query result set.
  Procedure Done(Handle.i)
    FinishDatabaseQuery(Handle)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Column accessors (0-based column index)
  ; ------------------------------------------------------------------

  Procedure.s GetStr(Handle.i, Col.i)
    ProcedureReturn GetDatabaseString(Handle, Col)
  EndProcedure

  Procedure.i GetInt(Handle.i, Col.i)
    ProcedureReturn GetDatabaseLong(Handle, Col)
  EndProcedure

  Procedure.d GetFloat(Handle.i, Col.i)
    ProcedureReturn GetDatabaseDouble(Handle, Col)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Parameter binding (0-based parameter index, called before Exec/Query)
  ; ------------------------------------------------------------------

  Procedure BindStr(Handle.i, Idx.i, Val.s)
    SetDatabaseString(Handle, Idx, Val)
  EndProcedure

  Procedure BindInt(Handle.i, Idx.i, Val.i)
    SetDatabaseLong(Handle, Idx, Val)
  EndProcedure

  ; ------------------------------------------------------------------
  ; Error reporting
  ; ------------------------------------------------------------------

  ; Returns the last database error message (empty string if no error).
  Procedure.s Error(Handle.i)
    ProcedureReturn DatabaseError()
  EndProcedure

  ; ------------------------------------------------------------------
  ; Migration runner
  ; ------------------------------------------------------------------

  ; Register a migration. Migrations are run in registration order.
  ; Version must be a positive integer unique per migration.
  Procedure AddMigration(Version.i, SQL.s)
    If _MigCount < #_MAX_MIG
      _MigVer(_MigCount) = Version
      _MigSQL(_MigCount) = SQL
      _MigCount + 1
    EndIf
  EndProcedure

  ; Run all pending migrations against Handle.
  ; Creates the puresimple_migrations tracking table if needed.
  ; Already-applied migrations (by version number) are skipped.
  ; Returns #True on success, #False if any migration fails.
  Procedure.i Migrate(Handle.i)
    Protected i.i, ver.i, applied.i

    ; Ensure the tracking table exists
    If Not DatabaseUpdate(Handle, "CREATE TABLE IF NOT EXISTS " +
                                  "puresimple_migrations " +
                                  "(version INTEGER PRIMARY KEY, applied_at TEXT)")
      ProcedureReturn #False
    EndIf

    For i = 0 To _MigCount - 1
      ver = _MigVer(i)

      ; Check if already applied
      applied = 0
      SetDatabaseLong(Handle, 0, ver)
      If DatabaseQuery(Handle, "SELECT COUNT(*) FROM puresimple_migrations WHERE version = ?")
        If NextDatabaseRow(Handle)
          applied = GetDatabaseLong(Handle, 0)
        EndIf
        FinishDatabaseQuery(Handle)
      EndIf

      If applied > 0
        Continue   ; already applied — skip
      EndIf

      ; Apply the migration SQL
      If Not DatabaseUpdate(Handle, _MigSQL(i))
        ProcedureReturn #False
      EndIf

      ; Record the applied version
      SetDatabaseLong(Handle, 0, ver)
      SetDatabaseString(Handle, 1, "2026-03-19")
      If Not DatabaseUpdate(Handle, "INSERT INTO puresimple_migrations " +
                                    "(version, applied_at) VALUES (?, ?)")
        ProcedureReturn #False
      EndIf
    Next i

    ProcedureReturn #True
  EndProcedure

  ; Clear all registered migrations (used between tests).
  Procedure ResetMigrations()
    _MigCount = 0
  EndProcedure

EndModule

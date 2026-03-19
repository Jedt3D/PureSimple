# Chapter 23: Multi-Database Support

![Chapter 23 opening illustration](../../illustrations/ch23-cover.svg)

*One interface, three drivers, zero code changes.*

---

**After reading this chapter you will be able to:**

- Explain how DSN-based connection factories abstract over multiple database drivers
- Use `DBConnect::Open` to connect to SQLite, PostgreSQL, and MySQL from a single code path
- Parse URL-style DSN strings into PureBasic's key-value connection format
- Swap databases via a `.env` file without changing any application code

---

## 23.1 Why Abstract?

For twenty-two chapters, every database example in this book has used SQLite. SQLite is excellent: it compiles into the binary, requires no server process, stores everything in a single file, and performs well enough for most applications. The Wild & Still blog (Chapter 22) runs on SQLite in production. It handles its traffic without strain.

But there are use cases where SQLite is not the right choice. You need concurrent writes from multiple processes. You need full-text search with language-aware stemming. You need a database that lives on a separate server from the application. You need to integrate with an existing PostgreSQL or MySQL deployment. These are legitimate requirements, and they should not require rewriting every `DB::Exec` and `DB::Query` call in your application.

The `DBConnect` module solves this problem. It sits between your application code and PureBasic's database API, providing a single `Open` procedure that accepts a DSN (Data Source Name) string and returns a database handle. The handle works with every `DB::*` procedure you already know. No new query API. No new result-set API. Just a different way to open the connection.

The joke about database abstraction layers is that they always promise "swap your database with one config change" and never deliver because your queries use database-specific features. The joke is fair. If your queries use SQLite's `INSERT OR IGNORE` syntax, switching to PostgreSQL means rewriting them as `INSERT ... ON CONFLICT DO NOTHING`. The `DBConnect` module does not hide this. It abstracts the *connection*, not the *dialect*. This is an honest abstraction: it solves the problem it claims to solve and does not pretend to solve the one it cannot.

> **Compare:** In Go, the `database/sql` package provides the same pattern: a `sql.Open(driver, dsn)` function that returns a `*sql.DB` handle. The driver is registered separately (e.g., `_ "github.com/lib/pq"` for PostgreSQL). PureBasic's `OpenDatabase()` takes a plugin constant (`#PB_Database_SQLite`, `#PB_Database_PostgreSQL`, `#PB_Database_MySQL`) instead. `DBConnect::Open` maps from a DSN prefix to the correct constant.

---

## 23.2 The DSN Format

A DSN string encodes everything the database driver needs to connect: the driver type, the host, the port, the credentials, and the database name. The `DBConnect` module supports three DSN formats:

```
sqlite::memory:                         SQLite in-memory
sqlite:path/to/db.sqlite                SQLite file-based
postgres://user:pass@host:5432/dbname   PostgreSQL
postgresql://user:pass@host:5432/db     PostgreSQL (alias)
mysql://user:pass@host:3306/dbname      MySQL / MariaDB
```

The format follows URL conventions. The scheme (everything before the first colon) identifies the driver. For SQLite, the remainder is the file path or `:memory:`. For PostgreSQL and MySQL, the remainder is a standard URL with userinfo, host, port, and path.

This is not a PureSimple invention. PostgreSQL's `libpq` uses connection URIs in the same format. MySQL's `mysqlclient` accepts similar strings. SQLite does not natively use DSN strings, but the `sqlite:` prefix is a common convention in multi-database tools. Adopting a universal format means you can copy a DSN from your PostgreSQL documentation and paste it into your `.env` file.

---

## 23.3 Driver Detection

The first step in opening a connection is figuring out which driver to use. The `DBConnect::Driver` procedure extracts the scheme from the DSN and maps it to a constant:

```purebasic
; Listing 23.1 -- From src/DB/Connect.pbi: Driver detection
DeclareModule DBConnect
  #Driver_Unknown  = -1
  #Driver_SQLite   =  0
  #Driver_Postgres =  1
  #Driver_MySQL    =  2

  Declare.i Driver(DSN.s)
  Declare.i Open(DSN.s)
  Declare.i OpenFromConfig()
  Declare.s ConnStr(DSN.s)
EndDeclareModule

Module DBConnect
  UseModule Types

  Procedure.s _Scheme(DSN.s)
    Protected p.i = FindString(DSN, ":")
    If p > 0
      ProcedureReturn LCase(Left(DSN, p - 1))
    EndIf
    ProcedureReturn ""
  EndProcedure

  Procedure.i Driver(DSN.s)
    Protected scheme.s = _Scheme(DSN)
    Select scheme
      Case "sqlite"
        ProcedureReturn #Driver_SQLite
      Case "postgres", "postgresql"
        ProcedureReturn #Driver_Postgres
      Case "mysql"
        ProcedureReturn #Driver_MySQL
    EndSelect
    ProcedureReturn #Driver_Unknown
  EndProcedure
```

The `_Scheme` helper finds the first colon and returns everything before it in lowercase. The `Driver` procedure matches the scheme against known values. Both `postgres` and `postgresql` map to the same driver -- PostgreSQL users split into two camps on this naming question, and supporting both avoids a support ticket.

The `Select` statement is PureBasic's equivalent of a `switch`. Each `Case` branch is a string comparison. If no case matches, the procedure returns `#Driver_Unknown`, and the `Open` procedure will return 0 (failure).

> **PureBasic Gotcha:** PureBasic's `Select...Case` with strings is case-sensitive. The `LCase()` call in `_Scheme` normalizes the input so that `POSTGRES://`, `Postgres://`, and `postgres://` all work. Without it, uppercase DSN strings would fail silently. This is the kind of bug you find in production when someone copies a DSN from an environment variable that was exported in all caps.

---

## 23.4 URL Parsing

PostgreSQL and MySQL DSNs carry authentication and connection details in a URL format. The `DBConnect` module includes a set of internal parsing procedures that decompose the URL into its components.

```purebasic
; Listing 23.2 -- URL-parsing helpers (from Connect.pbi)
Procedure.s _AfterScheme(DSN.s)
  Protected p.i = FindString(DSN, "://")
  If p > 0
    ProcedureReturn Mid(DSN, p + 3)
  EndIf
  ; sqlite uses "sqlite:<path>" without "//"
  p = FindString(DSN, ":")
  If p > 0
    ProcedureReturn Mid(DSN, p + 1)
  EndIf
  ProcedureReturn DSN
EndProcedure

Procedure.s _UserInfo(Rest.s)
  Protected atPos.i = FindString(Rest, "@")
  If atPos > 0
    ProcedureReturn Left(Rest, atPos - 1)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s _User(UserInfo.s)
  Protected p.i = FindString(UserInfo, ":")
  If p > 0
    ProcedureReturn Left(UserInfo, p - 1)
  EndIf
  ProcedureReturn UserInfo
EndProcedure

Procedure.s _Pass(UserInfo.s)
  Protected p.i = FindString(UserInfo, ":")
  If p > 0
    ProcedureReturn Mid(UserInfo, p + 1)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s _Host(HostPath.s)
  Protected slashPos.i = FindString(HostPath, "/")
  Protected hostPort.s
  If slashPos > 0
    hostPort = Left(HostPath, slashPos - 1)
  Else
    hostPort = HostPath
  EndIf
  Protected colonPos.i = FindString(hostPort, ":")
  If colonPos > 0
    ProcedureReturn Left(hostPort, colonPos - 1)
  EndIf
  ProcedureReturn hostPort
EndProcedure

Procedure.s _Port(HostPath.s)
  Protected slashPos.i = FindString(HostPath, "/")
  Protected hostPort.s
  If slashPos > 0
    hostPort = Left(HostPath, slashPos - 1)
  Else
    hostPort = HostPath
  EndIf
  Protected colonPos.i = FindString(hostPort, ":")
  If colonPos > 0
    ProcedureReturn Mid(hostPort, colonPos + 1)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s _DBName(HostPath.s)
  Protected slashPos.i = FindString(HostPath, "/")
  If slashPos > 0
    ProcedureReturn Mid(HostPath, slashPos + 1)
  EndIf
  ProcedureReturn ""
EndProcedure
```

These seven procedures parse a URL the way you would parse it by hand: find the `://`, find the `@`, find the `/`, find the `:`. No regular expressions. No URI library. Just `FindString`, `Left`, and `Mid`. PureBasic's string functions are sufficient for well-formed URLs, and DSN strings are always well-formed because the developer writes them, not the user.

You could also parse the URL by hand with `Mid()` and `FindString()` in a single procedure. You could also build a house with a spoon. Both are technically possible. The helper procedures make each parsing step testable and reusable.

The parsing pipeline for `postgres://admin:secret@db.example.com:5432/blogdb` produces:

| Helper | Input | Output |
|--------|-------|--------|
| `_Scheme` | full DSN | `"postgres"` |
| `_AfterScheme` | full DSN | `"admin:secret@db.example.com:5432/blogdb"` |
| `_UserInfo` | after scheme | `"admin:secret"` |
| `_User` | userinfo | `"admin"` |
| `_Pass` | userinfo | `"secret"` |
| `_HostPath` | after scheme | `"db.example.com:5432/blogdb"` |
| `_Host` | hostpath | `"db.example.com"` |
| `_Port` | hostpath | `"5432"` |
| `_DBName` | hostpath | `"blogdb"` |

Each helper handles missing components gracefully. A DSN without a port returns an empty string for `_Port`. A DSN without credentials returns empty strings for `_User` and `_Pass`. The `Open` procedure passes these values to PureBasic's `OpenDatabase`, which uses driver-specific defaults for anything not specified.

```mermaid
graph LR
    A["postgres://admin:secret@host:5432/blogdb"] --> B[_Scheme]
    A --> C[_AfterScheme]
    C --> D[_UserInfo]
    C --> E[_HostPath]
    D --> F[_User]
    D --> G[_Pass]
    E --> H[_Host]
    E --> I[_Port]
    E --> J[_DBName]
    B --> K{Driver Select}
    F --> L[OpenDatabase]
    G --> L
    H --> M[ConnStr]
    I --> M
    J --> M
    M --> L
    K --> L

    style K fill:#4A90D9,color:#fff
```
*Figure 23.1 -- DSN factory: a URL-style string is parsed into components, assembled into PureBasic's connection format, and passed to `OpenDatabase` with the correct driver constant.*

---

## 23.5 The ConnStr Procedure

PureBasic's `OpenDatabase` takes a connection string in key-value format for server-based databases: `host=localhost port=5432 dbname=mydb`. The `ConnStr` procedure converts a URL-style DSN into this format:

```purebasic
; Listing 23.3 -- ConnStr: URL DSN to PureBasic key=value format
Procedure.s ConnStr(DSN.s)
  Protected rest.s     = _AfterScheme(DSN)
  Protected userInfo.s = _UserInfo(rest)
  Protected hostPath.s = _HostPath(rest)
  Protected host.s     = _Host(hostPath)
  Protected port.s     = _Port(hostPath)
  Protected dbname.s   = _DBName(hostPath)
  Protected result.s   = "host=" + host
  If port   <> ""
    result + " port="   + port
  EndIf
  If dbname <> ""
    result + " dbname=" + dbname
  EndIf
  ProcedureReturn result
EndProcedure
```

The user and password are deliberately excluded from the connection string. PureBasic's `OpenDatabase` takes them as separate parameters (the second and third arguments). This follows the same separation that PostgreSQL's `libpq` uses: the connection string describes *where* to connect, the credentials describe *who* is connecting.

Given `postgres://admin:secret@db.example.com:5432/blogdb`, `ConnStr` returns `"host=db.example.com port=5432 dbname=blogdb"`. The user `admin` and password `secret` are extracted separately by `_User` and `_Pass` and passed directly to `OpenDatabase`.

---

## 23.6 Opening Connections

The `Open` procedure is the public entry point. It detects the driver, parses the DSN, and calls `OpenDatabase` with the correct parameters:

```purebasic
; Listing 23.4 -- DBConnect::Open: the connection factory
Procedure.i Open(DSN.s)
  Protected drv.i    = Driver(DSN)
  Protected rest.s   = _AfterScheme(DSN)
  Protected userInfo.s, user.s, pass.s, cs.s

  Select drv
    Case #Driver_SQLite
      ProcedureReturn OpenDatabase(#PB_Any,
        rest, "", "", #PB_Database_SQLite)

    Case #Driver_Postgres
      userInfo = _UserInfo(rest)
      user     = _User(userInfo)
      pass     = _Pass(userInfo)
      cs       = ConnStr(DSN)
      ProcedureReturn OpenDatabase(#PB_Any,
        cs, user, pass, #PB_Database_PostgreSQL)

    Case #Driver_MySQL
      userInfo = _UserInfo(rest)
      user     = _User(userInfo)
      pass     = _Pass(userInfo)
      cs       = ConnStr(DSN)
      ProcedureReturn OpenDatabase(#PB_Any,
        cs, user, pass, #PB_Database_MySQL)

  EndSelect
  ProcedureReturn 0
EndProcedure
```

Three drivers, one procedure, one return type. The handle returned by `Open` is a standard PureBasic database handle. It works with `DB::Exec`, `DB::Query`, `DB::NextRow`, `DB::GetStr`, `DB::BindStr`, `DB::Migrate` -- every procedure from Chapters 13 and 14. The driver is invisible to the rest of your application.

The `#PB_Any` flag tells PureBasic to allocate the handle dynamically and return its ID. This is the same pattern used throughout PureSimple for all dynamically created resources (Chapter 2). Without `#PB_Any`, you would need to pre-assign a numeric handle, which does not scale when multiple database connections are open.

For SQLite, the connection string is just the file path (or `:memory:`). No user, no password, no host. The empty strings passed to `OpenDatabase` are ignored by the SQLite driver.

For PostgreSQL and MySQL, the full URL parsing pipeline runs: extract user and password from the userinfo, build the key-value connection string from host, port, and database name, and pass everything to `OpenDatabase` with the appropriate plugin constant.

> **Warning:** PostgreSQL and MySQL require their server processes to be running before `Open` is called. SQLite does not -- it creates the file on first access. If `Open` returns 0 for a PostgreSQL DSN, check that the server is running and the credentials are correct. The error is in the infrastructure, not in the code.

---

## 23.7 Configuration-Driven Connections

The `OpenFromConfig` procedure reads the DSN from the application's `.env` file:

```purebasic
; Listing 23.5 -- OpenFromConfig: one-line database setup
Procedure.i OpenFromConfig()
  Protected dsn.s = Config::Get("DB_DSN",
                                "sqlite::memory:")
  ProcedureReturn Open(dsn)
EndProcedure
```

Two lines. Read the `DB_DSN` environment variable (with a default of `sqlite::memory:`). Call `Open`. The application's database driver is now controlled entirely by the `.env` file:

```bash
; Listing 23.6 -- Switching databases via .env

# Development: SQLite file
DB_DSN=sqlite:data/app.db

# Staging: PostgreSQL
DB_DSN=postgres://appuser:staging_pass@localhost:5432/myapp_staging

# Production: MySQL
DB_DSN=mysql://appuser:prod_pass@db.internal:3306/myapp_production
```

No code changes. No recompilation. Just change the DSN, restart the app, and the database switches. This is the twelve-factor app principle from Chapter 18 applied to the database layer: configuration lives in the environment, not in the source code.

The default value of `sqlite::memory:` is deliberate. If no `.env` file exists and no `DB_DSN` is set, the app still starts -- with an in-memory database that vanishes when the process exits. This is useful for tests (Chapter 20) and for quick demos where persistence is unnecessary.

In practice, most PureSimple applications use `OpenFromConfig` in their `main.pb`:

```purebasic
; Listing 23.7 -- Using OpenFromConfig in an application
Config::Load(".env")
Protected _db.i = DBConnect::OpenFromConfig()
If _db = 0
  PrintN("ERROR: Cannot connect to database")
  PrintN("DB_DSN = " +
         Config::Get("DB_DSN", "(not set)"))
  End 1
EndIf
```

If the connection fails, the error message prints the DSN (without credentials) to help diagnose the problem. Fail fast, fail with useful information.

---

## 23.8 Driver Activation

At the top of `Connect.pbi`, three lines activate all database drivers at compile time:

```purebasic
; Listing 23.8 -- Driver activation
UseSQLiteDatabase()
UsePostgreSQLDatabase()
UseMySQLDatabase()
```

PureBasic requires explicit driver activation. Without `UsePostgreSQLDatabase()`, passing `#PB_Database_PostgreSQL` to `OpenDatabase` silently fails. These three lines ensure that all drivers are available regardless of which DSN the application uses at runtime.

The cost is minimal: each driver adds a small amount to the binary size, but the database client libraries are linked only if the compiler finds the corresponding `Use*Database()` call. On macOS, the SQLite library is part of the system. PostgreSQL and MySQL client libraries need to be installed separately.

> **Tip:** If you know your application will only ever use SQLite, you can omit the `UsePostgreSQLDatabase()` and `UseMySQLDatabase()` lines from your own code. The `DBConnect` module includes all three because it is a general-purpose connector. Removing unused drivers shaves a few kilobytes off the binary.

---

## 23.9 Practical Considerations

### SQL Dialect Differences

The `DBConnect` module abstracts the connection, not the query language. SQLite, PostgreSQL, and MySQL have different SQL dialects. A few common differences to watch for:

| Feature | SQLite | PostgreSQL | MySQL |
|---------|--------|-----------|-------|
| Auto-increment | `AUTOINCREMENT` | `SERIAL` or `GENERATED ALWAYS AS IDENTITY` | `AUTO_INCREMENT` |
| Upsert | `INSERT OR IGNORE` | `ON CONFLICT DO NOTHING` | `INSERT IGNORE` |
| Boolean type | `INTEGER (0/1)` | `BOOLEAN` | `TINYINT(1)` |
| String concat | `\|\|` | `\|\|` | `CONCAT()` |
| Current timestamp | `datetime('now')` | `NOW()` | `NOW()` |

If you plan to support multiple databases, write your SQL to the lowest common denominator, or maintain separate migration files for each driver. The Wild & Still blog (Chapter 22) uses SQLite-specific syntax (`INSERT OR IGNORE`, `AUTOINCREMENT`) and would need migration changes to run on PostgreSQL.

This is an honest trade-off. Database portability is valuable when you need it and unnecessary overhead when you don't. Most applications choose a database and stay with it. The `DBConnect` module gives you the option without forcing the decision.

### Connection Lifecycle

One difference between SQLite and server-based databases: connection cost. SQLite opens a local file in microseconds. PostgreSQL and MySQL negotiate a TCP connection, authenticate, and initialize a session -- this takes milliseconds. For a web application that opens a single connection at startup and holds it for the lifetime of the process, this difference is negligible. If you were opening a new connection per request (don't), the difference would matter.

PureSimple applications typically open one database connection in the boot sequence and pass the handle to all handlers via a global variable. This is the pattern used in the Wild & Still blog and the to-do API. It works for single-threaded applications. For multi-threaded applications with the `-t` flag, you would need connection pooling, which PureBasic does not provide natively. At that point, you are building infrastructure rather than a web application, and a connection pool module would be a worthwhile addition to the framework.

---

## Summary

The `DBConnect` module provides a DSN-based connection factory that abstracts over SQLite, PostgreSQL, and MySQL. A single `Open` procedure parses a URL-style DSN string, detects the driver, converts the connection parameters to PureBasic's native format, and returns a standard database handle. The `OpenFromConfig` convenience procedure reads the DSN from the `.env` file, making database selection a configuration decision rather than a code change. The abstraction covers connections only -- SQL dialect differences remain the application's responsibility.

## Key Takeaways

- Use `DBConnect::Open("sqlite:data/app.db")` or `DBConnect::OpenFromConfig()` for driver-agnostic database connections.
- The DSN prefix (`sqlite:`, `postgres://`, `mysql://`) determines the driver; the rest of the string provides connection details.
- SQL dialect differences (auto-increment syntax, upsert behavior, boolean types) are not abstracted -- write portable SQL or maintain per-driver migrations.

## Review Questions

1. What would happen if you passed a DSN with the prefix `mongodb://` to `DBConnect::Open`? Trace the code path through `Driver` and `Open` to explain the result.
2. Why does `ConnStr` exclude the user and password from the returned key-value string, even though they are part of the DSN?
3. *Try it:* Install PostgreSQL locally, create a test database, and modify the Wild & Still blog to use `DBConnect::OpenFromConfig()` with a PostgreSQL DSN. Which SQL statements in the migration need to change?

# Chapter 14: Database Patterns

*Patterns that keep your data layer clean as the app grows.*

---

**Learning Objectives**

After reading this chapter you will be able to:

- Implement the repository pattern to isolate database logic behind a module boundary
- Build paginated queries using LIMIT and OFFSET
- Wrap multi-step operations in transactions using BEGIN, COMMIT, and ROLLBACK
- Seed test data and reset database state between test suites

---

## 14.1 The Problem with Scattered SQL

In Chapter 13 you learned to open databases, run queries, and apply migrations. You now have the tools. What you do not yet have is a plan for where to put them.

The temptation is strong: write your SQL directly in your route handlers. Need to fetch a list of posts? Query right there in `IndexHandler`. Need to create a post? INSERT right there in `CreateHandler`. For a ten-route application, this works. For a thirty-route application with tests, admin panels, and API endpoints, you end up with the same SQL scattered across a dozen procedures, each with its own subtle variations in column ordering, error handling, and parameter binding.

You could also manage this chaos with copy-paste and optimism. You could also juggle running chainsaws. Both are impressive for about thirty seconds.

The solution is the repository pattern: put all database access for a given resource behind a module. Handlers call the module. The module talks to the database. The handler never sees a SQL string.

---

## 14.2 The Repository Pattern

A repository module exposes procedures like `FindAll`, `FindBySlug`, `Create`, `Update`, and `Delete`. Inside the module, you write SQL. Outside the module, you call clean procedures with typed parameters. If the database schema changes, you fix one module instead of hunting through every handler.

```purebasic
; Listing 14.1 -- A repository module for blog posts
EnableExplicit

DeclareModule PostRepo
  Declare.i FindAll(db.i, List titles.s(), List slugs.s())
  Declare.i FindBySlug(db.i, slug.s, *title.String,
                       *body.String)
  Declare.i Create(db.i, title.s, slug.s, body.s)
  Declare.i Update(db.i, slug.s, title.s, body.s)
  Declare.i DeleteBySlug(db.i, slug.s)
EndDeclareModule

Module PostRepo

  Procedure.i FindAll(db.i, List titles.s(),
                      List slugs.s())
    Protected count.i = 0
    ClearList(titles())
    ClearList(slugs())
    If DB::Query(db, "SELECT title, slug FROM posts " +
                      "ORDER BY id DESC")
      While DB::NextRow(db)
        AddElement(titles())
        titles() = DB::GetStr(db, 0)
        AddElement(slugs())
        slugs() = DB::GetStr(db, 1)
        count + 1
      Wend
      DB::Done(db)
    EndIf
    ProcedureReturn count
  EndProcedure

  Procedure.i FindBySlug(db.i, slug.s, *title.String,
                         *body.String)
    DB::BindStr(db, 0, slug)
    If DB::Query(db, "SELECT title, body FROM posts " +
                      "WHERE slug = ?")
      If DB::NextRow(db)
        *title\s = DB::GetStr(db, 0)
        *body\s  = DB::GetStr(db, 1)
        DB::Done(db)
        ProcedureReturn #True
      EndIf
      DB::Done(db)
    EndIf
    ProcedureReturn #False
  EndProcedure

  Procedure.i Create(db.i, title.s, slug.s, body.s)
    DB::BindStr(db, 0, title)
    DB::BindStr(db, 1, slug)
    DB::BindStr(db, 2, body)
    ProcedureReturn DB::Exec(db,
      "INSERT INTO posts (title, slug, body) " +
      "VALUES (?, ?, ?)")
  EndProcedure

  Procedure.i Update(db.i, slug.s, title.s, body.s)
    DB::BindStr(db, 0, title)
    DB::BindStr(db, 1, body)
    DB::BindStr(db, 2, slug)
    ProcedureReturn DB::Exec(db,
      "UPDATE posts SET title = ?, body = ? " +
      "WHERE slug = ?")
  EndProcedure

  Procedure.i DeleteBySlug(db.i, slug.s)
    DB::BindStr(db, 0, slug)
    ProcedureReturn DB::Exec(db,
      "DELETE FROM posts WHERE slug = ?")
  EndProcedure

EndModule
```

> **Under the Hood:** `String` is a built-in PureBasic structure with a single `\s` field. Using `*title.String` passes a string by reference -- access the value with `*title\s`. This avoids copying large strings between procedures.

The handler code becomes readable:

```purebasic
; Listing 14.2 -- Handler using the repository module
Procedure IndexHandler(*C.RequestContext)
  Protected NewList titles.s()
  Protected NewList slugs.s()
  PostRepo::FindAll(db, titles(), slugs())
  ; ... render the list ...
EndProcedure

Procedure PostHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")
  Protected title.String, body.String
  If PostRepo::FindBySlug(db, slug, @title, @body)
    ; ... render the post ...
  Else
    Rendering::Status(*C, 404)
  EndIf
EndProcedure
```

No SQL in the handler. No parameter binding in the handler. No `DB::Done` in the handler. The handler makes a request, gets a result, and renders it. That is its job. Talking to databases is the repository's job.

> **Compare:** In Go, you would define a `PostStore` interface with `FindAll`, `FindBySlug`, `Create`, `Update`, and `Delete` methods, then implement it with a struct holding a `*sql.DB`. PureBasic does not have interfaces, but modules with `DeclareModule` serve the same encapsulation purpose. The handler depends on the module's public API, not on its SQL implementation.

---

## 14.3 Pagination with LIMIT and OFFSET

When your posts table grows from five rows to five thousand, returning all of them in a single query is rude to your users and unkind to their browsers. Pagination limits each query to a fixed number of rows and lets the user navigate through pages.

SQLite supports `LIMIT` and `OFFSET` directly:

```purebasic
; Listing 14.3 -- Paginated query with LIMIT and OFFSET
Procedure.i FindPage(db.i, page.i, perPage.i,
                     List titles.s(), List slugs.s())
  Protected count.i = 0
  Protected offset.i = (page - 1) * perPage
  ClearList(titles())
  ClearList(slugs())

  DB::BindInt(db, 0, perPage)
  DB::BindInt(db, 1, offset)
  If DB::Query(db, "SELECT title, slug FROM posts " +
                    "ORDER BY id DESC " +
                    "LIMIT ? OFFSET ?")
    While DB::NextRow(db)
      AddElement(titles())
      titles() = DB::GetStr(db, 0)
      AddElement(slugs())
      slugs() = DB::GetStr(db, 1)
      count + 1
    Wend
    DB::Done(db)
  EndIf
  ProcedureReturn count
EndProcedure
```

Page 1 with 10 items per page gives `OFFSET 0`. Page 2 gives `OFFSET 10`. Page 3 gives `OFFSET 20`. The math is simple, and the pattern works well for small to medium datasets.

To build page navigation in your templates, you also need the total count:

```purebasic
; Listing 14.4 -- Getting total row count for pagination
Procedure.i CountPosts(db.i)
  Protected total.i = 0
  If DB::Query(db, "SELECT COUNT(*) FROM posts")
    If DB::NextRow(db)
      total = DB::GetInt(db, 0)
    EndIf
    DB::Done(db)
  EndIf
  ProcedureReturn total
EndProcedure
```

With `total` and `perPage`, you calculate `totalPages = (total + perPage - 1) / perPage` and render page links in your template.

> **Tip:** LIMIT/OFFSET pagination is simple and correct for datasets under ten thousand rows. For larger datasets, consider keyset pagination (also called cursor pagination), which uses `WHERE id > lastSeenId LIMIT N` instead of OFFSET. Keyset pagination does not degrade as the offset grows.

There is a known gotcha with OFFSET pagination that catches developers who come from larger database systems: with SQLite's single-writer model, the data can shift between the COUNT query and the SELECT query if a write happens in between. For a blog with one admin user, this is not a practical concern. For a high-traffic application, keyset pagination eliminates the issue entirely.

---

## 14.4 Transactions

Some operations must succeed or fail as a unit. If you are transferring credits between two user accounts, you cannot debit one account and then crash before crediting the other. Transactions ensure atomicity: either all statements succeed, or none of them take effect.

SQLite supports transactions through standard SQL statements: `BEGIN`, `COMMIT`, and `ROLLBACK`. The `DB` module executes these just like any other non-SELECT statement:

```purebasic
; Listing 14.5 -- Transaction wrapper pattern
Procedure.i TransferCredits(db.i, fromUser.i,
                            toUser.i, amount.i)
  ; Begin transaction
  If Not DB::Exec(db, "BEGIN")
    ProcedureReturn #False
  EndIf

  ; Debit sender
  DB::BindInt(db, 0, amount)
  DB::BindInt(db, 1, fromUser)
  If Not DB::Exec(db, "UPDATE users SET credits = " +
                       "credits - ? WHERE id = ?")
    DB::Exec(db, "ROLLBACK")
    ProcedureReturn #False
  EndIf

  ; Credit receiver
  DB::BindInt(db, 0, amount)
  DB::BindInt(db, 1, toUser)
  If Not DB::Exec(db, "UPDATE users SET credits = " +
                       "credits + ? WHERE id = ?")
    DB::Exec(db, "ROLLBACK")
    ProcedureReturn #False
  EndIf

  ; All good -- commit
  If Not DB::Exec(db, "COMMIT")
    DB::Exec(db, "ROLLBACK")
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure
```

The pattern is always the same: `BEGIN`, do work, check each step, `ROLLBACK` on any failure, `COMMIT` when everything succeeds. The `If Not ... ROLLBACK ... ProcedureReturn #False` sequence repeats for every statement in the transaction. This is verbose. It is also correct. In database programming, "correct and verbose" beats "clever and broken" every time.

> **Under the Hood:** SQLite uses a journal file (or WAL mode) to implement transactions. When you `BEGIN`, SQLite starts recording changes in a separate area. When you `COMMIT`, it makes those changes permanent. When you `ROLLBACK`, it discards them. The database file is never left in an inconsistent state, even if the process crashes mid-transaction. This is the same mechanism that makes SQLite reliable enough for aircraft flight recorders.

You could extract a generic transaction helper to reduce the boilerplate:

```purebasic
; Listing 14.6 -- Simplified transaction begin/rollback/commit
; Begin a transaction. Returns #True on success.
Procedure.i TxBegin(db.i)
  ProcedureReturn DB::Exec(db, "BEGIN")
EndProcedure

; Commit a transaction. Returns #True on success.
Procedure.i TxCommit(db.i)
  ProcedureReturn DB::Exec(db, "COMMIT")
EndProcedure

; Rollback a transaction.
Procedure TxRollback(db.i)
  DB::Exec(db, "ROLLBACK")
EndProcedure
```

These are thin wrappers, but they communicate intent. When you read `TxBegin(db)` you know exactly what is happening. When you read `DB::Exec(db, "BEGIN")` you have to parse the SQL string in your head.

---

## 14.5 Seeding Test Data

Tests need data. Every test suite that touches the database needs a known starting state. The seed pattern gives you that:

```purebasic
; Listing 14.7 -- Seeding test data into an in-memory DB
Procedure.i SetupTestDB()
  Protected db.i = DB::Open(":memory:")
  If db = 0 : ProcedureReturn 0 : EndIf

  DB::ResetMigrations()
  DB::AddMigration(1, "CREATE TABLE posts (" +
                       "id INTEGER PRIMARY KEY " +
                       "AUTOINCREMENT, " +
                       "title TEXT NOT NULL, " +
                       "slug TEXT NOT NULL UNIQUE, " +
                       "body TEXT NOT NULL)")

  If Not DB::Migrate(db)
    DB::Close(db)
    ProcedureReturn 0
  EndIf

  ; Seed known test data
  DB::BindStr(db, 0, "First Post")
  DB::BindStr(db, 1, "first-post")
  DB::BindStr(db, 2, "Hello world")
  DB::Exec(db, "INSERT INTO posts (title, slug, body) " +
               "VALUES (?, ?, ?)")

  DB::BindStr(db, 0, "Second Post")
  DB::BindStr(db, 1, "second-post")
  DB::BindStr(db, 2, "Goodbye world")
  DB::Exec(db, "INSERT INTO posts (title, slug, body) " +
               "VALUES (?, ?, ?)")

  ProcedureReturn db
EndProcedure
```

Each test opens a fresh in-memory database, seeds it, runs assertions, and closes it. No test can contaminate another. No leftover rows from a previous run will cause a spurious failure at 3 AM when you are trying to ship a fix.

The `SetupTestDB` function encapsulates the entire setup sequence: open, migrate, seed, return handle. If any step fails, it cleans up and returns zero. The test checks for zero and skips gracefully:

```purebasic
; Listing 14.8 -- Using the test database in a test suite
BeginSuite("PostRepo")

Define testdb.i = SetupTestDB()
Check(testdb > 0)

If testdb
  ; Test FindAll returns two posts
  Protected NewList titles.s()
  Protected NewList slugs.s()
  Protected count.i = PostRepo::FindAll(testdb,
                                         titles(),
                                         slugs())
  CheckEqual(count, 2)

  ; Test FindBySlug
  Protected t.String, b.String
  Protected found.i = PostRepo::FindBySlug(testdb,
                        "first-post", @t, @b)
  Check(found)
  CheckStr(t\s, "First Post")

  DB::Close(testdb)
EndIf

DB::ResetMigrations()
```

> **Tip:** Use `":memory:"` for test databases. They are fast (no disk I/O), isolated (each handle is independent), and require no cleanup. If you need to test file-based behavior, create a temporary file and delete it in your teardown code.

I have a personal rule: if a test takes more than 100 milliseconds, something is wrong. In-memory SQLite databases make this easy. The entire `SetupTestDB` sequence -- open, migrate, seed two rows -- takes less than a millisecond on modern hardware. You could run a thousand test databases before the kettle boils.

---

## 14.6 Connection Considerations

PureSimple runs in a single-threaded request model. One request at a time, one database connection, no contention. This simplicity is a feature. You do not need connection pools, you do not need to worry about two handlers trying to write to the same table simultaneously, and you do not need a mutex around your database calls.

If you move to a multi-threaded model (compiling with the `-t` flag and dispatching requests to worker threads), the rules change. SQLite supports concurrent reads but serialises writes. You would need one connection per thread or a shared connection protected by a mutex. The `DB` module does not currently manage connection pools -- that is a design decision for a future phase, and one that Chapter 23 (Multi-Database Support) touches on.

For now, the pattern is simple: open the database once at startup, pass the handle to your handlers, close it at shutdown. One connection, one handle, zero surprises.

> **Warning:** In-memory databases (`":memory:"`) are lost when the process exits. This is perfect for testing but dangerous for production. Always use a file path in production: `DB::Open("/opt/puresimple/data/app.db")`. And back up that file. SQLite databases are just files. Back them up like files.

---

## Summary

Database patterns give structure to your data layer as your application grows. The repository pattern isolates SQL behind module boundaries so handlers stay clean and testable. Pagination with LIMIT and OFFSET keeps queries efficient and responses reasonably sized. Transactions wrap multi-step operations in atomic units that either fully succeed or fully roll back. Seeding test data into in-memory databases gives you fast, isolated test runs that never interfere with each other or with production data.

---

**Key Takeaways**

- Isolate all database access behind repository modules -- handlers should never contain SQL strings.
- Use LIMIT/OFFSET for pagination and include a COUNT query to calculate total pages.
- Wrap multi-step database operations in BEGIN/COMMIT/ROLLBACK transactions to guarantee atomicity.

---

**Review Questions**

1. What are the advantages of the repository pattern over writing SQL directly in route handlers? Name at least two.

2. Explain why in-memory databases (`":memory:"`) are ideal for testing but unsuitable for production.

3. *Try it:* Write a `UserRepo` module with `Create`, `FindByID`, and `FindAll` procedures. Write a test suite that opens an in-memory database, seeds three users, and verifies that `FindAll` returns all three and `FindByID` returns the correct user.

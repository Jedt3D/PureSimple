# Chapter 20: Testing

![Chapter 20 opening illustration](../../illustrations/ch20-cover.svg)

*The 264 assertions that let you refactor without fear.*

---

**After reading this chapter you will be able to:**

- Write unit tests for handlers and middleware using the PureSimple test harness
- Construct `RequestContext` objects manually for isolated handler testing
- Use in-memory SQLite databases for integration tests that run without disk I/O
- Organise tests using the `run_all.pb` pattern with `BeginSuite` grouping
- Isolate test state with `Config::Reset`, `Session::ClearStore`, and `ResetMiddleware`

---

## 20.1 Why Tests Matter More in a Compiled Language

In Python or JavaScript, you can start your application, poke at it in a browser, and see immediately whether something broke. The feedback loop is fast. In a compiled language, the feedback loop includes a compilation step. If you change a handler and want to verify it works, you compile, run, open a browser, navigate to the page, and check the result. That is five steps where Python had two.

Tests collapse those five steps into one: compile and run the test binary. The test binary exercises your handlers, middleware, and database queries without starting an HTTP server or opening a browser. It runs in milliseconds, not minutes. And it checks everything, every time, including the feature you changed six months ago and forgot about.

PureSimple's test suite currently has 264 assertions across 11 test files. Every assertion runs every time. Every phase must pass all tests before merging. There are no "known failures." There are no tests marked "skip." If it is in the suite, it must pass. All 264 assertions pass. Or at least they did when I compiled this page.

## 20.2 The Test Harness Revisited

We introduced the test harness in Chapter 3. Here is a deeper look at how it works and how to use it effectively for framework-level testing.

The harness lives in `tests/TestHarness.pbi` and provides five tools:

```purebasic
; Listing 20.1 -- The test harness API
; From tests/TestHarness.pbi

BeginSuite(name)       ; label a group of related checks
Check(expr)            ; fails if expr is #False
CheckEqual(a, b)       ; fails if a <> b (numeric)
CheckStr(a, b)         ; fails if a <> b (string)
PrintResults()         ; print summary; exit code 0 or 1
```

`Check`, `CheckEqual`, and `CheckStr` are macros, not procedures. This is a deliberate design choice. Macros expand at compile time, which means `#PB_Compiler_File` and `#PB_Compiler_Line` resolve to the caller's file and line number, not the harness file. When a test fails, the output tells you exactly where the failure occurred:

```
  FAIL  CheckStr @ tests/P8_Config_Test.pbi:24 => "9091" <> "9090"
```

That line number points to the assertion in your test code, not to line 51 of `TestHarness.pbi`. This is the entire reason the harness uses macros. A procedure call would report its own line number, which tells you nothing useful.

> **PureBasic Gotcha:** PureBasic 6.x pre-defines `Assert()` and `AssertString()` as built-in halt-on-fail macros from `pureunit.res`. Redefining them causes silent conflicts. The harness avoids this by using `Check`, `CheckEqual`, and `CheckStr` -- non-conflicting names that also make the distinction clear: PureUnit halts on first failure, PureSimple's harness continues and reports all failures.

### How the Harness Counts

Two global counters -- `_PS_PassCount` and `_PS_FailCount` -- track every assertion. Each `Check*` macro calls a helper procedure that increments one counter or the other. At the end of the suite, `PrintResults` adds them up:

```purebasic
; Listing 20.2 -- From tests/TestHarness.pbi: the CheckEqual helper
Procedure _PS_CheckEqual(a.i, b.i, file.s, line.i)
  If a = b
    _PS_PassCount + 1
  Else
    _PS_FailCount + 1
    PrintN("  FAIL  CheckEqual @ " + file + ":" +
      Str(line) + " => " + Str(a) + " <> " + Str(b))
  EndIf
EndProcedure
```

Passing assertions are silent. Only failures produce output. This keeps the test run clean -- when everything passes, you see the suite names and the summary. When something breaks, the failure stands out immediately because it is the only output between the suite header and the summary.

```purebasic
; Listing 20.3 -- From tests/TestHarness.pbi: PrintResults
Procedure.i PrintResults()
  Protected Total.i = _PS_PassCount + _PS_FailCount
  PrintN("")
  PrintN("======================================")
  If _PS_FailCount = 0
    PrintN("  ALL TESTS PASSED  (" +
      Str(Total) + " assertions)")
  Else
    PrintN("  FAILURES: " + Str(_PS_FailCount) +
      " / " + Str(Total))
  EndIf
  PrintN("======================================")
  ProcedureReturn Bool(_PS_FailCount = 0)
EndProcedure
```

`PrintResults` returns `#True` if all tests passed and `#False` otherwise. The `run_all.pb` entry point uses this return value to set the process exit code:

```purebasic
; Listing 20.4 -- From tests/run_all.pb: exit with proper code
If PrintResults()
  End 0
Else
  End 1
EndIf
```

A non-zero exit code is critical for CI and deployment. The deploy script (Chapter 19) runs the test binary and checks its exit code. If tests fail, the deploy aborts. Without that exit code, the script would happily deploy broken code and you would discover the problem from a customer's bug report. At 3 AM.

> **Compare:** PureUnit's `Assert()` is equivalent to Go's `testing.Fatal()` -- it halts on the first failure, so you only see one broken test per run. PureSimple's `Check()` is equivalent to Go's `testing.Error()` -- it records the failure and continues, so you see all broken tests in a single run. When you have 264 assertions, seeing all failures at once saves you from the compile-run-fix-one-compile-run-fix-another cycle.

## 20.3 The run_all.pb Pattern

PureSimple uses a single entry point -- `tests/run_all.pb` -- that includes every test file. This produces one test binary that runs all assertions.

```purebasic
; Listing 20.5 -- From tests/run_all.pb
EnableExplicit

; Pull in the framework
XIncludeFile "../src/PureSimple.pb"

; Test harness (macros + counters)
XIncludeFile "TestHarness.pbi"

; Phase test files
PrintN("PureSimple Test Suite")
PrintN("=====================")
PrintN("")

XIncludeFile "P0_Harness_Test.pbi"
XIncludeFile "P1_Router_Test.pbi"
XIncludeFile "P2_Middleware_Test.pbi"
XIncludeFile "P3_Binding_Test.pbi"
XIncludeFile "P4_Rendering_Test.pbi"
XIncludeFile "P5_Groups_Test.pbi"
XIncludeFile "P6_SQLite_Test.pbi"
XIncludeFile "P7_Auth_Test.pbi"
XIncludeFile "P8_Config_Test.pbi"
XIncludeFile "P9_Examples_Test.pbi"
XIncludeFile "P10_MultiDB_Test.pbi"

If PrintResults()
  End 0
Else
  End 1
EndIf
```

The pattern is simple: include the framework, include the harness, include each test file, print results, exit. Adding a new phase's tests means adding one `XIncludeFile` line. The include order follows the phase numbers, which also follows the dependency order -- P0 tests the harness itself, P1 tests the router (which depends on the harness), P2 tests middleware (which depends on the router), and so on.

You compile and run the suite with two commands:

```bash
# Listing 20.6 -- Compiling and running the test suite
$PUREBASIC_HOME/compilers/pbcompiler tests/run_all.pb \
  -cl -o run_all
./run_all
```

The `-cl` flag is essential. Without it, PureBasic produces a GUI binary that cannot print to the terminal, and your test output goes nowhere. You will stare at a blank terminal and wonder if the tests passed. They did not. The output just went to an invisible window. Ask me how I know.

A successful run looks like this:

```
PureSimple Test Suite
=====================

  [Suite] P0 — Harness Self-Test
  [Suite] P1 — Router
  [Suite] P2 — Middleware
  [Suite] P3 — Binding
  [Suite] P4 — Rendering
  [Suite] P5 — Groups
  [Suite] P6 — SQLite
  [Suite] P7 — Auth
  [Suite] P8 — Config / Log / Modes
  [Suite] P9 — Examples
  [Suite] P10 — Multi-DB

======================================
  ALL TESTS PASSED  (264 assertions)
======================================
```

A failed run shows the failures inline:

```
  [Suite] P8 — Config / Log / Modes
  FAIL  CheckStr @ tests/P8_Config_Test.pbi:24
    => "9091" <> "9090"

======================================
  FAILURES: 1 / 264
======================================
```

## 20.4 Writing Unit Tests for Handlers

A unit test exercises a single function in isolation. For handlers, this means calling the handler procedure directly with a manually constructed `RequestContext`, then checking the context's state afterward.

Here is how the P8 Config tests exercise the `Config` module:

```purebasic
; Listing 20.7 -- From tests/P8_Config_Test.pbi: unit testing Config
Procedure P8_Config_Tests()
  Protected result.i, val.s, ival.i

  ; Load a known .env file
  Config::Reset()
  result = Config::Load("tests/test.env")
  Check(result)   ; file loaded successfully

  ; Verify parsed values
  CheckStr(Config::Get("PORT"),     "9090")
  CheckStr(Config::Get("MODE"),     "release")
  CheckStr(Config::Get("APP_NAME"), "PureSimple")
  CheckStr(Config::Get("DB_PATH"),  "data/test.db")

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
EndProcedure

P8_Config_Tests()
```

Notice the pattern: each test procedure is self-contained. It sets up state (load a known file), exercises the module (call `Get`, `GetInt`, `Has`), and verifies the results (use `Check`, `CheckStr`, `CheckEqual`). The procedure is called immediately after its definition -- PureBasic does not have a test runner that discovers tests automatically. You write the procedure, you call it.

> **Tip:** Start each test procedure by resetting shared state. `Config::Reset()` clears the config map. `Session::ClearStore()` wipes session data. `ResetMiddleware()` removes registered middleware. Without these resets, one test suite's leftover state becomes the next suite's mystery bug. I once spent forty minutes debugging a test failure that only happened when I ran the full suite. Running the test file alone? Green. Running all tests? Red. The cause was a config value from a previous suite that changed the behaviour of a later one. Call `Reset`. Always.

## 20.5 Testing Runtime Overrides

The Config test suite also verifies runtime overrides -- the ability to set values programmatically without a `.env` file. This is particularly important for testing, where you need to simulate different configurations without writing temporary files.

```purebasic
; Listing 20.8 -- Testing runtime overrides
; Runtime Set
Config::Set("RUNTIME_KEY", "hello")
CheckStr(Config::Get("RUNTIME_KEY"), "hello")

; Override an existing key
Config::Set("PORT", "1234")
CheckEqual(Config::GetInt("PORT"), 1234)

; Has detects dynamically set keys
Check(Config::Has("MODE"))
Check(Not Config::Has("DEFINITELY_MISSING"))

; Reset clears everything
Config::Reset()
Check(Not Config::Has("PORT"))
Check(Not Config::Has("MODE"))
```

Each assertion tests one specific behaviour. `Set` stores a value. `Set` on an existing key overwrites it. `Has` returns `#True` for existing keys and `#False` for missing ones. `Reset` clears all keys. These are not complex tests. They do not need to be. Their value comes from running automatically, every time, catching regressions that manual testing would miss.

## 20.6 Testing Engine Modes

The Engine mode tests verify that `SetMode` and `Mode` work as a getter/setter pair, and that the default mode is `"debug"`:

```purebasic
; Listing 20.9 -- Testing run modes
; Default is "debug"
CheckStr(Engine::Mode(), "debug")

; Set to release
Engine::SetMode("release")
CheckStr(Engine::Mode(), "release")

; Set to test
Engine::SetMode("test")
CheckStr(Engine::Mode(), "test")

; Restore default for other tests
Engine::SetMode("debug")
```

The final line -- restoring the default -- is crucial. If this test suite set the mode to `"test"` and did not restore it, every subsequent test would run in test mode. Some tests might behave differently in test mode. The failure would appear in a completely unrelated test file, and you would spend an hour reading the wrong code. Restore your defaults. Every time.

## 20.7 Testing Log Output

Log output is harder to test than config values because logs write to stdout or a file. The P8 test suite handles this by redirecting log output to a temporary file and verifying the file was created with content:

```purebasic
; Listing 20.10 -- Testing log output
; Redirect to temp file to avoid polluting test output
Log::SetOutput("tests/p8_log_test_tmp.txt")
Log::SetLevel(Log::#LevelDebug)

; Write at all levels
Log::Dbg("debug message")
Log::Info("info message")
Log::Warn("warn message")
Log::Error("error message")

; Restore defaults
Log::SetOutput("")
Log::SetLevel(Log::#LevelInfo)

; Verify the file exists and has content
Check(FileSize("tests/p8_log_test_tmp.txt") > 0)

; Clean up
DeleteFile("tests/p8_log_test_tmp.txt")
```

This is a pragmatic approach. It does not verify the exact contents of each log line -- that would make the test brittle, breaking every time you change the timestamp format. Instead, it verifies that the log system writes something to the file. The level filtering is tested implicitly: if `SetLevel(Log::#LevelDebug)` did not work, the debug message would not be written, and the file might be smaller than expected.

> **Under the Hood:** The test uses `FileSize` to check the file, not `FileExists` (which does not exist in PureBasic). `FileSize` returns `-1` for nonexistent files and the byte count for existing ones. The check `FileSize(path) > 0` confirms both existence and non-empty content in one call.

## 20.8 Integration Testing with In-Memory SQLite

Unit tests exercise individual functions. Integration tests exercise multiple components working together. For PureSimple, the most common integration test pattern involves an in-memory SQLite database.

SQLite's `:memory:` mode creates a database that lives entirely in RAM. It is fast (no disk I/O), isolated (no shared state between tests), and automatically destroyed when the database handle is closed. This makes it ideal for testing database-dependent handlers.

```purebasic
; Listing 20.11 -- Integration test with in-memory SQLite
Procedure TestPostCreation()
  Protected db.i

  ; Open in-memory database
  db = DB::Open(":memory:")
  Check(db <> 0)

  ; Run migrations
  DB::Exec(db, "CREATE TABLE posts (" +
    "id INTEGER PRIMARY KEY AUTOINCREMENT, " +
    "title TEXT NOT NULL, " +
    "slug TEXT NOT NULL UNIQUE, " +
    "body TEXT NOT NULL DEFAULT '')")

  ; Insert a post
  DB::Exec(db, "INSERT INTO posts (title, slug, body)" +
    " VALUES ('Hello', 'hello', 'World')")

  ; Query it back
  DB::Query(db, "SELECT title, slug FROM posts " +
    "WHERE slug = 'hello'")
  Check(DB::NextRow(db))
  CheckStr(DB::GetStr(db, 0), "Hello")
  CheckStr(DB::GetStr(db, 1), "hello")

  ; Clean up
  DB::Close(db)
EndProcedure
```

The pattern is: open an in-memory database, create the schema, insert test data, query it back, verify the results, close the database. Each test procedure gets its own database. No test can interfere with another. No test leaves behind a `.db` file that confuses the next developer.

> **Tip:** Use `:memory:` for test databases. It is faster than file-based SQLite (no disk I/O), automatically clean (no leftover data between runs), and requires no cleanup code. The only downside is that you cannot inspect the database after the test finishes, but if a test fails, the assertion output tells you what went wrong.

## 20.9 Regression Testing

A regression test verifies that a bug, once fixed, stays fixed. In PureSimple, the `run_all.pb` pattern is inherently a regression test suite. Every assertion from every phase runs every time. If phase P5 introduced a subtle interaction between route groups and middleware, and phase P8 accidentally breaks it, the P5 tests will catch it.

This is why the project rule is strict: every phase must pass all tests before merging. Not just the new phase's tests -- all tests. A change that makes P8 pass but breaks P2 is not a fix. It is a trade.

The practical benefit is confidence. When you refactor the router internals in a later phase, you run `./run_all` and either see 264 green assertions or a clear failure message pointing to the exact file and line that broke. You do not need to manually test every feature in the browser. You do not need to keep a checklist of "things to verify after changing the router." The test suite is your checklist, and it never forgets an item.

## 20.10 Test Organisation Best Practices

After writing tests for ten phases, patterns emerge. Here are the practices that keep a test suite maintainable as it grows.

**One test file per phase.** Each phase gets its own `.pbi` file: `P0_Harness_Test.pbi`, `P1_Router_Test.pbi`, and so on. This keeps files focused and makes it easy to find the tests for a specific feature.

**One procedure per test area.** Within a test file, group related assertions into procedures: `P8_Config_Tests()`, `P8_Log_Tests()`, `P8_Mode_Tests()`. Call each procedure at the bottom of the file. This provides logical grouping without requiring a test framework's discovery mechanism.

**Reset state at the start, restore defaults at the end.** Begin each test procedure with `Config::Reset()` or the appropriate cleanup call. End it by restoring any global state (like `Engine::SetMode("debug")`) to its default. The next test procedure should see a clean environment.

**Use `BeginSuite` for readable output.** A suite label in the test output tells you which group of assertions is running. When everything passes, the suite labels are the only output besides the summary. When something fails, the suite label tells you which area to investigate.

```purebasic
; Listing 20.12 -- Organising tests with BeginSuite
BeginSuite("P8 -- Config / Log / Modes")
P8_Config_Tests()
; P8_Log_Tests() would go here
; P8_Mode_Tests() would go here
```

**Test the sad path.** It is tempting to only test the happy path -- valid input, existing files, correct parameters. But bugs hide in the sad path: missing files, empty strings, invalid data, out-of-range values. The P8 suite tests that `Config::Load` returns `#False` for a nonexistent file, that `Get` returns the fallback for missing keys, and that `Has` returns `#False` for absent keys. These "boring" tests catch real bugs.

> **Warning:** Do not skip tests to make the suite pass faster. If a test is slow, make it faster (use `:memory:` instead of file-based SQLite). If a test is flaky, fix the root cause (usually shared mutable state). Skipping tests is technical debt with compound interest. You think you are saving time now. You are borrowing it from a future debugging session.

## 20.11 Testing Middleware Chains

Unit tests for individual handlers are valuable, but many bugs hide in the interaction between middleware. Does MiddlewareA run before MiddlewareB? Does the handler see the values that the middleware set? Testing the full chain without starting an HTTP server gives you confidence that your middleware ordering is correct.

The pattern is straightforward: construct a `RequestContext` manually, add handlers with `Ctx::AddHandler`, and call `Ctx::Dispatch` to run the chain. Each middleware calls `Ctx::Advance` to pass control to the next handler, and you verify the final state of the context.

```purebasic
; Listing 20.13 -- Testing a middleware chain
BeginSuite("Middleware chain ordering")

Ctx::Init(@testCtx, "GET", "/test")
Ctx::AddHandler(@testCtx, @MiddlewareA())
Ctx::AddHandler(@testCtx, @MiddlewareB())
Ctx::AddHandler(@testCtx, @TestHandler())
Ctx::Dispatch(@testCtx)

CheckStr(Ctx::Get(@testCtx, "order"), "A-B-handler")
CheckEqual(testCtx\StatusCode, 200)
```

Each middleware in this example appends its name to the `"order"` key in the context's key-value store. After dispatch, the test verifies that all three ran in the expected order. This pattern is valuable because it tests the middleware chain's behaviour without any HTTP overhead -- no socket, no parsing, no serialisation. If the ordering is wrong, the `CheckStr` assertion fails with a clear message showing the actual execution order versus the expected one.

This technique is especially useful when debugging middleware that depends on other middleware. If your auth middleware expects a session to be loaded, you can add both the session middleware and the auth middleware to a test chain and verify they cooperate correctly, all within a single test procedure.

---

## Summary

Testing in PureSimple follows a straightforward pattern: macros capture file and line information for failure reporting, helper procedures increment pass/fail counters, and `PrintResults` generates a summary with a proper exit code. The `run_all.pb` entry point includes every test file and produces a single binary that exercises all 264 assertions. Unit tests call module procedures directly with known inputs. Integration tests use in-memory SQLite for fast, isolated database testing. Every phase must pass all tests -- not just its own -- before merging.

## Key Takeaways

- **The harness uses macros for a reason.** `Check`, `CheckEqual`, and `CheckStr` are macros so that `#PB_Compiler_File` and `#PB_Compiler_Line` resolve at the call site, giving you accurate failure locations.
- **One binary, all tests.** The `run_all.pb` pattern produces a single test binary that runs every assertion. Adding a new test file means adding one `XIncludeFile` line.
- **Reset state between suites.** Call `Config::Reset()`, `Session::ClearStore()`, and `Engine::SetMode("debug")` to prevent one suite's state from contaminating the next.
- **Use `:memory:` for database tests.** In-memory SQLite is fast, isolated, and requires no cleanup.

## Review Questions

1. Why does the test harness use macros instead of procedures for `Check`, `CheckEqual`, and `CheckStr`? What would change if they were procedures?
2. Explain why the deploy script running `./run_all` on the server before swapping binaries is a critical safety net. What categories of bugs does this catch that local testing might miss?
3. *Try it:* Write a test file (`P_Custom_Test.pbi`) that uses `BeginSuite`, tests a simple procedure you define (such as a string formatting function), includes both passing and deliberately failing assertions, and observe the output format. Then fix the failing assertion, recompile, and verify all tests pass.

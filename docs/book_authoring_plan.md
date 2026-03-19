# Book Authoring Plan

**Master document for editors and reviewers.**
All chapter content in `book-outline.md` must conform to the guidelines below.

---

## 1. Book Identity

| Field | Value |
|-------|-------|
| **Title** | *PureSimple Web Framework: Building Fast, Dependency-Free Web Applications with PureBasic* |
| **Subtitle** | From Hello World to Production Blog in One Binary |
| **Author** | Jedt Sitth |
| **Target length** | 450-550 pages (print equivalent) |
| **Chapters** | 23 + 4 appendices |
| **Code repo** | `github.com/Jedt3D/PureSimple` (three-repo ecosystem) |
| **PureBasic version** | 6.x (C backend) |
| **Framework version** | PureSimple v0.10.0+ |

### Audience

| Tier | Profile | What they need |
|------|---------|---------------|
| Primary | Intermediate PureBasic developers who have written desktop apps but never a web app | Chapters 3-4 (HTTP fundamentals) are critical; Chapters 1-2 can be skimmed |
| Secondary | Experienced web developers (Go, Python, C, Node.js) exploring PureBasic | Chapters 1-3 (language & toolchain) are critical; Chapter 4 can be skimmed |
| Tertiary | Students, hobbyists, CS teachers looking for a single-binary web stack | Need everything; keep jargon to a minimum, always define terms on first use |

### Prerequisites

Readers should be comfortable with:
- At least one programming language (any)
- Basic terminal / command-line usage
- The concept of a web browser talking to a server (no HTTP expertise required)

Readers do **not** need:
- Prior PureBasic experience (covered in Chapters 2-3)
- Prior web framework experience (covered in Chapters 4+)
- Linux server administration (covered in Chapter 19)

---

## 2. Author Voice & Style Guide

### Tone

Write as an experienced developer talking to a peer over coffee. Be direct, be honest
about trade-offs, and respect the reader's intelligence. Avoid:
- Condescension ("as you obviously know...")
- Hedging ("you might perhaps consider...")
- Marketing language ("revolutionary", "game-changing")

Prefer:
- Short, declarative sentences
- Active voice ("PureBasic compiles to..." not "The code is compiled by...")
- Concrete examples over abstract explanations

### Reading Level

Target a Flesch-Kincaid grade level of 8-10 (clear, professional English). Use simple
words when they exist: "use" not "utilise", "start" not "initialise" (except when
`Init` is a function name), "send" not "transmit".

### Tech Humour Guidelines (5-10% per chapter)

Every chapter must include 2-4 moments of humour. These are not asides or callout boxes
-- they are woven naturally into the prose. Types of humour that work:

| Type | Example | When to use |
|------|---------|-------------|
| **Self-deprecating** | "I once spent three hours debugging a `FileExists()` call before discovering it doesn't exist. The function, I mean. The file was fine." | When introducing a gotcha the author personally hit |
| **Language contrast** | "In Go you'd write `if err != nil` about forty times per file. In PureBasic you write `If result = 0` about forty times per file. Progress." | When comparing PureBasic to other languages |
| **Naming pun** | "The method is called `Advance` because `Next` is reserved. PureBasic has strong opinions about `For...Next` loops, and it will not negotiate." | When explaining a PureBasic constraint |
| **Absurd escalation** | "You could also parse the query string manually with `Mid()` and `FindString()`. You could also build a house with a spoon. Both are technically possible." | When justifying why a convenience function exists |
| **Historical** | "The RFC calls this 'percent encoding' because '%20' is shorter than 'that space character that breaks everything'." | When explaining a protocol detail |

**Do not use:**
- Jokes that require pop-culture knowledge post-2020
- Memes, emoji humour, or "lol" / "lmao" tone
- Jokes at the expense of other languages or their communities (gentle ribbing is fine)
- Jokes that interrupt a critical explanation (security, data loss, production failures)

### Code Style

- All code blocks use `purebasic` syntax highlighting
- Maximum line length: 85 characters (fits in print margins)
- Every code block longer than 5 lines gets a caption comment at the top:
  ```purebasic
  ; Listing 4.1 — Registering routes with named parameters
  Engine::GET("/users/:id", @GetUser())
  Engine::POST("/users", @CreateUser())
  ```
- Use `; ← explanation` inline comments sparingly, only when the line is non-obvious
- Every code example must compile. No pseudocode. No "..." elisions in running code.
  (Use `; ... (omitted for brevity)` only if the surrounding code compiles without it.)
- Include `EnableExplicit` in every standalone listing (not in fragments that are part
  of a larger file)

### Terminology

| Preferred | Avoid | Reason |
|-----------|-------|--------|
| handler | controller, endpoint | Framework uses "handler" |
| middleware | filter, interceptor | Framework uses "middleware" |
| route | path pattern, URL rule | Consistent with Gin/Chi terminology |
| context | request object, `*C` | "Context" is the concept; `*C` is the variable |
| chain | pipeline, stack | "Handler chain" is the framework term |
| advance | next | `Next` is a reserved keyword; `Advance` is the method |
| binary | executable, artifact | "Single native binary" is the book's tagline |

---

## 3. Chapter Architecture

Every chapter follows this exact structure:

```
1. CHAPTER TITLE PAGE
   - Chapter number and title
   - One-sentence tagline (appears under the title)
   - AI illustration (full-width, black-and-white pen sketch)

2. LEARNING OBJECTIVES (bulleted list, 3-5 items)
   "After reading this chapter you will be able to:"
   - Verb-first objectives (configure, implement, explain, debug)

3. BODY (3-6 numbered sections)
   - Each section: 2-6 pages
   - Code listings referenced by number: "Listing 5.3"
   - Diagrams referenced by number: "Figure 5.1"
   - Callout boxes (see below)

4. SUMMARY (1 paragraph, 3-5 sentences)

5. KEY TAKEAWAYS (bulleted list, 3-5 items)
   - Each takeaway: one sentence, concrete and actionable

6. REVIEW QUESTIONS (1-3 questions)
   - Difficulty: conceptual recall + one "try it" question
   - No answers in the chapter (Appendix E collects all answers)
```

### Callout Box Types

| Type | Icon | When to use |
|------|------|-------------|
| **Tip** | lightbulb | A useful shortcut or best practice |
| **Warning** | exclamation | Something that will bite you if ignored |
| **PureBasic Gotcha** | bug | A language-specific surprise (from common-pitfalls.md) |
| **Compare** | arrows | How this concept maps to Go, Python, or Node.js |
| **Under the Hood** | gear | Implementation detail for the curious (can be skipped) |

---

## 4. Visual Asset Specifications

### 4a. MermaidJS Diagrams

Every diagram is authored in MermaidJS and stored in the manuscript source. The
production pipeline renders them to SVG for print and web.

**Conventions:**
- Maximum 12 nodes per diagram (readability)
- Use consistent colour theme: grayscale with one accent colour (#4A90D9)
- Label every edge
- Use `graph TD` (top-down) for request flows, `graph LR` (left-right) for
  pipelines, `classDiagram` for data structures
- Number diagrams sequentially within each chapter: Figure 5.1, Figure 5.2

**Required diagrams by chapter** (see Per-Chapter Plan for details):

| Chapter | Figures | Subject |
|---------|---------|---------|
| 1 | 1.1, 1.2 | Three-repo ecosystem; compilation pipeline |
| 3 | 3.1, 3.2 | Compiler pipeline; XIncludeFile resolution tree |
| 4 | 4.1, 4.2 | HTTP request/response cycle; URL anatomy |
| 5 | 5.1 | Radix trie routing example |
| 6 | 6.1, 6.2 | RequestContext struct; KV store data flow |
| 7 | 7.1, 7.2 | Middleware chain (onion model); middleware ordering |
| 10 | 10.1 | Route group tree (prefix + middleware inheritance) |
| 11 | 11.1, 11.2 | PureJinja render pipeline; template inheritance tree |
| 13 | 13.1 | SQLite integration: open → migrate → query → close |
| 15 | 15.1, 15.2 | Session lifecycle; Cookie read/write flow |
| 16 | 16.1 | BasicAuth decode pipeline |
| 17 | 17.1 | CSRF token flow (generate → embed → validate) |
| 19 | 19.1, 19.2, 19.3 | Deploy pipeline; systemd lifecycle; Caddy proxy |
| 22 | 22.1 | Blog route map and handler chain diagram |
| 23 | 23.1 | DSN factory: one interface, three drivers |

### 4b. AI-Generated Illustrations

Each chapter opens with a full-width illustration. Style: **black-and-white pen
sketching**, reminiscent of technical patent drawings or field-notebook illustrations.
No colour. Crosshatching for shading. Thin, confident ink lines.

**AI prompt template:**
```
Black and white pen sketch illustration, technical drawing style with crosshatching.
[SUBJECT]. Clean white background, no text, no labels. Style: architectural patent
drawing meets nature field notebook. Ink on paper texture.
```

**Required illustrations (one per chapter):**

| Ch | Subject | Prompt extension |
|----|---------|-----------------|
| 1 | A single compiled binary sitting on a circuit board, dwarfing interpreters and VMs shown as complex Rube Goldberg machines beside it | Show contrast between simplicity and complexity |
| 2 | A workbench with labelled drawers (Types, Strings, Maps, Lists, Modules) — each drawer slightly open showing neatly organised tools inside | Craftsman's workshop feel |
| 3 | A precision lathe or milling machine (the compiler) turning raw source code scrolls into a polished mechanical gear (the binary) | Industrial precision, steampunk touches |
| 4 | A postal sorting office: letters (requests) arriving, being stamped (headers), sorted into pigeonholes (routes), and reply letters (responses) going out | Edwardian-era post office |
| 5 | A tree with paths carved into its trunk (the radix trie), with small signposts at each branch point showing `:id` and `*path` | Botanical drawing of a tree with carved paths |
| 6 | A traveller's rucksack (the RequestContext) with pockets labelled Method, Path, Params, Headers, KV Store — items visible in each pocket | Explorer's field pack |
| 7 | A series of gates in a walled garden — each gate is a middleware, a traveller passes through each one, handing over a passport (context) at every gate | Medieval castle gates |
| 8 | An intake funnel sorting different materials (query strings, form data, JSON) into labelled bins | Industrial sorting mechanism |
| 9 | A printing press assembling a page — type blocks (variables) being placed into a frame (template), ink roller (renderer) about to print | Gutenberg press |
| 10 | A tree of roads diverging from a single trunk road, with toll booths (middleware) at each junction | Road network branching |
| 11 | A puppet theatre stage — the puppet master (PureJinja) holds strings connected to HTML elements on stage; filters are the pulleys | Theatre mechanism |
| 12 | A completed jigsaw puzzle of a webpage, each piece labelled (nav, content, footer, sidebar) | Jigsaw with clear piece outlines |
| 13 | A library card catalogue (the database) — drawers labelled with table names, cards being inserted and retrieved | Library catalogue cabinet |
| 14 | An architect's drafting table with blueprints (schemas), a ruler (migration runner), and numbered revision stamps | Technical drafting scene |
| 15 | A hotel reception desk — a guest (request) receives a room key (cookie) with a tag (session ID); behind the desk, pigeonholes hold session data | Hotel reception |
| 16 | A castle gate with a guard checking credentials (BasicAuth), a wax seal (CSRF token), and a moat (the middleware chain) | Castle security |
| 17 | A wax seal press stamping tokens onto documents, with a verification desk checking seals against a ledger | Wax seal and verification |
| 18 | A control room with dials and gauges (log levels), a `.env` file on a clipboard, and a mode switch (debug/release/test) | Industrial control panel |
| 19 | A crane lowering a binary onto a server rack, with a health-check stethoscope attached to the server | Deployment as construction |
| 20 | A laboratory bench with test tubes (assertions), a microscope (debugger), and a lab notebook (test runner output) | Science laboratory |
| 21 | A kitchen where ingredients (JSON, routes, handlers) are being assembled into a dish (the To-Do API) on a mise-en-place counter | Chef's workstation |
| 22 | A printing workshop producing a newspaper (the blog) — layout tables, ink, typeset blocks, and a delivery bicycle outside | Newspaper production |
| 23 | Three identical keys (SQLite, PostgreSQL, MySQL) opening the same lock (the DB interface) | Key-and-lock mechanism |

---

## 5. Code Standards

### Compilation Guarantee

Every code listing in the book must compile with PureBasic 6.x. The CI pipeline runs:

```bash
for file in manuscript/listings/*.pb; do
  $PUREBASIC_HOME/compilers/pbcompiler -k "$file"
done
```

Listings that require the PureSimple framework must include:
```purebasic
XIncludeFile "../../src/PureSimple.pb"
```

### Listing Numbering

Format: `Listing {chapter}.{sequence}` — e.g., Listing 7.3 is the third listing in
Chapter 7. Each listing gets a one-line caption.

### Code Repository Cross-References

When referencing actual repository files, use the format:
> See `src/Router.pbi` in the PureSimple repository.

When showing code from the repository, note the source:
```purebasic
; From src/Context.pbi — Ctx::Advance procedure
```

### Test Code

Chapters that introduce testable features should include at least one test listing
using the PureSimple harness (`Check`, `CheckEqual`, `CheckStr`). Chapter 3 introduces
PureUnit and the custom harness, so all subsequent chapters can reference both.

---

## 6. Per-Chapter Production Plan

Each entry below specifies: the section breakdown, required diagrams, required
illustrations, code listings, callout boxes, and end-of-chapter materials.

---

### Chapter 1: Why PureBasic for the Web?
**Tagline:** *The case for compiling your web app into a single file that just runs.*
**Estimated pages:** 15-18

#### Sections
1. **The Binary Advantage** (3 pp)
   - What "zero dependencies" means in practice
   - Comparison: deploying a Go binary vs a Node.js app vs a PureSimple binary
   - Memory and startup time (show actual numbers from the `massively` example)
   - *Joke opportunity:* "Your `node_modules` folder has more files than some operating systems."

2. **Why Not Just Use Go?** (2 pp)
   - Honest comparison: Go has a larger ecosystem, better concurrency
   - PureBasic wins: smaller binaries, simpler toolchain, no package manager drama
   - The niche: developers who want native speed without learning systems programming

3. **The Three-Repo Ecosystem** (3 pp)
   - PureSimpleHTTPServer: what it does, what it doesn't do
   - PureSimple: the router/framework layer
   - PureJinja: template engine with 36 filters
   - How they compile into one binary
   - *Diagram:* Figure 1.1 — Three-repo dependency graph (MermaidJS)

4. **Setting Up the Development Environment** (3 pp)
   - Installing PureBasic 6.x (macOS, Linux, Windows)
   - Setting `PUREBASIC_HOME`
   - IDE vs command-line workflow
   - Cloning the three repos side-by-side

5. **Hello World: Your First PureSimple App** (3 pp)
   - The 10-line app from `docs/api/index.md`
   - Compiling and running
   - What each line does
   - *Diagram:* Figure 1.2 — Compilation pipeline (source → compiler → binary → browser)

#### Visual Assets
- **Illustration:** Compiled binary vs Rube Goldberg interpreters
- **Figure 1.1:** Three-repo ecosystem (MermaidJS `graph TD`)
- **Figure 1.2:** Compilation pipeline (MermaidJS `graph LR`)

#### Code Listings
- Listing 1.1 — Hello World PureSimple app (10 lines)
- Listing 1.2 — Compiling and running from the terminal

#### Callout Boxes
- **Compare:** "If you know Go's `net/http` — PureSimple is roughly Gin for PureBasic"
- **Tip:** "Set `PUREBASIC_HOME` in your shell profile so you don't have to export it every session"

#### End of Chapter
- **Summary:** PureBasic compiles to native binaries with no runtime dependencies. The PureSimple ecosystem splits responsibility across three repos that merge at compile time.
- **Key Takeaways:** (1) One binary, zero deployment complexity. (2) Three repos, one `XIncludeFile` chain. (3) The compiler is your package manager.
- **Questions:**
  1. Name the three repositories in the PureSimple ecosystem and explain what each one does.
  2. What is the advantage of compiling a web app into a single binary versus deploying an interpreted language?
  3. *Try it:* Clone all three repos, compile and run the Hello World example.

---

### Chapter 2: The PureBasic Language
**Tagline:** *Everything you need to read framework code and write handlers.*
**Estimated pages:** 22-26

#### Sections
1. **Types and Variables** (4 pp)
   - Built-in types: `.i`, `.l`, `.s`, `.d`, `.f`, `.b`, `.w`, `.q`
   - The `.i` trap: pointer-sized integer (4 bytes on x86, 8 on x64)
   - `EnableExplicit` — why every file in PureSimple starts with it
   - `Protected` vs `Global` vs `Shared` — scope rules
   - *Joke opportunity:* "Forgetting `EnableExplicit` is like driving without a seatbelt. You feel free right up until the crash."

2. **Strings** (3 pp)
   - Concatenation with `+`
   - `StringField()` and `CountString()` — PureBasic's split/count
   - `Mid()`, `Left()`, `Right()`, `FindString()`
   - Escape sequences with `~"..."` prefix
   - `Chr()` and `Asc()` — character codes

3. **Data Structures** (4 pp)
   - `Structure` and `*pointer.StructName` — PureBasic's structs
   - `NewMap` — hash maps with `FindMapElement()` and `MapKey()`
   - `NewList` — doubly-linked lists
   - `Dim` / `ReDim` — arrays (remember: `Dim a(N)` creates N+1 elements)
   - When to use each: Map for KV lookup, List for ordered collections, Array for indexed access
   - *Gotcha box:* "`Dim a(5)` creates 6 elements (indices 0-5). Not 5. Six."

4. **Procedures and Prototypes** (3 pp)
   - `Procedure` / `ProcedureReturn` / `EndProcedure`
   - Return types: `Procedure.s` (string), `Procedure.i` (integer)
   - `Prototype.i` — function pointers (used for handler registration)
   - Procedure addresses with `@MyProc()`
   - `Declare` for forward references

5. **Modules** (4 pp)
   - `DeclareModule` / `Module` / `EndModule` — the black-box model
   - `UseModule` — importing module symbols
   - Why module bodies cannot see main-code globals
   - The `Types` module pattern: shared types across modules
   - *Joke opportunity:* "Module bodies are like hotel rooms. What happens inside stays inside. Unless you left the door open with `DeclareModule`."

6. **Error Handling** (3 pp)
   - Return-code pattern: `If result = 0 : handle error : EndIf`
   - `OnErrorGoto` / `OnErrorResume` — structured error recovery
   - `ErrorMessage()`, `ErrorLine()`, `ErrorFile()`
   - Why `OnErrorGoto` doesn't catch OS signals on macOS arm64
   - The Recovery middleware pattern (preview of Chapter 7)

7. **Reserved Words That Will Bite You** (2 pp)
   - `Next` — cannot be used as a procedure name (`For...Next`)
   - `Default` — cannot be used as a parameter name (`Select...Case...Default`)
   - `Data` — cannot be used as a variable name (`Data` statement)
   - `Debug` — the IDE debug output statement
   - `FreeJSON`, `Assert` — built-in names that shadow custom definitions
   - *Table:* Reserved word → what it does → PureSimple's workaround name

#### Visual Assets
- **Illustration:** Craftsman's workbench with labelled drawers
- No MermaidJS diagrams required (language fundamentals are better taught through code)

#### Code Listings
- Listing 2.1 — Type declarations and `EnableExplicit`
- Listing 2.2 — String manipulation: `StringField` splitting a CSV line
- Listing 2.3 — Structure definition and pointer access
- Listing 2.4 — Map, List, and Array comparison
- Listing 2.5 — Module declaration and `UseModule`
- Listing 2.6 — `OnErrorGoto` error recovery pattern
- Listing 2.7 — Reserved word workarounds table (as code comments)

#### Callout Boxes
- **PureBasic Gotcha:** "`Dim a(N)` creates N+1 elements" (with example)
- **PureBasic Gotcha:** "There is no `FileExists()` — use `FileSize(path) >= 0`"
- **Compare:** "PureBasic's modules are like Go packages, except they share nothing by default"
- **Warning:** "`EnableExplicit` is non-negotiable. Every file in PureSimple uses it."

#### End of Chapter
- **Summary:** PureBasic is a typed, compiled language with explicit variable declaration, manual memory management, and a module system that enforces strong encapsulation. Understanding types, strings, structures, and modules is essential before reading framework code.
- **Key Takeaways:** (1) Always use `EnableExplicit`. (2) `.i` is pointer-sized, not 32-bit. (3) Module bodies are black boxes — use `DeclareModule` to expose interfaces. (4) Several common English words (`Next`, `Default`, `Data`) are reserved.
- **Questions:**
  1. Why does `Dim a(5)` create six elements, and how would you create exactly five?
  2. Explain the difference between `IncludeFile` and `XIncludeFile`.
  3. *Try it:* Write a module that exposes a `Greet(name.s)` procedure returning `"Hello, " + name + "!"`.

---

### Chapter 3: The PureBasic Toolchain — Compiler, Debugger, and PureUnit
**Tagline:** *The three tools that turn your code into a tested, debugged binary.*
**Estimated pages:** 20-24

This is the **new chapter** added to give readers a solid foundation in PureBasic's
development toolchain before they encounter the framework. Readers who complete this
chapter can compile, test, and debug any code in the PureSimple repository.

#### Sections
1. **The PureBasic Compiler (`pbcompiler`)** (5 pp)
   - Command-line invocation: `$PUREBASIC_HOME/compilers/pbcompiler`
   - Essential flags:
     - `-cl` — console application (required for servers and test runners)
     - `-o <name>` — output binary name
     - `-z` — enable C optimiser (release builds)
     - `-k` — syntax check only (no binary produced)
     - `-t` — thread-safe mode (required when using threads)
     - `-dl` — compile as shared library / DLL
   - The include resolution model: how `XIncludeFile` builds the compilation unit
   - `XIncludeFile` vs `IncludeFile` — why `X` prevents duplicate definitions
   - Compiler constants: `#PB_Compiler_OS`, `#PB_Compiler_Processor`,
     `#PB_Compiler_File`, `#PB_Compiler_Line`, `#PB_Compiler_Home`
   - Cross-platform compilation notes (macOS, Linux, Windows paths)
   - *Diagram:* Figure 3.1 — Compiler pipeline: `.pb` → preprocessor (includes) → C backend → system linker → binary
   - *Joke opportunity:* "The compiler doesn't have a package manager. It doesn't need one. It also doesn't have a `node_modules` folder. You're welcome."

2. **The Include Tree** (3 pp)
   - How PureSimple's `src/PureSimple.pb` includes all modules
   - Include order matters: types before consumers
   - *Diagram:* Figure 3.2 — XIncludeFile resolution tree for `PureSimple.pb`
   - Practical exercise: trace the include chain from `run_all.pb`

3. **The PureBasic IDE and Debugger** (4 pp)
   - IDE overview (for readers who prefer a GUI)
   - Setting compiler options in the IDE
   - The integrated debugger: breakpoints, variable watches, call stack
   - The profiler: procedure-level timing
   - Debug output window: the `Debug` statement
   - When to use IDE vs command line (answer: command line for web servers)
   - *Tip:* "The IDE is excellent for exploring and debugging. The command line is essential for CI and deployment. Use both."

4. **PureUnit — The Built-in Test Framework** (4 pp)
   - What PureUnit is: `Assert()` and `AssertString()` halt on first failure
   - How to write a PureUnit test file
   - Running PureUnit tests from the IDE and command line
   - Limitations: halt-on-fail means you only see the first broken test
   - Why PureSimple uses a custom harness instead (count-and-continue)
   - *Compare box:* PureUnit's `Assert()` vs PureSimple's `Check()` (side-by-side table)

5. **The PureSimple Test Harness** (4 pp)
   - `TestHarness.pbi` — macros + global counters
   - `Check(expr)` — boolean assertion
   - `CheckEqual(a, b)` — numeric equality
   - `CheckStr(a, b)` — string equality
   - `BeginSuite("name")` — test organisation
   - `PrintResults()` — summary with pass/fail counts and exit code
   - The `run_all.pb` pattern: one entry point includes all test files
   - Writing your first test suite: a step-by-step walkthrough
   - *Joke opportunity:* "All 264 tests pass. Or at least they did when I compiled this page."

6. **Putting It All Together** (2 pp)
   - Compile → Run Tests → Debug Failure → Fix → Re-test cycle
   - The workflow PureSimple uses for every phase
   - Quick reference card: essential compiler flags

#### Visual Assets
- **Illustration:** Precision lathe turning source scrolls into a polished gear
- **Figure 3.1:** Compiler pipeline (MermaidJS `graph LR`)
- **Figure 3.2:** XIncludeFile tree for `PureSimple.pb` (MermaidJS `graph TD`)

#### Code Listings
- Listing 3.1 — Compiling a console app from the command line
- Listing 3.2 — PureSimple.pb include chain (annotated)
- Listing 3.3 — A PureUnit test file: `Assert()` and `AssertString()`
- Listing 3.4 — The PureSimple `Check` / `CheckEqual` / `CheckStr` macros
- Listing 3.5 — Writing a test suite: `BeginSuite` + assertions + `PrintResults`
- Listing 3.6 — The `run_all.pb` entry point pattern
- Listing 3.7 — Using `#PB_Compiler_File` and `#PB_Compiler_Line` for diagnostics

#### Callout Boxes
- **Warning:** "Always use `-cl` for server applications and test runners. Without it, PureBasic produces a GUI binary that won't print to the terminal."
- **PureBasic Gotcha:** "PureBasic 6.x pre-defines `Assert()` and `AssertString()` from `pureunit.res`. Redefining them causes a silent conflict."
- **Compare:** "PureUnit = Go's `testing.Fatal()` (halt on first fail). PureSimple's harness = Go's `testing.Error()` (continue and report all)."
- **Tip:** "Use `-k` for syntax checking during development — it's 10x faster than a full compile."

#### End of Chapter
- **Summary:** The PureBasic toolchain consists of the `pbcompiler` (with flags for console mode, optimisation, and thread safety), the IDE with integrated debugger, and PureUnit for halt-on-fail assertions. PureSimple extends PureUnit with a count-and-continue harness that reports all failures rather than stopping at the first.
- **Key Takeaways:** (1) `-cl` for console, `-z` for release, `-k` for syntax check. (2) `XIncludeFile` prevents duplicate definitions; include order matters. (3) PureUnit halts on first failure; PureSimple's harness continues. (4) The `run_all.pb` pattern: one entry point, one binary, all tests.
- **Questions:**
  1. What is the difference between `-cl` and the default compiler mode, and why does it matter for web servers?
  2. Why does PureSimple use `Check()` instead of PureBasic's built-in `Assert()`?
  3. *Try it:* Write a test file with `BeginSuite`, three `Check` assertions (one failing), compile with `-cl`, run it, and read the output.

---

### Chapter 4: HTTP Fundamentals
**Tagline:** *The language your browser and server speak to each other.*
**Estimated pages:** 14-16

*(Previously Chapter 3. Content unchanged, renumbered.)*

#### Sections
1. **Request and Response** (3 pp)
   - Method, path, headers, body, status code
   - *Diagram:* Figure 4.1 — HTTP request/response cycle
   - *Joke opportunity:* "HTTP is a polite conversation between two programs that fundamentally don't trust each other."

2. **URL Anatomy** (3 pp)
   - Scheme, host, port, path, query, fragment
   - Path segments and why `/users/42` is different from `/users?id=42`
   - Percent encoding (`%20`, `+`)
   - *Diagram:* Figure 4.2 — URL anatomy with labelled parts

3. **Content Types** (2 pp)
   - `application/json`, `text/html`, `text/plain`
   - Content negotiation (brief)
   - When to use which (API vs browser vs plain health check)

4. **Stateless HTTP** (2 pp)
   - Why HTTP forgets you after every request
   - Cookies: the sticky note on the fridge
   - Sessions: the server's memory of who you are
   - Preview of Chapters 15-17

5. **What PureSimpleHTTPServer Provides** (3 pp)
   - Listener, TLS, compression, static file serving
   - What PureSimple adds: routing, middleware, context, rendering
   - The dispatch callback — where the two repos meet

#### Visual Assets
- **Illustration:** Edwardian postal sorting office
- **Figure 4.1:** HTTP request/response cycle (MermaidJS `sequenceDiagram`)
- **Figure 4.2:** URL anatomy (MermaidJS `graph LR` with labelled segments)

#### Code Listings
- Listing 4.1 — A raw HTTP request (text, not code)
- Listing 4.2 — A raw HTTP response (text, not code)

#### End of Chapter
- **Summary:** HTTP is a stateless request-response protocol. Browsers send requests with a method, path, and headers; servers reply with a status code, headers, and body. PureSimpleHTTPServer handles the low-level socket work; PureSimple adds routing and structure.
- **Key Takeaways:** (1) Every HTTP request has a method, a path, and headers. (2) Query strings and path parameters are two ways to pass data in a URL. (3) HTTP is stateless — cookies and sessions add memory.
- **Questions:**
  1. What is the difference between a path parameter (`/users/:id`) and a query parameter (`/users?id=42`)?
  2. Why is HTTP considered stateless, and what mechanism do web apps use to remember users between requests?

---

### Chapters 5-23: Section Structure

The remaining chapters follow the same template. Below is the condensed production
checklist for each. Full section breakdowns should be written during the drafting phase,
following the pattern established in Chapters 1-4 above.

---

#### Chapter 5: Routing (was Ch 4)
- **Diagrams:** Figure 5.1 — Radix trie routing example
- **Listings:** Route registration (GET/POST/PUT/PATCH/DELETE), named params, wildcards, priority demo
- **Callouts:** Compare (Gin's `r.GET` vs `Engine::GET`), Gotcha (wildcard must be last segment)
- **Joke:** On route priority: "Exact beats param beats wildcard. Democracy has no place in URL matching."

#### Chapter 6: The Request Context (was Ch 5)
- **Diagrams:** Figure 6.1 — RequestContext struct fields; Figure 6.2 — KV store data flow
- **Listings:** Ctx::Init, Ctx::Advance, Ctx::Abort, Ctx::Set/Get, Ctx::Param
- **Callouts:** Gotcha (`Advance` not `Next`), Under the Hood (handler chain array with index)

#### Chapter 7: Middleware (was Ch 6)
- **Diagrams:** Figure 7.1 — Onion model; Figure 7.2 — Middleware ordering (A→B→handler→B→A)
- **Listings:** Logger, Recovery, custom rate-limiter middleware
- **Callouts:** Warning (middleware order matters — Logger before Recovery), Compare (Express.js `app.use()`)
- **Joke:** "Middleware is like airport security. Everyone passes through it, nobody enjoys it, and it catches the one thing that would ruin everyone's day."

#### Chapter 8: Request Binding (was Ch 7)
- **Listings:** Query, PostForm, BindJSON, JSONString, ReleaseJSON, validation pattern
- **Callouts:** Gotcha (`ReleaseJSON` not `FreeJSON` — name collision), Warning (always validate user input)

#### Chapter 9: Response Rendering (was Ch 8)
- **Listings:** JSON, HTML, Text, Status, Redirect (302/301), File, Render with PureJinja
- **Callouts:** Tip (use `Rendering::Status` for 204 No Content), Compare (Gin's `c.JSON()`)

#### Chapter 10: Route Groups (was Ch 9)
- **Diagrams:** Figure 10.1 — Group tree with prefix inheritance and middleware stacking
- **Listings:** Group::Init, Group::Use, nested SubGroup, API versioning pattern, admin group with BasicAuth
- **Callouts:** Under the Hood (MW[32] fixed array and copy-on-SubGroup)

#### Chapter 11: PureJinja — Jinja2 Templates in PureBasic (was Ch 10)
- **Diagrams:** Figure 11.1 — Render pipeline (tokenize → parse → render); Figure 11.2 — Template inheritance tree
- **Listings:** Variable output, if/for, extends/block, filter chaining, the `split` filter
- **Callouts:** Compare (Python Jinja2 vs PureJinja — identical syntax, compiled execution)
- **Note:** Update filter count to 36 (includes `split`)

#### Chapter 12: Building an HTML Application (was Ch 11)
- **Listings:** Project structure, base template, index page with loop, detail page, 404/500 pages, flash messages
- **Callouts:** Tip (keep templates in a dedicated directory; use `.html` extension)

#### Chapter 13: SQLite Integration (was Ch 12)
- **Diagrams:** Figure 13.1 — SQLite lifecycle: open → migrate → query → close
- **Listings:** DB::Open, DB::Exec DDL/DML, DB::Query with NextRow, BindStr/BindInt, DB::Migrate
- **Callouts:** Warning (always use parameterised queries — never concatenate user input into SQL), Gotcha (`NextRow` not `Next`)

#### Chapter 14: Database Patterns (was Ch 13)
- **Listings:** Repository module pattern, LIMIT/OFFSET pagination, transaction wrapper, seed data pattern
- **Callouts:** Tip (use `:memory:` for test databases — fast and automatically clean)

#### Chapter 15: Cookies and Sessions (was Ch 14)
- **Diagrams:** Figure 15.1 — Session lifecycle; Figure 15.2 — Cookie read/write flow
- **Listings:** Cookie::Get/Set, Session::Middleware, Session::Get/Set, Session::Save
- **Callouts:** Warning (in-memory sessions are lost on restart — acceptable for development), Gotcha (`sessData` not `data` — reserved word)

#### Chapter 16: Authentication (was Ch 15)
- **Diagrams:** Figure 16.1 — BasicAuth decode pipeline
- **Listings:** BasicAuth::SetCredentials, BasicAuth::Middleware, Fingerprint SHA-256 password hashing, session login flow
- **Callouts:** Warning (never store plaintext passwords), Compare (Passport.js middleware pattern)

#### Chapter 17: CSRF Protection (was Ch 16)
- **Diagrams:** Figure 17.1 — CSRF token flow (generate → embed → validate)
- **Listings:** CSRF::GenerateToken, CSRF::SetToken, CSRF::Middleware, form with `_csrf` hidden field
- **Callouts:** Tip (JSON APIs using `Authorization` headers don't need CSRF), Under the Hood (128-bit random hex)

#### Chapter 18: Configuration and Logging (was Ch 17)
- **Listings:** Config::Load, Config::Get/GetInt/Has/Set/Reset, Engine::SetMode, Log levels, Log::SetOutput to file
- **Callouts:** Tip (twelve-factor: one `.env` per environment, never commit `.env`), Compare (Go's Viper vs Config module)

#### Chapter 19: Deployment (was Ch 18)
- **Diagrams:** Figure 19.1 — Deploy pipeline; Figure 19.2 — systemd lifecycle; Figure 19.3 — Caddy reverse proxy
- **Listings:** `deploy.sh` walkthrough, `rollback.sh`, systemd unit file, Caddyfile, health check endpoint
- **Callouts:** Warning (never deploy without a health check), Tip (Caddy auto-HTTPS requires a domain name)
- **Joke:** "The rollback script exists because hope is not a deployment strategy."

#### Chapter 20: Testing (was Ch 19)
- **Listings:** Unit test for a handler, middleware chain test, integration test with in-memory SQLite, regression test pattern
- **Callouts:** Tip (call `ResetMiddleware()`, `Session::ClearStore()`, `Config::Reset()` between suites)

#### Chapter 21: Building a REST API — To-Do List (was Ch 20)
- **Listings:** Full `main.pb` for the to-do app, CRUD handlers, `curl` test commands, adding auth
- **Callouts:** Tip (scaffold with `scripts/new-project.sh`)

#### Chapter 22: Building a Blog — Wild & Still (was Ch 21)
- **Diagrams:** Figure 22.1 — Route map and handler chain diagram
- **Listings:** Full `main.pb` from `examples/massively/`, migration runner with 10 migrations, PostsToStr helper, template rendering, admin CRUD, contact form PRG
- **This is the capstone chapter.** It ties together everything from Chapters 1-20.
- **Callouts:** Under the Hood (the `SafeVal` function and why Tab characters break the KV store)
- **Joke:** "596 lines of PureBasic. One binary. A production blog. Your React app has more lines in its webpack config."

#### Chapter 23: Multi-Database Support (was Ch 22)
- **Diagrams:** Figure 23.1 — DSN factory: one interface, three drivers
- **Listings:** DBConnect::Open with SQLite/PostgreSQL/MySQL DSNs, DBConnect::OpenFromConfig, DBConnect::Driver, DBConnect::ConnStr
- **Callouts:** Warning (PostgreSQL and MySQL require their server processes running; SQLite is file-based)

---

## 7. Appendix Production Plan

### Appendix A: PureBasic Quick Reference for Web Developers
- Two-page cheat sheet: types, strings, structures, maps, lists, modules
- Comparison table: PureBasic vs Go vs Python vs C (key syntax differences)
- Condensed common-gotchas table (10-12 entries from `resources/common-pitfalls.md`)

### Appendix B: PureSimple API Reference
- Generated from `docs/api/*.md` — all 11 module summaries
- `RequestContext` field reference table (all fields, types, descriptions)
- Handler signature reference

### Appendix C: PureJinja Filter Reference
- All 36 built-in filters with one-line descriptions and examples
- Grouped by category: String, Number, List, Object, Encoding, Special

### Appendix D: Compiler Flags Reference
- Table of all `pbcompiler` flags used in the book
- Columns: flag, description, when to use, example

### Appendix E: Review Question Answers
- One-paragraph answers to all chapter-end questions
- "Try it" questions get a complete code solution

---

## 8. Production Checklist (for Editors)

### Per-Chapter Review

- [ ] Learning objectives use action verbs (configure, implement, explain)
- [ ] All code listings compile with `pbcompiler -k`
- [ ] All MermaidJS diagrams render correctly
- [ ] Humour is present (2-4 moments) and appropriate (no exclusionary jokes)
- [ ] Callout boxes are used correctly (right type for content)
- [ ] Summary matches the chapter content (not a repeat of the intro)
- [ ] Key takeaways are concrete and actionable (not vague)
- [ ] Review questions test recall AND application
- [ ] No undefined terms — every concept is explained on first use
- [ ] Cross-references are correct (chapter and listing numbers)
- [ ] Code listing numbers are sequential within the chapter
- [ ] Figure numbers are sequential within the chapter
- [ ] Terminology is consistent (see Section 2 table)

### Full-Book Review

- [ ] Chapter numbering is sequential (1-23)
- [ ] All cross-references resolve (no "see Chapter X" pointing to wrong chapter)
- [ ] Filter count is consistently 36 throughout
- [ ] PureBasic version is consistently 6.x throughout
- [ ] Framework version is consistently v0.10.0+ throughout
- [ ] No chapter exceeds 30 pages (split if necessary)
- [ ] Appendix E has answers for every review question
- [ ] Index covers all module names, procedure names, and key concepts
- [ ] All illustrations have alt-text for accessibility

---

## 9. File Organisation

```
manuscript/
  chapters/
    ch01-why-purebasic.md
    ch02-language.md
    ch03-toolchain.md          ← NEW
    ch04-http.md
    ch05-routing.md
    ch06-context.md
    ch07-middleware.md
    ch08-binding.md
    ch09-rendering.md
    ch10-groups.md
    ch11-purejinja.md
    ch12-html-app.md
    ch13-sqlite.md
    ch14-db-patterns.md
    ch15-sessions.md
    ch16-auth.md
    ch17-csrf.md
    ch18-config-logging.md
    ch19-deployment.md
    ch20-testing.md
    ch21-rest-api.md
    ch22-blog.md
    ch23-multi-db.md
  appendices/
    app-a-reference.md
    app-b-api.md
    app-c-filters.md
    app-d-compiler.md
    app-e-answers.md
  illustrations/
    ch01-binary-vs-rube-goldberg.png
    ch02-workbench.png
    ch03-compiler-lathe.png
    ... (one per chapter)
  diagrams/
    fig-01-01-ecosystem.mmd
    fig-01-02-pipeline.mmd
    fig-03-01-compiler.mmd
    fig-03-02-include-tree.mmd
    ... (one per figure)
  listings/
    listing-01-01.pb
    listing-01-02.pb
    ... (one per listing)
```

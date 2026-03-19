# Editing Proposal

Editorial review of all 28 manuscript files (23 chapters + 5 appendices).
Mark each item **[Y]** to fix or **[N]** to skip.

---

## CRITICAL — Code won't compile or factual errors

### C01. Ch08 Listing 8.7: `EndProcedure` instead of `EndIf` [Y]

The `ReleaseJSON` listing uses `EndProcedure` where `EndIf` should close the `If` block.
This code will not compile. The actual source (`src/Binding.pbi:172-177`) is correct.

**File:** `manuscript/chapters/ch08-binding.md`
**Fix:** Replace inner `EndProcedure` with `EndIf` in the ReleaseJSON listing.

---

### C02. Ch19 Listing 19.15: Reversed `Rendering::Text` arguments [Y]

Shows `Rendering::Text(*C, 200, "OK")` but the actual signature is
`Text(*C, Body.s, StatusCode.i = 200)` — Body first, then Status.
The actual massively health handler uses `Rendering::JSON(*C, ~"{\"status\":\"ok\"}")`.

**File:** `manuscript/chapters/ch19-deployment.md`
**Fix:** Change to `Rendering::JSON(*C, ~"{\"status\":\"ok\"}")` or `Rendering::Text(*C, "OK")`.

---

### C03. Ch22 Section 22.4: PostsToStr format omits `id` field [Y]

Text says format is `slug|title|published_at|photo_url|excerpt|published` (6 fields).
Actual code produces `id|slug|title|published_at|photo_url|excerpt|published` (7 fields,
starting with `id`). This cascading error also affects Ch22 Listing 22.8 template indices.

**File:** `manuscript/chapters/ch22-blog.md`
**Fix:** (a) Correct format description to include leading `id`. (b) Verify template
index references (`p[0]`=id, `p[1]`=slug, etc.) match actual `index.html`.

---

### C04. Appendix C: Filter count contradicts rest of book [Y]

Appendix C concludes "34 unique + 3 aliases = 37 registered names." The rest of the book
(Ch1 architecture diagram, Ch11, outline, CLAUDE.md) consistently says "36 filters."
One number must be authoritative.

**File:** `manuscript/appendices/app-c-filters.md` + all references
**Fix:** Cross-check against `pure_jinja/Environment/Filters.pbi` RegisterAll().
Count actual unique filters + aliases. Update Appendix C and all references to match.

---

### C05. Appendix E Ch5 Q2: Procedures referenced before definition [Y]

Listing E.3 calls `@HomeHandler()` before `HomeHandler` is defined. PureBasic requires
either a `Declare` forward-declaration or defining procedures before taking their address.

**File:** `manuscript/appendices/app-e-answers.md`
**Fix:** Move procedure definitions before `Engine::GET(...)` calls, or add `Declare` statements.

---

## MAJOR — Content missing, significant inconsistencies

### M01. Ch05/Ch06: Missing `EnableExplicit` in standalone listings [Y]

Chapters 1-3 correctly include `EnableExplicit` in standalone listings. Starting at Ch05,
standalone handler listings systematically omit it. Affects ~12 listings across Ch05-Ch06.
The authoring plan requires it in every standalone listing.

**Files:** `ch05-routing.md`, `ch06-context.md`
**Fix:** Add `EnableExplicit` as the first line of each standalone listing in both chapters.
Audit Ch07-Ch23 for the same pattern.

---

### M02. Ch03: Listing and Figure numbering out of order [Y]

Listing 3.7 appears before Listing 3.2. Figure 3.2 appears before Figure 3.1.
The authoring plan requires sequential numbering matching order of appearance.

**File:** `manuscript/chapters/ch03-toolchain.md`
**Fix:** Renumber listings and figures to match their order of appearance in the text.

---

### M03. Ch04: Duplicate joke with Ch03 [Y]

"Build a house with a spoon" appears in both Ch03 (line 397) and Ch04 (line 122).

**Files:** `ch03-toolchain.md` and `ch04-http.md`
**Fix:** Keep the Ch04 instance (better context). Replace the Ch03 instance with a
different absurd-escalation joke.

---

### M04. Ch02: Missing learning objectives for error handling [Y]

Sections 2.6 (error handling) and 2.7 (reserved words) are present in the chapter
but not promised in the learning objectives. Objectives-to-content mismatch.

**File:** `manuscript/chapters/ch02-language.md`
**Fix:** Add objective: "Handle runtime errors using return-code patterns and `OnErrorGoto`."

---

### M05. Ch12: Templates don't use `{% extends %}`/`{% block %}` [Y]

Learning objective #2 says "Build a base template and extend it." But the actual
template listings are standalone HTML files without inheritance — contradicting Ch11's
teaching and the outline's explicit requirement.

**File:** `manuscript/chapters/ch12-html-app.md`
**Fix:** Refactor blog templates to use a `base.html` with `{% extends %}` and `{% block %}`.

---

### M06. Ch12: Flash messages topic missing [Y]

The outline lists "Flash messages via sessions" for this chapter. The chapter has
no mention of flash messages, sessions, or one-time redirect messages.

**File:** `manuscript/chapters/ch12-html-app.md`
**Fix:** Add a section covering flash messages (Session::Set before redirect,
Session::Get + clear after). Or add a forward-reference to Ch15 and remove from outline.

---

### M07. Ch16: Token-based auth missing from chapter [Y]

The outline lists "Token-based auth: storing tokens in the KV store" but the chapter
skips from BasicAuth directly to password hashing.

**File:** `manuscript/chapters/ch16-auth.md`
**Fix:** Add a brief section on token-based auth, or remove it from the outline.

---

### M08. Ch18: Log rotation topic missing [Y]

The outline lists "Log rotation and file management" but the chapter doesn't cover it.

**File:** `manuscript/chapters/ch18-config-logging.md`
**Fix:** Add a paragraph: "PureSimple does not include built-in log rotation. On Linux,
use `logrotate`. The open-write-close-per-line pattern allows rotation at any time."

---

### M09. Ch21/Ch22/App A: Contradictory `@Module::Proc()` claims [Y]

Ch22 says `@Logger::Middleware()` fails with `EnableExplicit` and requires wrappers.
Ch21 and `examples/todo/main.pb` use it directly and compile fine. Appendix A Gotcha #11
also claims it fails. One explanation must be correct.

**Files:** `ch21-rest-api.md`, `ch22-blog.md`, `app-a-reference.md`
**Fix:** Test empirically. If direct `@Module::Proc()` works, soften Ch22's explanation
(the restriction may only apply in `Global` initialisers, not program-level calls).
Update Appendix A Gotcha #11 to match.

---

### M10. Appendix B: Phantom `FormKeys`/`FormVals` fields [Y]

PostForm description references `*C\FormKeys` / `*C\FormVals` which do not exist
in `src/Types.pbi`. The RequestContext has no such fields.

**File:** `manuscript/appendices/app-b-api.md`
**Fix:** Remove the reference or replace with the actual caching mechanism from `Binding.pbi`.

---

### M11. Appendix E Ch22 Q2: Wrong redirect URL [Y]

Answer says `Rendering::Redirect(*C, "/contact?sent=1")` but the actual source
(`main.pb:372`) redirects to `/contact/ok`.

**File:** `manuscript/appendices/app-e-answers.md`
**Fix:** Change to `Rendering::Redirect(*C, "/contact/ok")`.

---

### M12. Ch22: Wrong migration table name [Y]

Section 22.5 says "`_migrations` table" but the actual table name in
`src/DB/SQLite.pbi` is `puresimple_migrations`.

**File:** `manuscript/chapters/ch22-blog.md`
**Fix:** Change to `puresimple_migrations`.

---

### M13. Ch20: Missing middleware chain test [Y]

The outline calls for "testing middleware chains: constructing RequestContext manually"
but the chapter tests Config/Log/Mode — no middleware chain test shown.

**File:** `manuscript/chapters/ch20-testing.md`
**Fix:** Add a section showing manual RequestContext construction, AddHandler, Dispatch,
and asserting handler execution order.

---

### M14. Ch15: Figure numbering out of sequence [Y]

Figure 15.2 (cookie flow) appears in section 15.2, before Figure 15.1 (session lifecycle)
in section 15.3. Figures must appear in sequential order.

**File:** `manuscript/chapters/ch15-sessions.md`
**Fix:** Swap figure numbers so the first diagram encountered is 15.1.

---

## MEDIUM — Accuracy, completeness, consistency

### D01. Ch04-Ch06, Ch18: Inconsistent learning objectives heading [Y]

Chapters 1-3 use `## Learning Objectives`. Chapters 4-6 and 18 omit the heading,
going directly to "After reading this chapter you will be able to:".

**Files:** `ch04-http.md`, `ch05-routing.md`, `ch06-context.md`, `ch18-config-logging.md`
**Fix:** Add `## Learning Objectives` heading to match Ch1-3 format.

---

### D02. Ch13: Missing `UseSQLiteDatabase()` mention [Y]

The source calls `UseSQLiteDatabase()` at module level. A reader writing standalone
code would get a runtime error without it.

**File:** `manuscript/chapters/ch13-sqlite.md`
**Fix:** Add a PureBasic Gotcha callout explaining `UseSQLiteDatabase()` is required
and that PureSimple.pb handles it via the include chain.

---

### D03. Ch15: Cookie::Set default parameters not shown [Y]

Chapter shows `Cookie::Set(*C, Name.s, Value.s, Path.s, MaxAge.i)` as required params.
Actual source has `Path.s = "/"` and `MaxAge.i = 0` as defaults.

**File:** `manuscript/chapters/ch15-sessions.md`
**Fix:** Show defaults in the signature display.

---

### D04. Ch16: BasicAuth snippet omits null-pointer check [Y]

The source includes `If *buf = 0 : Ctx::AbortWithError(...) : EndIf` after
`AllocateMemory`. The chapter's excerpt skips this safety check.

**File:** `manuscript/chapters/ch16-auth.md`
**Fix:** Include the null check or add comment `; (null check omitted for brevity)`.

---

### D05. Ch18: Missing section separators (---) [Y]

Chapter 18 omits `---` between sections, unlike all other chapters.

**File:** `manuscript/chapters/ch18-config-logging.md`
**Fix:** Add `---` between each numbered section and before Summary/Takeaways/Questions.

---

### D06. Ch23: Missing `_User`/`_Pass` helpers in listing [Y]

Listing 23.2 shows parsing helpers but omits `_User` and `_Pass` which are referenced
in the parsing pipeline table.

**File:** `manuscript/chapters/ch23-multi-db.md`
**Fix:** Add `_User` and `_Pass` helpers to the listing.

---

### D07. Ch19: Figure numbering doesn't match appearance order [Y]

Figures 19.2 and 19.3 appear before Figure 19.1 in the text.

**File:** `manuscript/chapters/ch19-deployment.md`
**Fix:** Renumber figures to match order of appearance, or reorder sections.

---

### D08. Appendix E Ch23 Q1: Wrong dispatch description [Y]

Says `Open` "dispatches to `UseSQLiteDatabase`..." but those are compile-time activation.
`Open` dispatches to `OpenDatabase()` with different `#PB_Database_*` constants.

**File:** `manuscript/appendices/app-e-answers.md`
**Fix:** Change to "dispatches to `OpenDatabase()` with the appropriate driver constant."

---

### D09. Appendix E Ch22 Q3: Creates new DB connection per request [Y]

The TagHandler answer calls `DBConnect::OpenFromConfig()` on every request instead
of using the global `_db` handle.

**File:** `manuscript/appendices/app-e-answers.md`
**Fix:** Use the global `_db` handle, matching the blog's architecture.

---

### D10. Appendix E Ch3 Q3: Expected output format wrong [Y]

Shows `=== My First Test Suite ===` and `PASS:` lines, but the actual harness
uses `[Suite]` headers with silent passes and a summary block.

**File:** `manuscript/appendices/app-e-answers.md`
**Fix:** Update expected output to match actual harness format.

---

### D11. Ch16: Humor count below minimum [Y]

Only 1 joke found. The authoring plan requires 2-4 per chapter.

**File:** `manuscript/chapters/ch16-auth.md`
**Fix:** Add 1-2 light moments in the password hashing or login flow sections.

---

### D12. Ch14: `String` built-in structure used without explanation [Y]

Listing 14.1 uses `*title.String` without explaining that `String` is a PureBasic
built-in structure with a `\s` field.

**File:** `manuscript/chapters/ch14-db-patterns.md`
**Fix:** Add an Under the Hood callout explaining the `String` structure.

---

## MINOR — Style, formatting, nice-to-have

### S01. Ch01/Ch03: Listing captions use `;` in bash blocks [Y]

PureBasic uses `;` for comments, bash uses `#`. Several listings use `;` inside bash blocks.

**Files:** `ch01-why-purebasic.md`, `ch03-toolchain.md`, `ch21-rest-api.md`
**Fix:** Move listing captions outside code blocks or use `#` for bash blocks.

---

### S02. Ch03 Figure 3.2: Exceeds 12-node diagram limit [Y]

The XIncludeFile tree has 18 nodes. The authoring plan says max 12.

**File:** `manuscript/chapters/ch03-toolchain.md`
**Fix:** Collapse middleware nodes into a single "Middleware/*.pbi" subgraph node.

---

### S03. Ch06 Figure 6.2: Unicode `\u21E5` may not render [Y]

The KV store diagram uses `⇥` (tab symbol) which may fail in some Mermaid renderers.

**File:** `manuscript/chapters/ch06-context.md`
**Fix:** Replace `⇥` with `TAB` in the node label.

---

### S04. Ch02 Summary: Mentions "manual memory management" [Y]

The summary says "manual memory management" but the chapter never covers
`AllocateMemory`/`FreeMemory`.

**File:** `manuscript/chapters/ch02-language.md`
**Fix:** Change to "explicit type declarations" or remove the phrase.

---

### S05. Ch12: `{{ request.path }}` in 404 template unexplained [Y]

The 404 template references `request.path` but no handler code sets this variable.

**File:** `manuscript/chapters/ch12-html-app.md`
**Fix:** Show the 404 handler code that calls `Ctx::Set(*C, "request.path", *C\Path)`.

---

### S06. Ch13: `Protected` inside `While` loop [Y]

Listing 13.5 declares `Protected` inside a `While` body, which re-declares per iteration.

**File:** `manuscript/chapters/ch13-sqlite.md`
**Fix:** Move `Protected` declarations before the `While`, or add a brief note that
PureBasic `Protected` is scoped to the procedure, not the block.

---

### S07. Ch17/Ch18: Missing cross-reference chapter numbers [Y]

Ch17 mentions sessions implicitly but never cites "Chapter 15." Ch18 references
"P8 test suite" using an internal phase designation readers won't know.

**Files:** `ch17-csrf.md`, `ch18-config-logging.md`
**Fix:** Add explicit chapter references. Replace "P8 test suite" with "the configuration
test suite."

---

### S08. Appendix D: Extra table column in D.2 [Y]

Table separator has 4 columns but header has 3, producing a phantom column.

**File:** `manuscript/appendices/app-d-compiler.md`
**Fix:** Remove extra `|` from separator row.

---

### S09. Ch19 Figure 19.2: Circular reference in systemd diagram [Y]

`restart` connects to `stop` which connects back, creating a logical loop.

**File:** `manuscript/chapters/ch19-deployment.md`
**Fix:** Remove the cycle. Show `restart` as a separate entry that leads to `stop → start`.

---

---

## Statistics

| Severity | Count |
|----------|-------|
| CRITICAL | 5 |
| MAJOR | 14 |
| MEDIUM | 12 |
| MINOR | 9 |
| **Total** | **40** |

## How to use this file

1. Review each item
2. Mark **[Y]** to approve the fix or **[N]** to skip
3. Return this file — all [Y] items will be applied in a single editing pass

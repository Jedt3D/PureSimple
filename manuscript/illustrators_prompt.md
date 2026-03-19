# Chapter Opening Illustration Prompts

*Editorial cartoon style — Wired / Popular Mechanics / New Yorker.*
*Black and white pen-and-ink, single panel, witty caption.*
*Generated for use with Google Imagen or equivalent AI image generator.*

---

### Chapter 1: Why PureBasic for the Web?
**Main idea:** A PureBasic web app compiles into a single binary that needs nothing else to run — no runtime, no package manager, no dependency graph.
**Comedic angle:** While other developers are performing a ritual of installs, configs, and prayers, the PureBasic developer just copies one file and walks away.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. Three developer desks side by side. Left desk: a frantic developer surrounded by towering stacks of folders labelled "node_modules", "package.json", "package-lock.json", sweating over a laptop with a screaming npm install terminal. Middle desk: another developer performing a ritual around a bonfire of pip install logs, holding a rubber chicken. Right desk: a calm developer in a Hawaiian shirt, feet up on desk, holding up a single floppy disk labelled "app" and sipping coffee, laptop closed. Caption reads: "The entire deployment." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 2: The PureBasic Language
**Main idea:** PureBasic requires `EnableExplicit` — every variable must be declared before use, making the compiler your strictest, most reliable colleague.
**Comedic angle:** The compiler catches typos that dynamic languages let silently destroy your weekend.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. An office scene: a stern compiler character sits behind a desk wearing reading glasses and a judge's robe, holding a red stamp that reads "UNDECLARED VARIABLE". A sheepish developer stands before the desk holding a slip of paper with the code line `coutn = coutn + 1`. The compiler points a long bony finger at the typo. On the wall behind hangs a framed motto: "ENABLEEXPLICIT — No Exceptions." A wastebasket overflows with crumpled Python scripts. Caption reads: "The compiler found it. The runtime would have waited until Friday night." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 3: The Toolchain
**Main idea:** The PureBasic toolchain is one compiler, no package manager, and a `-k` flag for instant syntax checking.
**Comedic angle:** The entire build toolchain fits in one command, while modern JavaScript developers manage separate compilers, bundlers, transpilers, linters, and formatters just to say "Hello, World."

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. Split panel: LEFT SIDE shows a lone developer at a clean desk typing a single command into a terminal — `pbcompiler main.pb -o app` — with a satisfied expression and a steaming coffee mug. RIGHT SIDE shows a different developer buried under an avalanche of tools: boxes labelled "webpack", "babel", "eslint", "prettier", "vite", "rollup", "tsc", "jest" are stacked precariously overhead while they frantically read a config file. Caption reads: "You should try our build pipeline." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 4: HTTP Fundamentals
**Main idea:** HTTP is a stateless request-response protocol — one message in, one message out, and the server immediately forgets you exist.
**Comedic angle:** HTTP's amnesia is a feature, not a bug — but it makes for a deeply awkward conversation.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A formal reception desk with a sign reading "SERVER" above it. A visitor (labelled "Browser") approaches and says: "Hi, I was just here. You gave me a cookie." The server receptionist, wearing a blank expression and holding a sign reading "200 OK", replies: "I'm sorry, I have absolutely no memory of that." A single cookie sits on the counter. The lobby wall displays framed status codes: "404 — Not My Problem", "500 — My Problem", "301 — I Moved." Caption reads: "HTTP: Technically correct. Deeply unsatisfying." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 5: Routing
**Main idea:** A router matches incoming URL patterns to handler functions — the framework's version of an air traffic controller directing requests to the right runway.
**Comedic angle:** Every route is a contract. Break the pattern, and the plane has nowhere to land.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. An air traffic control tower scene. An exhausted controller sits at a radar screen covered in URLs: "/api/users/:id", "/posts/*", "/health". Three aircraft approach in the background, each labelled "GET", "POST", and "DELETE". The controller guides one plane toward a runway sign reading "Handler". A plane labelled "GET /undefined" circles overhead with a "404" banner trailing behind it. Caption reads: "Route not found. Pilot has been circling since Tuesday." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 6: The Request Context
**Main idea:** The `RequestContext` is a single struct that every request carries through the entire handler chain — containing request data, response state, parameters, cookies, session, and a key-value store.
**Comedic angle:** One backpack, twenty-five pockets, and the developer who insists they don't need half of them until the moment they desperately do.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A hiker entering an office through a revolving door, wearing an enormous, comically overstuffed backpack labelled "RequestContext". Pockets are labelled with tiny tags: "Method", "Path", "Body", "Cookie", "SessionID", "StoreKeys", "Aborted", "HandlerIndex", etc. A colleague at a desk watches the backpack squeeze through the door, saying: "New guy carries everything with him." The hiker replies: "It's one struct." Caption reads: "Pre-allocated per thread. Reset per request. Never lost." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 7: Middleware
**Main idea:** Middleware is an "onion model" of functions that wrap every request — each layer does work before passing control inward, then does more work on the way back out.
**Comedic angle:** Like airport security, everyone must pass through it, nobody enjoys it, and it exists to catch the one thing that would ruin everyone's day.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. An airport security scene with a long queue of passengers labelled "HTTP Requests". The security checkpoints are labelled in order: "Logger", "Recovery", "BasicAuth", "CSRF" — each staffed by a bored agent in uniform. At the very end of the line stands a tiny booth labelled "Your Handler". A single passenger who bypassed the line is being escorted out by a large bouncer labelled "Abort()". Caption reads: "Middleware: Nobody enjoys it. Nobody removes it." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 8: Request Binding
**Main idea:** Request binding extracts structured data from URLs, query strings, form submissions, and JSON bodies — turning raw HTTP bytes into typed values your handler can actually use.
**Comedic angle:** Without binding, reading request data by hand is technically possible the same way peeling a potato with a Swiss Army knife is technically possible.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. Two developers sit at side-by-side desks. LEFT desk: a developer using a proper peeler (labelled "Binding::Query") to neatly peel a potato in one smooth motion, looking relaxed. RIGHT desk: a developer hunched over a potato using a Swiss Army knife, tongue out in concentration, surrounded by scattered peel fragments and a manual titled "Mid(), FindString(), StringField() — The Complete Guide." Caption reads: "You could parse it yourself. You could also be here all afternoon." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 9: Response Rendering
**Main idea:** The Rendering module provides seven procedures — JSON, HTML, Text, Status, Redirect, File, and Render — that write the server's response with no buffering, no builder objects, just a single function call.
**Comedic angle:** Seven procedures that cover everything, in contrast to building a PDF which, as the chapter notes, is "the polar opposite."

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A short-order cook stands at a diner counter behind a menu board listing exactly seven items: "JSON", "HTML", "Text", "Status", "Redirect", "File", "Render". The cook confidently serves a plate labelled "200 OK" across the counter to a waiting browser character. On one side, a developer at a neighboring counter is attempting to hand-fold a tiny origami PDF, surrounded by crumpled paper and a 400-page manual. Caption reads: "Seven procedures. Pick one. No configuration necessary." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 10: Route Groups
**Main idea:** Route groups bundle a URL prefix and shared middleware so every route inside the group automatically inherits both — define the policy once, and all routes follow it.
**Comedic angle:** Forget to add the auth middleware to one admin route, and you've left the back door unlocked in production.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A large office building cross-section: the left wing is labelled "/admin" and has a burly bouncer at the entrance marked "BasicAuth Middleware", checking IDs. Every door inside the wing has a matching lock. The right wing is labelled "/api/v1" with a sign: "Rate Limiter on Duty." In the basement, a tiny unlabelled door is wide open with a sign reading "POST /admin/delete — oops, no middleware." A lone server monitor displays a blinking "BREACH" alert. Caption reads: "The one route you forgot." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 11: PureJinja Templates
**Main idea:** PureJinja is a Jinja-compatible template engine written in PureBasic — it speaks Python syntax but executes at compiled C speed.
**Comedic angle:** A template engine that Python developers can read without learning anything new, running in a language Python developers have never heard of.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A magician on a stage holds up a template file showing familiar Jinja syntax: `{{ title }}`, `{% for post in posts %}`. With one hand the magician gestures to a CPU gauge labelled "C SPEED" pegged in the red. The audience, a mix of confused Python and JavaScript developers, leans forward squinting at the code. One whispers to another: "That's... Jinja?" The other replies: "In PureBasic." Caption reads: "Same syntax. Different compiler. Considerably fewer dependencies." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 12: Building an HTML Application
**Main idea:** A complete HTML web app in PureSimple follows a simple directory layout — one source file, one templates folder, one static folder — and fits in 106 lines.
**Comedic angle:** The framework convention is simple enough that your future self, six months from now, will still understand it without reading any documentation.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A developer holds up a single manila folder with three tabs: "main.pb", "templates/", "static/" — the entire project structure, neat and labeled. Behind the developer, through a window, a rival developer is drowning in an avalanche of folders — "src/", "dist/", "build/", "public/", "assets/", "lib/", "node_modules/" — each folder containing more sub-folders. A clock on the wall reads "6 Months Later" on the first panel. Caption reads: "Future you will know exactly where everything is." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 13: SQLite Integration
**Main idea:** PureBasic ships SQLite compiled into its standard library — calling `UseSQLiteDatabase()` makes the database engine part of your binary with no external server, socket, or configuration.
**Comedic angle:** The developer spent twenty minutes debugging blank pages before discovering the database handle was zero — silent failures are the best kind.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A developer stares at a completely blank web page on their monitor, expression shifting from confusion to dawning horror. A tiny thought bubble reveals the bug: `db = 0`. On the desk beside them, a note reads "Check your handle!!" A framed poster on the wall shows the lifecycle: "Open → Check for zero → Query → Profit." In the background, a server room sign reads "No PostgreSQL. No MySQL. No configuration files." Caption reads: "Twenty minutes. It was zero the whole time." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 14: Database Patterns
**Main idea:** The repository pattern isolates all SQL behind a module boundary so handlers never see a SQL string — one module to fix when the schema changes, not thirty handlers.
**Comedic angle:** Writing SQL directly in handlers is like juggling running chainsaws — impressive for about thirty seconds.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A street performer in a developer's hoodie juggles three running chainsaws labelled "SELECT * FROM posts", "INSERT INTO posts VALUES (?)", and "DELETE FROM posts WHERE slug=?". A small crowd of horrified spectators watches. To the side, a calm developer sits behind a clean booth labelled "PostRepo Module" offering a tidy menu card reading "FindAll / FindBySlug / Create / Update / Delete". Caption reads: "The SQL stays in the repository. The chainsaws stay in the street." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 15: Cookies and Sessions
**Main idea:** HTTP is stateless by design — cookies and sessions give it the illusion of memory, like a hotel room key and a guest register at a desk where the staff changes every thirty seconds.
**Comedic angle:** The server's amnesia is architecturally necessary but interpersonally exhausting.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A hotel reception desk with a revolving door of identical-looking receptionists rapidly cycling through (representing stateless requests). A guest approaches one holding up a tiny cookie labelled "session_id=abc123". The receptionist beams: "Welcome back! Room 42, Mr. Admin." The guest looks relieved. Through a window, a parallel guest without a cookie approaches a different receptionist who holds up a sign: "Who are you, exactly?" Caption reads: "The cookie remembers so the server doesn't have to." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 16: Authentication
**Main idea:** Basic Auth sends a Base64-encoded username and password in every request — it is encoding, not encryption, and anyone watching unencrypted traffic can decode it in three seconds.
**Comedic angle:** Developers who think internal tools don't need HTTPS have not yet met their curious colleagues with Wireshark.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. An office hallway scene: a developer tapes a sign on a server room door reading "ADMIN PANEL — Basic Auth Protected. No HTTPS needed, it's internal." Around the corner, crouched behind a potted plant with a laptop, sits a colleague running Wireshark. The Wireshark screen clearly displays in large text: "admin:s3cret-passw0rd". The eavesdropping colleague looks back at the reader with a knowing expression. Caption reads: "Base64 is encoding. It is not encryption. Your colleagues know the difference." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 17: CSRF Protection
**Main idea:** A CSRF attack tricks your browser into submitting a forged request to a site you're already logged into — invisible, silent, and entirely preventable with a random token the attacker cannot guess.
**Comedic angle:** The attack is embarrassingly simple. The defense is also embarrassingly simple. The only required ingredient is remembering to implement it.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A browser window shows a cheerful cat photo website. Hidden behind the cat photo, a tiny shadowy figure labelled "Attacker" operates a hand puppet shaped like a browser, puppeteering it to fill out a bank transfer form. The real browser looks down at its hands in confusion, saying: "Did I just... do that?" A velvet rope barrier labelled "CSRF Token Validation" stands between the puppet and the bank form, with a bouncer holding up a clipboard checking tokens. Caption reads: "The cat was not free. There were hidden terms." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 18: Configuration and Logging
**Main idea:** Twelve-factor app methodology: store configuration in `.env` files, read it at startup, and never hard-code values — the same binary runs everywhere, only the config file changes.
**Comedic angle:** Hard-coding your database path is like tattooing your WiFi password on your forehead — it works right up until you need to change something.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A developer sits in a tattoo parlor chair, wincing as a tattoo artist inscribes "DB_PATH=/Users/dev/local/test.db" across their forearm. The artist, needle in hand, pauses to ask: "You sure about this?" In the background, a sensible colleague holds up a tidy index card labelled ".env" with values neatly written in pencil, pointing to an eraser on their desk. Caption reads: "Configuration in the environment. Not on your person." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 19: Deployment
**Main idea:** Deploying a PureSimple app means compiling one binary, copying it to a server, and running it — the deploy script is 78 lines of bash, the rollback script is 51 lines, total.
**Comedic angle:** Compare this to a typical Kubernetes deployment manifest, a Dockerfile, a CI/CD pipeline YAML, and the three hours you spent debugging why staging has a different libssl than production.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. Two moving trucks outside server buildings. LEFT TRUCK: one developer hops off and carries a single small box labelled "app" (one binary) through the front door. The entire move takes one panel. RIGHT TRUCK: an armada of trucks stretches to the horizon, each carrying containers labelled "Dockerfile", "Kubernetes manifest", "CI/CD YAML", "Helm chart", "libssl", "node 18.2.1", "node 18.2.2 (oops)". A forklift is involved. Chaos reigns. Caption reads: "Deploy day." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 20: Testing
**Main idea:** PureSimple's test harness uses macros instead of procedures so that failing assertions report the exact file and line number in your test code — 264 assertions, all must pass, no skips.
**Comedic angle:** In a compiled language, tests collapse five steps into one — because there's no browser to open and no "let me just check it manually."

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A scoreboard on a gymnasium wall reads "264 of 264 PASSED" in bold letters. A developer sits in bleachers reading a book, entirely relaxed, while the test runner on a laptop next to them flickers through assertions at high speed. On the other side of the gym, a different developer has assembled an elaborate obstacle course involving a browser, a staging server, a notepad, and a checklist — just to verify one function works. Caption reads: "Compile. Run. Done. The browser is not involved." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 21: Building a REST API
**Main idea:** Building a complete JSON CRUD REST API in PureSimple starts with a scaffold script that generates a ready-to-compile project in one command — no generators pulling half the internet.
**Comedic angle:** One bash script creates your entire project structure. The contrast with npm create, yeoman generators, and CLI wizards requiring configuration configuration is left as an exercise for the reader.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A developer types `./new-project.sh todo` into a terminal. The terminal immediately produces a tidy, labeled stack of files: "main.pb", ".env", ".gitignore", "templates/index.html" — everything neatly arranged on the desk. The developer looks mildly surprised by the speed. Next to them, another developer is on step 7 of 23 of an npm project creation wizard on their screen, answering questions like "Would you like to configure ESLint now? [Y/n]" while surrounded by empty coffee cups. Caption reads: "Step 1: `./new-project.sh todo`. Step 2: There is no step 2." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 22: Building a Blog — Wild & Still
**Main idea:** A production blog with fifteen routes, a SQLite database, admin CRUD, and two UI themes — 596 lines of PureBasic, one binary, running on a real server.
**Comedic angle:** 596 lines. Your React app has more code in its webpack config.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. Two developers at a tech conference comparing notes. LEFT developer holds up a single index card labelled "main.pb — 596 lines. Runs in production." RIGHT developer wrestles with a comically oversized accordion-fold printout of their webpack.config.js, which unfolds across the aisle and into the hallway, blocking conference attendees. The printout is labelled "Just the config." A conference badge on the left developer's lanyard reads: "One Binary." Caption reads: "596 lines. Router, templates, database, auth, admin panel, deployment scripts. Not counting the webpack config, because there isn't one." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

---

### Chapter 23: Multi-Database Support
**Main idea:** The `DBConnect` module abstracts database *connections* over SQLite, PostgreSQL, and MySQL using DSN strings — swap databases via a one-line `.env` change, without touching application code.
**Comedic angle:** Every database abstraction layer promises "swap your database with one config change" and never delivers — except this one is honest about what it abstracts and what it doesn't.

**Image prompt:**
Black and white editorial cartoon, pen-and-ink line art, Wired magazine style, single panel, clean crosshatching, speech bubbles with hand-lettered text. A single universal power adapter (labelled "DBConnect::Open") sits on a desk. Three plugs dangle from it, labelled "SQLite", "PostgreSQL", and "MySQL". A developer simply edits one line in a `.env` file, switching `DB_DSN=sqlite:app.db` to `DB_DSN=postgres://user:pass@db:5432/app`. The outlet on the wall stays exactly the same. Beside this scene, a graveyard of discarded ORM boxes: "Hibernate", "SQLAlchemy", "ActiveRecord" — each with the epitaph "Promised everything." Caption reads: "The abstraction solves the problem it claims to solve. No more. No less." Style: New Yorker cartoon meets tech magazine illustration, no color, white background, bold outlines, expressive characters.

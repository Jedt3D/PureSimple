; examples/massively/main.pb — "Wild & Still" nature photography blog
;
; A production-quality example showcasing the full PureSimple stack:
;   - SQLite DB with migrations + seed data
;   - Public routes: index, post, contact form
;   - Admin group: BasicAuth + full CRUD
;   - PureJinja templates (Massively theme + Tabler admin)
;   - Config via .env
;
; Compile:
;   export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"
;   $PUREBASIC_HOME/compilers/pbcompiler examples/massively/main.pb -o massively_app
; Run:
;   ./massively_app
; Then visit http://localhost:8080/

EnableExplicit

XIncludeFile "../../src/PureSimple.pb"

; ---- Globals ---------------------------------------------------------------

Global _db.i                      ; SQLite database handle
Global _tplDir.s = "examples/massively/templates/"

; ---- Helpers ---------------------------------------------------------------

; SafeVal: replace Tab (Chr(9)) with space before Ctx::Set.
; The KV store uses Chr(9) as delimiter — a tab in a value corrupts parsing.
Procedure.s SafeVal(s.s)
  ProcedureReturn ReplaceString(s, Chr(9), " ")
EndProcedure

; SetSiteVars: inject site_name and tagline into every render context.
Procedure SetSiteVars(*C.RequestContext)
  Protected siteName.s = "Wild & Still"
  Protected tagline.s  = "One frame. One story."

  If DB::Query(_db, "SELECT value FROM site_settings WHERE key = 'site_name'")
    If DB::NextRow(_db) : siteName = DB::GetStr(_db, 0) : EndIf
    DB::Done(_db)
  EndIf
  If DB::Query(_db, "SELECT value FROM site_settings WHERE key = 'tagline'")
    If DB::NextRow(_db) : tagline = DB::GetStr(_db, 0) : EndIf
    DB::Done(_db)
  EndIf
  Ctx::Set(*C, "site_name", SafeVal(siteName))
  Ctx::Set(*C, "tagline",   SafeVal(tagline))
EndProcedure

; PostsToStr: build a newline-delimited, pipe-separated list of published posts.
; Each line: id|slug|title|published_at|photo_url|excerpt|published
Procedure.s PostsToStr()
  Protected result.s = ""
  If DB::Query(_db, "SELECT id, slug, title, published_at, photo_url, excerpt, published" +
                    " FROM posts WHERE published = 1 ORDER BY published_at DESC")
    While DB::NextRow(_db)
      result + SafeVal(DB::GetStr(_db, 0)) + "|" +
               SafeVal(DB::GetStr(_db, 1)) + "|" +
               SafeVal(DB::GetStr(_db, 2)) + "|" +
               SafeVal(DB::GetStr(_db, 3)) + "|" +
               SafeVal(DB::GetStr(_db, 4)) + "|" +
               SafeVal(DB::GetStr(_db, 5)) + "|" +
               SafeVal(DB::GetStr(_db, 6)) + Chr(10)
    Wend
    DB::Done(_db)
  EndIf
  ProcedureReturn result
EndProcedure

; AllPostsToStr: same as PostsToStr but includes drafts (for admin).
Procedure.s AllPostsToStr()
  Protected result.s = ""
  If DB::Query(_db, "SELECT id, slug, title, published_at, photo_url, excerpt, published" +
                    " FROM posts ORDER BY published_at DESC")
    While DB::NextRow(_db)
      result + SafeVal(DB::GetStr(_db, 0)) + "|" +
               SafeVal(DB::GetStr(_db, 1)) + "|" +
               SafeVal(DB::GetStr(_db, 2)) + "|" +
               SafeVal(DB::GetStr(_db, 3)) + "|" +
               SafeVal(DB::GetStr(_db, 4)) + "|" +
               SafeVal(DB::GetStr(_db, 5)) + "|" +
               SafeVal(DB::GetStr(_db, 6)) + Chr(10)
    Wend
    DB::Done(_db)
  EndIf
  ProcedureReturn result
EndProcedure

; ContactsToStr: newline + pipe delimited contact rows for admin.
; Each line: id|name|email|message|submitted_at|is_read
Procedure.s ContactsToStr()
  Protected result.s = ""
  If DB::Query(_db, "SELECT id, name, email, message, submitted_at, is_read" +
                    " FROM contacts ORDER BY submitted_at DESC")
    While DB::NextRow(_db)
      result + SafeVal(DB::GetStr(_db, 0)) + "|" +
               SafeVal(DB::GetStr(_db, 1)) + "|" +
               SafeVal(DB::GetStr(_db, 2)) + "|" +
               SafeVal(DB::GetStr(_db, 3)) + "|" +
               SafeVal(DB::GetStr(_db, 4)) + "|" +
               SafeVal(DB::GetStr(_db, 5)) + Chr(10)
    Wend
    DB::Done(_db)
  EndIf
  ProcedureReturn result
EndProcedure

; UnreadCount: count unread contacts.
Procedure.s UnreadCount()
  Protected n.s = "0"
  If DB::Query(_db, "SELECT COUNT(*) FROM contacts WHERE is_read = 0")
    If DB::NextRow(_db) : n = DB::GetStr(_db, 0) : EndIf
    DB::Done(_db)
  EndIf
  ProcedureReturn n
EndProcedure

; NowStr: current date as YYYY-MM-DD string.
Procedure.s NowStr()
  ProcedureReturn FormatDate("%yyyy-%mm-%dd", Date())
EndProcedure

; ---- Middleware wrappers ---------------------------------------------------
; PureBasic can't take @Module::Proc() addresses at the program level with
; EnableExplicit. Thin local wrappers solve this cleanly.

Procedure _LoggerMW(*C.RequestContext)
  Logger::Middleware(*C)
EndProcedure

Procedure _RecoveryMW(*C.RequestContext)
  Recovery::Middleware(*C)
EndProcedure

Procedure _BasicAuthMW(*C.RequestContext)
  BasicAuth::Middleware(*C)
EndProcedure

; ---- DB Migrations ---------------------------------------------------------

Procedure InitDB()
  Protected sql.s
  Protected cols.s = " (slug, title, body, excerpt, photo_url, photo_credit, photo_license, photo_link, author, published_at, created_at, updated_at, published)"
  Protected nl.s   = Chr(10) + Chr(10)

  ; v1: posts table
  sql = "CREATE TABLE IF NOT EXISTS posts ("
  sql + "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
  sql + "  slug TEXT UNIQUE NOT NULL,"
  sql + "  title TEXT NOT NULL,"
  sql + "  body TEXT NOT NULL,"
  sql + "  excerpt TEXT NOT NULL,"
  sql + "  photo_url TEXT NOT NULL,"
  sql + "  photo_credit TEXT NOT NULL,"
  sql + "  photo_license TEXT NOT NULL DEFAULT 'Pexels License',"
  sql + "  photo_link TEXT NOT NULL,"
  sql + "  author TEXT NOT NULL DEFAULT 'Jedt Sitth',"
  sql + "  published_at TEXT NOT NULL,"
  sql + "  created_at TEXT NOT NULL,"
  sql + "  updated_at TEXT NOT NULL,"
  sql + "  published INTEGER NOT NULL DEFAULT 1)"
  DB::AddMigration(1, sql)

  ; v2: contacts table
  sql = "CREATE TABLE IF NOT EXISTS contacts ("
  sql + "  id INTEGER PRIMARY KEY AUTOINCREMENT,"
  sql + "  name TEXT NOT NULL,"
  sql + "  email TEXT NOT NULL,"
  sql + "  message TEXT NOT NULL,"
  sql + "  submitted_at TEXT NOT NULL,"
  sql + "  is_read INTEGER NOT NULL DEFAULT 0)"
  DB::AddMigration(2, sql)

  ; v3: site_settings table
  sql = "CREATE TABLE IF NOT EXISTS site_settings ("
  sql + "  key TEXT PRIMARY KEY,"
  sql + "  value TEXT NOT NULL)"
  DB::AddMigration(3, sql)

  ; v4: seed site_name
  DB::AddMigration(4, "INSERT OR IGNORE INTO site_settings (key, value) VALUES ('site_name', 'Wild & Still')")

  ; v5: seed tagline
  DB::AddMigration(5, "INSERT OR IGNORE INTO site_settings (key, value) VALUES ('tagline', 'One frame. One story.')")

  ; v6: seed post 1 — The Heron's Patience
  sql = "INSERT OR IGNORE INTO posts" + cols + " VALUES ("
  sql + " 'herons-patience',"
  sql + " 'The Heron''s Patience',"
  sql + " 'It was barely four in the morning when I waded into the shallows. The air held that cool, glassy quality you only find in the hour before the birds decide the world is safe."
  sql + nl
  sql + "I had been watching this particular grey heron for three weeks. Every morning it stood at the same bend in the canal, a stone-grey statue in the grey water, and I had never once seen it move with urgency. It did not hunt. It waited."
  sql + nl
  sql + "There is a kind of courage in that stillness. The heron does not worry that the fish will not come. It simply holds its position and trusts the river."
  sql + nl
  sql + "I pressed the shutter at the exact moment a thin band of rose appeared above the tree line. The heron did not flinch. The water did not ripple. Only the light changed."
  sql + nl
  sql + "That is the frame I had been waiting three weeks to take. One second of perfect alignment between light, bird, and my own held breath.',"
  sql + " 'Three weeks of predawn wading for a single second of perfect light.',"
  sql + " 'https://images.pexels.com/photos/158251/heron-bird-animal-lake-158251.jpeg',"
  sql + " 'Pixabay',"
  sql + " 'Pexels License',"
  sql + " 'https://www.pexels.com/photo/158251/',"
  sql + " 'Jedt Sitth', '2026-01-15', '2026-01-15', '2026-01-15', 1)"
  DB::AddMigration(6, sql)

  ; v7: seed post 2 — Doi Inthanon in the Mist
  sql = "INSERT OR IGNORE INTO posts" + cols + " VALUES ("
  sql + " 'doi-inthanon-mist',"
  sql + " 'Doi Inthanon in the Mist',"
  sql + " 'The road to Thailand''s highest summit disappears into white by kilometre 24."
  sql + nl
  sql + "I had driven up from Chiang Mai in darkness, headlights cutting through a fog that rolled down the mountain like something alive. By the time I reached the summit plateau, the world had contracted to a circle of about fifteen metres."
  sql + nl
  sql + "Most photographers turn around at this point. I unpacked the tripod."
  sql + nl
  sql + "The thing about shooting in dense fog is that it flattens everything into a single plane. Distance loses its meaning. A pine tree three metres away can look like a painting of a pine tree fifty metres away. The eye has nothing to anchor to, and that disorientation is exactly what I wanted the viewer to feel."
  sql + nl
  sql + "I waited two hours. The mist never lifted. I came home with the photograph I wanted: a forest that looks like a memory, indistinct at the edges, completely present at the centre.',"
  sql + " 'What a fog-bound summit teaches you about depth and disorientation.',"
  sql + " 'https://images.pexels.com/photos/2559941/pexels-photo-2559941.jpeg',"
  sql + " 'Johannes Plenio',"
  sql + " 'Pexels License',"
  sql + " 'https://www.pexels.com/photo/2559941/',"
  sql + " 'Jedt Sitth', '2026-01-28', '2026-01-28', '2026-01-28', 1)"
  DB::AddMigration(7, sql)

  ; v8: seed post 3 — Rain Season Macro
  sql = "INSERT OR IGNORE INTO posts" + cols + " VALUES ("
  sql + " 'rain-season-macro',"
  sql + " 'Rain Season Macro',"
  sql + " 'The monsoon arrived on a Tuesday, as it always does in Chiang Rai, without announcement."
  sql + nl
  sql + "Within an hour the garden was jewelled. Every leaf held its own small world: a bead of water that contained, in perfect miniature, a reflection of the sky above it."
  sql + nl
  sql + "Macro photography is an act of translation. You take something the eye slides past and you make it impossible to ignore. A vein in a leaf. The hinge of an insect''s leg. The surface tension of a raindrop deciding whether or not to fall."
  sql + nl
  sql + "I shot at 1:1 magnification, the lens almost touching the leaf. Depth of field collapsed to a sliver — perhaps two millimetres. Everything else dissolved into a soft green suggestion."
  sql + nl
  sql + "The rain continued for six hours. I worked for four of them, moving from leaf to leaf with the patience of someone who has finally learned that the smallest things contain the most light.',"
  sql + " 'Monsoon season and the discipline of seeing at 1:1 magnification.',"
  sql + " 'https://images.pexels.com/photos/931177/pexels-photo-931177.jpeg',"
  sql + " 'Pixabay',"
  sql + " 'Pexels License',"
  sql + " 'https://www.pexels.com/photo/931177/',"
  sql + " 'Jedt Sitth', '2026-02-10', '2026-02-10', '2026-02-10', 1)"
  DB::AddMigration(8, sql)

  ; v9: seed post 4 — Fireflies Over the Rice Fields
  sql = "INSERT OR IGNORE INTO posts" + cols + " VALUES ("
  sql + " 'fireflies-rice-fields',"
  sql + " 'Fireflies Over the Rice Fields',"
  sql + " 'There is a village near Lampang where the rice fields produce fireflies in June."
  sql + nl
  sql + "I had heard about this place from a farmer at a market in the city. He described it the way people describe childhood memories: imprecisely, with feeling, without GPS coordinates. It took me two evenings of wrong turns to find it."
  sql + nl
  sql + "The fireflies began at dusk. Not all at once — first one, then three, then suddenly hundreds threading between the green stalks in the darkness, each one its own small lantern."
  sql + nl
  sql + "Long exposure photography turns time into texture. A thirty-second exposure of fireflies becomes a map of their movement: curved lines of cold light suspended in dark air."
  sql + nl
  sql + "I made eighteen exposures over two hours. The farmer''s description had been exactly right: imprecise, full of feeling, and completely accurate about the things that matter.',"
  sql + " 'A wrong-turn village and the long-exposure maps of firefly light.',"
  sql + " 'https://images.pexels.com/photos/1108572/pexels-photo-1108572.jpeg',"
  sql + " 'Aleksey Kuprikov',"
  sql + " 'Pexels License',"
  sql + " 'https://www.pexels.com/photo/1108572/',"
  sql + " 'Jedt Sitth', '2026-02-24', '2026-02-24', '2026-02-24', 1)"
  DB::AddMigration(9, sql)

  ; v10: seed post 5 — The Last Light at Phi Phi
  sql = "INSERT OR IGNORE INTO posts" + cols + " VALUES ("
  sql + " 'last-light-phi-phi',"
  sql + " 'The Last Light at Phi Phi',"
  sql + " 'You''ve seen the photographs. Everyone has. The limestone cliffs of Phi Phi at golden hour are one of the most photographed subjects in Southeast Asia."
  sql + nl
  sql + "I didn''t come to make a better version of those photographs. I came to understand why people keep making them."
  sql + nl
  sql + "The answer, I think, is that Phi Phi at last light is genuinely unreasonable. The colour that the sun produces in that final fifteen minutes — somewhere between amber and rose, hitting vertical limestone at a nearly horizontal angle — is a colour that the eye knows is temporary."
  sql + nl
  sql + "That is what all the photographs are attempting to hold: not the cliffs, not the sea, but the knowledge that this specific quality of light exists for exactly fifteen minutes and will not return in quite the same way."
  sql + nl
  sql + "I made one frame. I put the camera down and watched the rest with my eyes. Some things are better stored in the body than on a card.',"
  sql + " 'Why the most-photographed cliff in Thailand still stops you cold at golden hour.',"
  sql + " 'https://images.pexels.com/photos/3601425/pexels-photo-3601425.jpeg',"
  sql + " 'Humphrey Muleba',"
  sql + " 'Pexels License',"
  sql + " 'https://www.pexels.com/photo/3601425/',"
  sql + " 'Jedt Sitth', '2026-03-10', '2026-03-10', '2026-03-10', 1)"
  DB::AddMigration(10, sql)

  ; Open (or create) the database
  _db = DB::Open("examples/massively/db/blog.db")
  If _db = 0
    PrintN("ERROR: Cannot open database")
    End 1
  EndIf

  If Not DB::Migrate(_db)
    PrintN("ERROR: Migration failed: " + DB::Error(_db))
    End 1
  EndIf
EndProcedure

; ---- Public Handlers -------------------------------------------------------

Procedure IndexHandler(*C.RequestContext)
  SetSiteVars(*C)
  Ctx::Set(*C, "active_page", "home")
  Ctx::Set(*C, "posts_data", PostsToStr())
  Rendering::Render(*C, "index.html", _tplDir)
EndProcedure

Procedure PostHandler(*C.RequestContext)
  Protected slug.s = Binding::Param(*C, "slug")

  DB::BindStr(_db, 0, slug)
  If Not DB::Query(_db,
    "SELECT title, body, excerpt, photo_url, photo_credit, photo_license, photo_link," +
    " author, published_at FROM posts WHERE slug = ? AND published = 1")
    Engine::HandleNotFound(*C)
    ProcedureReturn
  EndIf

  If Not DB::NextRow(_db)
    DB::Done(_db)
    Engine::HandleNotFound(*C)
    ProcedureReturn
  EndIf

  SetSiteVars(*C)
  Ctx::Set(*C, "title",         SafeVal(DB::GetStr(_db, 0)))
  Ctx::Set(*C, "body",          SafeVal(DB::GetStr(_db, 1)))
  Ctx::Set(*C, "excerpt",       SafeVal(DB::GetStr(_db, 2)))
  Ctx::Set(*C, "photo_url",     SafeVal(DB::GetStr(_db, 3)))
  Ctx::Set(*C, "photo_credit",  SafeVal(DB::GetStr(_db, 4)))
  Ctx::Set(*C, "photo_license", SafeVal(DB::GetStr(_db, 5)))
  Ctx::Set(*C, "photo_link",    SafeVal(DB::GetStr(_db, 6)))
  Ctx::Set(*C, "author",        SafeVal(DB::GetStr(_db, 7)))
  Ctx::Set(*C, "date",          SafeVal(DB::GetStr(_db, 8)))
  DB::Done(_db)

  Rendering::Render(*C, "post.html", _tplDir)
EndProcedure

Procedure ContactGetHandler(*C.RequestContext)
  SetSiteVars(*C)
  Ctx::Set(*C, "active_page", "contact")
  Rendering::Render(*C, "contact.html", _tplDir)
EndProcedure

Procedure ContactPostHandler(*C.RequestContext)
  Protected name.s    = SafeVal(Trim(Binding::PostForm(*C, "name")))
  Protected email.s   = SafeVal(Trim(Binding::PostForm(*C, "email")))
  Protected message.s = SafeVal(Trim(Binding::PostForm(*C, "message")))
  Protected now.s     = NowStr()

  If name = "" Or email = "" Or message = ""
    SetSiteVars(*C)
    Ctx::Set(*C, "active_page", "contact")
    Ctx::Set(*C, "error", "Please fill in all fields.")
    Rendering::Render(*C, "contact.html", _tplDir)
    ProcedureReturn
  EndIf

  DB::BindStr(_db, 0, name)
  DB::BindStr(_db, 1, email)
  DB::BindStr(_db, 2, message)
  DB::BindStr(_db, 3, now)
  DB::Exec(_db, "INSERT INTO contacts (name, email, message, submitted_at) VALUES (?, ?, ?, ?)")

  Rendering::Redirect(*C, "/contact/ok")
EndProcedure

Procedure ContactOkHandler(*C.RequestContext)
  SetSiteVars(*C)
  Ctx::Set(*C, "active_page", "contact")
  Rendering::Render(*C, "contact_ok.html", _tplDir)
EndProcedure

Procedure HealthHandler(*C.RequestContext)
  Rendering::JSON(*C, ~"{\"status\":\"ok\"}")
EndProcedure

Procedure NotFoundHandler(*C.RequestContext)
  SetSiteVars(*C)
  Rendering::Render(*C, "404.html", _tplDir)
  *C\StatusCode = 404
EndProcedure

; ---- Admin Handlers --------------------------------------------------------

Procedure AdminDashHandler(*C.RequestContext)
  Protected totalPosts.s = "0", publishedPosts.s = "0"

  If DB::Query(_db, "SELECT COUNT(*) FROM posts")
    If DB::NextRow(_db) : totalPosts = DB::GetStr(_db, 0) : EndIf
    DB::Done(_db)
  EndIf
  If DB::Query(_db, "SELECT COUNT(*) FROM posts WHERE published = 1")
    If DB::NextRow(_db) : publishedPosts = DB::GetStr(_db, 0) : EndIf
    DB::Done(_db)
  EndIf

  Ctx::Set(*C, "active_admin",    "dashboard")
  Ctx::Set(*C, "total_posts",     totalPosts)
  Ctx::Set(*C, "published_posts", publishedPosts)
  Ctx::Set(*C, "unread_count",    UnreadCount())
  Rendering::Render(*C, "admin/dashboard.html", _tplDir)
EndProcedure

Procedure AdminPostsHandler(*C.RequestContext)
  Ctx::Set(*C, "active_admin",  "posts")
  Ctx::Set(*C, "posts_data",    AllPostsToStr())
  Ctx::Set(*C, "unread_count",  UnreadCount())
  Rendering::Render(*C, "admin/posts.html", _tplDir)
EndProcedure

Procedure AdminPostNewHandler(*C.RequestContext)
  Ctx::Set(*C, "active_admin",   "posts")
  Ctx::Set(*C, "form_title",     "New Post")
  Ctx::Set(*C, "form_action",    "/admin/posts/new")
  Ctx::Set(*C, "submit_label",   "Create Post")
  Ctx::Set(*C, "post_title",     "")
  Ctx::Set(*C, "post_slug",      "")
  Ctx::Set(*C, "post_excerpt",   "")
  Ctx::Set(*C, "post_body",      "")
  Ctx::Set(*C, "post_photo_url",    "")
  Ctx::Set(*C, "post_photo_credit", "")
  Ctx::Set(*C, "post_photo_link",   "")
  Ctx::Set(*C, "post_published", "1")
  Ctx::Set(*C, "unread_count",   UnreadCount())
  Rendering::Render(*C, "admin/post_form.html", _tplDir)
EndProcedure

Procedure AdminPostCreateHandler(*C.RequestContext)
  Protected title.s       = SafeVal(Trim(Binding::PostForm(*C, "title")))
  Protected slug.s        = SafeVal(Trim(Binding::PostForm(*C, "slug")))
  Protected excerpt.s     = SafeVal(Trim(Binding::PostForm(*C, "excerpt")))
  Protected body.s        = SafeVal(Trim(Binding::PostForm(*C, "body")))
  Protected photoUrl.s    = SafeVal(Trim(Binding::PostForm(*C, "photo_url")))
  Protected photoCredit.s = SafeVal(Trim(Binding::PostForm(*C, "photo_credit")))
  Protected photoLink.s   = SafeVal(Trim(Binding::PostForm(*C, "photo_link")))
  Protected published.s   = Binding::PostForm(*C, "published")
  Protected now.s         = NowStr()

  DB::BindStr(_db, 0, slug)
  DB::BindStr(_db, 1, title)
  DB::BindStr(_db, 2, body)
  DB::BindStr(_db, 3, excerpt)
  DB::BindStr(_db, 4, photoUrl)
  DB::BindStr(_db, 5, photoCredit)
  DB::BindStr(_db, 6, photoLink)
  DB::BindStr(_db, 7, now)
  DB::BindStr(_db, 8, now)
  DB::BindStr(_db, 9, now)
  DB::BindInt(_db, 10, Val(published))
  Protected insertSQL.s = "INSERT INTO posts (slug, title, body, excerpt, photo_url, photo_credit, photo_link,"
  insertSQL + " published_at, created_at, updated_at, published) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  DB::Exec(_db, insertSQL)

  Rendering::Redirect(*C, "/admin/posts")
EndProcedure

Procedure AdminPostEditHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")

  DB::BindStr(_db, 0, id)
  If Not DB::Query(_db,
    "SELECT id, slug, title, body, excerpt, photo_url, photo_credit, photo_link, published" +
    " FROM posts WHERE id = ?")
    Engine::HandleNotFound(*C)
    ProcedureReturn
  EndIf

  If Not DB::NextRow(_db)
    DB::Done(_db)
    Engine::HandleNotFound(*C)
    ProcedureReturn
  EndIf

  Ctx::Set(*C, "active_admin",      "posts")
  Ctx::Set(*C, "form_title",        "Edit Post")
  Ctx::Set(*C, "form_action",       "/admin/posts/" + id + "/edit")
  Ctx::Set(*C, "submit_label",      "Save Changes")
  Ctx::Set(*C, "post_slug",         SafeVal(DB::GetStr(_db, 1)))
  Ctx::Set(*C, "post_title",        SafeVal(DB::GetStr(_db, 2)))
  Ctx::Set(*C, "post_body",         SafeVal(DB::GetStr(_db, 3)))
  Ctx::Set(*C, "post_excerpt",      SafeVal(DB::GetStr(_db, 4)))
  Ctx::Set(*C, "post_photo_url",    SafeVal(DB::GetStr(_db, 5)))
  Ctx::Set(*C, "post_photo_credit", SafeVal(DB::GetStr(_db, 6)))
  Ctx::Set(*C, "post_photo_link",   SafeVal(DB::GetStr(_db, 7)))
  Ctx::Set(*C, "post_published",    SafeVal(DB::GetStr(_db, 8)))
  DB::Done(_db)

  Ctx::Set(*C, "unread_count", UnreadCount())
  Rendering::Render(*C, "admin/post_form.html", _tplDir)
EndProcedure

Procedure AdminPostUpdateHandler(*C.RequestContext)
  Protected id.s          = Binding::Param(*C, "id")
  Protected title.s       = SafeVal(Trim(Binding::PostForm(*C, "title")))
  Protected slug.s        = SafeVal(Trim(Binding::PostForm(*C, "slug")))
  Protected excerpt.s     = SafeVal(Trim(Binding::PostForm(*C, "excerpt")))
  Protected body.s        = SafeVal(Trim(Binding::PostForm(*C, "body")))
  Protected photoUrl.s    = SafeVal(Trim(Binding::PostForm(*C, "photo_url")))
  Protected photoCredit.s = SafeVal(Trim(Binding::PostForm(*C, "photo_credit")))
  Protected photoLink.s   = SafeVal(Trim(Binding::PostForm(*C, "photo_link")))
  Protected published.s   = Binding::PostForm(*C, "published")
  Protected now.s         = NowStr()

  DB::BindStr(_db, 0, title)
  DB::BindStr(_db, 1, slug)
  DB::BindStr(_db, 2, excerpt)
  DB::BindStr(_db, 3, body)
  DB::BindStr(_db, 4, photoUrl)
  DB::BindStr(_db, 5, photoCredit)
  DB::BindStr(_db, 6, photoLink)
  DB::BindInt(_db, 7, Val(published))
  DB::BindStr(_db, 8, now)
  DB::BindStr(_db, 9, id)
  Protected updateSQL.s = "UPDATE posts SET title=?, slug=?, excerpt=?, body=?, photo_url=?, photo_credit=?,"
  updateSQL + " photo_link=?, published=?, updated_at=? WHERE id=?"
  DB::Exec(_db, updateSQL)

  Rendering::Redirect(*C, "/admin/posts")
EndProcedure

Procedure AdminPostDeleteHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  DB::BindStr(_db, 0, id)
  DB::Exec(_db, "DELETE FROM posts WHERE id = ?")
  Rendering::Redirect(*C, "/admin/posts")
EndProcedure

Procedure AdminContactsHandler(*C.RequestContext)
  ; Mark all as read when admin views the inbox
  DB::Exec(_db, "UPDATE contacts SET is_read = 1 WHERE is_read = 0")

  Ctx::Set(*C, "active_admin",   "contacts")
  Ctx::Set(*C, "contacts_data",  ContactsToStr())
  Ctx::Set(*C, "unread_count",   "0")
  Rendering::Render(*C, "admin/contacts.html", _tplDir)
EndProcedure

Procedure AdminContactDeleteHandler(*C.RequestContext)
  Protected id.s = Binding::Param(*C, "id")
  DB::BindStr(_db, 0, id)
  DB::Exec(_db, "DELETE FROM contacts WHERE id = ?")
  Rendering::Redirect(*C, "/admin/contacts")
EndProcedure

; ---- App Boot --------------------------------------------------------------

Engine::NewApp()
Config::Load("examples/massively/.env")
Engine::SetMode(Config::Get("MODE", "debug"))
Log::SetLevel(Log::#LevelInfo)

InitDB()

Engine::Use(@_LoggerMW())
Engine::Use(@_RecoveryMW())

; Custom 404 handler
Engine::SetNotFoundHandler(@NotFoundHandler())

; Public routes
Engine::GET("/",           @IndexHandler())
Engine::GET("/post/:slug", @PostHandler())
Engine::GET("/contact",    @ContactGetHandler())
Engine::POST("/contact",   @ContactPostHandler())
Engine::GET("/contact/ok", @ContactOkHandler())
Engine::GET("/health",     @HealthHandler())

; Admin group — protected by BasicAuth
Define _adminUser.s = Config::Get("ADMIN_USER", "admin")
Define _adminPass.s = Config::Get("ADMIN_PASS", "changeme")
BasicAuth::SetCredentials(_adminUser, _adminPass)
Define adminGrp.PS_RouterGroup
Group::Init(@adminGrp, "/admin")
Group::Use(@adminGrp, @_BasicAuthMW())

Group::GET(@adminGrp,  "/",                   @AdminDashHandler())
Group::GET(@adminGrp,  "/posts",              @AdminPostsHandler())
Group::GET(@adminGrp,  "/posts/new",          @AdminPostNewHandler())
Group::POST(@adminGrp, "/posts/new",          @AdminPostCreateHandler())
Group::GET(@adminGrp,  "/posts/:id/edit",     @AdminPostEditHandler())
Group::POST(@adminGrp, "/posts/:id/edit",     @AdminPostUpdateHandler())
Group::POST(@adminGrp, "/posts/:id/delete",   @AdminPostDeleteHandler())
Group::GET(@adminGrp,  "/contacts",           @AdminContactsHandler())
Group::POST(@adminGrp, "/contacts/:id/delete", @AdminContactDeleteHandler())

Log::Info("Wild & Still starting on :" + Str(Config::GetInt("PORT", 8080)) +
          " [" + Engine::Mode() + "]")
Engine::Run(Config::GetInt("PORT", 8080))

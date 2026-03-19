# 03 — Database

## Schema overview

Five tables, created in order via the migration runner:

| Table | Purpose |
|-------|---------|
| `posts` | Blog posts with photo metadata |
| `contacts` | Contact form submissions |
| `site_settings` | Key/value config (site_name, tagline) |
| `puresimple_migrations` | Migration tracking (auto-created by `DB::Migrate`) |

## The migration runner

PureSimple's `DB::AddMigration(version, sql)` registers a migration.
`DB::Migrate(handle)` creates the tracking table if needed, then runs any
migrations whose version number hasn't been recorded yet.

```purebasic
DB::AddMigration(1, "CREATE TABLE IF NOT EXISTS posts (...)")
DB::AddMigration(2, "CREATE TABLE IF NOT EXISTS contacts (...)")
; ...
_db = DB::Open("examples/massively/db/blog.db")
DB::Migrate(_db)
```

Migrations are **idempotent** — re-running the app on an existing database
skips already-applied migrations. This is safe to call on every boot.

## Posts table columns

| Column | Type | Notes |
|--------|------|-------|
| `id` | INTEGER PK | Auto-increment |
| `slug` | TEXT UNIQUE | URL identifier, e.g. `herons-patience` |
| `title` | TEXT | Display title |
| `body` | TEXT | Full essay, paragraphs separated by `\n\n` |
| `excerpt` | TEXT | One-sentence teaser shown in the post list |
| `photo_url` | TEXT | Pexels image URL (direct link to JPEG) |
| `photo_credit` | TEXT | Photographer name |
| `photo_license` | TEXT | Always "Pexels License" for seed data |
| `photo_link` | TEXT | Pexels photo page URL |
| `author` | TEXT | Default "Jedt Sitth" |
| `published_at` | TEXT | YYYY-MM-DD |
| `published` | INTEGER | 1 = live, 0 = draft |

## Seed data

Migrations v6–v10 insert five posts using `INSERT OR IGNORE INTO posts ...`
so re-running on an existing database doesn't duplicate data.

The seed uses single-quoted strings with PureBasic's `''` escape for literal
apostrophes inside SQL strings (e.g., `'The Heron''s Patience'`).

## Query pattern

```purebasic
; Parameterized SELECT
DB::BindStr(_db, 0, slug)
If DB::Query(_db, "SELECT title, body FROM posts WHERE slug = ? AND published = 1")
  If DB::NextRow(_db)
    title$ = DB::GetStr(_db, 0)
    body$  = DB::GetStr(_db, 1)
  EndIf
  DB::Done(_db)
EndIf

; Parameterized INSERT
DB::BindStr(_db, 0, name)
DB::BindStr(_db, 1, email)
DB::Exec(_db, "INSERT INTO contacts (name, email) VALUES (?, ?)")
```

Always call `DB::Done(_db)` after a `Query` to free the result set, even if
`NextRow` returns false.

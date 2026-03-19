# 02 — Project Structure

```
examples/massively/
  main.pb                    Entry point: all routes, handlers, DB init, app boot
  .env.example               Sample config (PORT, ADMIN_USER, ADMIN_PASS, MODE)
  Caddyfile                  Caddy reverse-proxy + static file server config
  README.md                  Ubuntu VM setup and compile guide
  db/
    blog.db                  Pre-seeded SQLite database (committed to repo)
  static/                    Massively theme assets (extracted from html5up-massively.zip)
    css/
      main.css               Massively theme styles
      fontawesome-all.min.css FontAwesome icons
      noscript.css           Fallback styles
    js/                      jQuery, ScrollEx, ScrollY, browser/breakpoints, main, util
    webfonts/                FontAwesome webfont files
    images/
      bg.jpg                 Hero background image
      overlay.png            Texture overlay
  templates/
    base.html                Public shell (nav, header, footer, scripts)
    index.html               Homepage: post list grid
    post.html                Single post with photo credit
    contact.html             Contact form
    contact_ok.html          Thank-you page
    404.html                 Not found page
    admin/
      base.html              Admin shell (Tabler CDN navbar + sidenav)
      dashboard.html         Stats: post count, unread contacts, quick links
      posts.html             All posts table (edit / delete actions)
      post_form.html         Create + Edit form (shared via form_action variable)
      contacts.html          Contact submissions table with read/unread status
  walk-through/
    01-introduction.md  through  10-ubuntu-deploy.md
```

## Key file: main.pb

Everything lives in one file. This is intentional for an example — it makes
the full request lifecycle readable without jumping between files.

The structure inside `main.pb` is:

1. `EnableExplicit` + `XIncludeFile "../../src/PureSimple.pb"`
2. **Globals**: `_db`, `_tplDir`
3. **Helper procedures**: `SafeVal`, `SetSiteVars`, `PostsToStr`, etc.
4. **`InitDB()`**: 10 migrations (schema + seed data)
5. **Public handlers**: Index, Post, ContactGet, ContactPost, Health
6. **Admin handlers**: Dash, Posts, PostNew, PostCreate, PostEdit, PostUpdate, PostDelete, Contacts, ContactDelete
7. **App boot**: NewApp → Config → SetMode → InitDB → middleware → routes → Run

## Template directory

`_tplDir` is set to `"examples/massively/templates/"` so the app works when
run from the repository root. In production (`/opt/massively/`), change this
to `"templates/"`.

## Static files

Static files are **not** served by PureSimple. Caddy handles `/static/*`
directly from disk. This means:
- No file-read overhead in the PureBasic binary for CSS/JS
- Caddy's efficient static serving with proper cache headers
- Easy CDN offload later if needed

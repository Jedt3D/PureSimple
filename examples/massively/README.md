# Wild & Still

A production-quality nature photography blog built with **PureSimple**.

> *One frame. One story.* — Jedt Sitth

## What this example demonstrates

- **SQLite** with migration runner (10 migrations: schema + seed data)
- **Public routes**: post list, single post, contact form, health check
- **Admin**: RouterGroup + BasicAuth + full post CRUD + contact inbox
- **PureJinja templates**: Massively theme (public) + Tabler (admin)
- **Config**: `.env` file loading
- **Logging**: leveled logger

## Quick start (local)

### Prerequisites

- PureBasic 6.x
- The three PureSimple repos cloned side-by-side:
  ```
  parent/
    PureSimple/          ← this repo
    PureSimpleHTTPServer/
    pure_jinja/
  ```

### 1. Extract static assets

```bash
cd PureSimple
unzip examples/html5up-massively.zip "assets/*" "images/bg.jpg" "images/overlay.png" \
  -d /tmp/massively_raw
cp /tmp/massively_raw/assets/css/*      examples/massively/static/css/
cp /tmp/massively_raw/assets/js/*       examples/massively/static/js/
cp /tmp/massively_raw/assets/webfonts/* examples/massively/static/webfonts/
cp /tmp/massively_raw/images/bg.jpg     examples/massively/static/images/
cp /tmp/massively_raw/images/overlay.png examples/massively/static/images/
```

*(The static assets are pre-extracted in the repository — this step is only needed after a fresh clone.)*

### 2. Configure

```bash
cp examples/massively/.env.example examples/massively/.env
# Edit .env if desired (defaults work for local testing)
```

### 3. Compile and run

```bash
export PUREBASIC_HOME="/Applications/PureBasic.app/Contents/Resources"  # macOS
# export PUREBASIC_HOME="/opt/purebasic"                                 # Linux

$PUREBASIC_HOME/compilers/pbcompiler examples/massively/main.pb -o massively_app
./massively_app
```

### 4. Test

```bash
curl http://localhost:8080/health               # {"status":"ok"}
curl http://localhost:8080/                     # HTML — post list
curl http://localhost:8080/post/herons-patience # HTML — single post
curl http://localhost:8080/contact              # HTML — contact form
curl http://localhost:8080/admin/ -u admin:changeme  # Admin dashboard
```

## Admin access

- URL: `http://localhost:8080/admin/`
- Credentials: `admin` / `changeme` (set in `.env`)

## Routes

### Public

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Post list |
| GET | `/post/:slug` | Single post |
| GET | `/contact` | Contact form |
| POST | `/contact` | Submit contact form |
| GET | `/health` | Health check (JSON) |

### Admin (BasicAuth required)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/admin/` | Dashboard |
| GET | `/admin/posts` | All posts table |
| GET | `/admin/posts/new` | Create post form |
| POST | `/admin/posts/new` | Create post |
| GET | `/admin/posts/:id/edit` | Edit post form |
| POST | `/admin/posts/:id/edit` | Save post changes |
| POST | `/admin/posts/:id/delete` | Delete post |
| GET | `/admin/contacts` | Contact inbox |
| POST | `/admin/contacts/:id/delete` | Delete contact message |

## Static files

In development, static files at `/static/*` need to be served by something.
Options:
- Run Caddy locally with the provided `Caddyfile` (adjust to `:80`)
- Use `npx serve` or any static file server pointing at `examples/massively/`
- Or configure PureSimpleHTTPServer to serve `/static/*` from disk

In production, Caddy handles `/static/*` directly. See `Caddyfile` and
`walk-through/09-static-and-caddy.md`.

## Walk-through

Step-by-step explanations in `walk-through/`:

1. Introduction & architecture
2. Project structure
3. Database schema & migrations
4. Public routes & handlers
5. PureJinja templates
6. Contact form (POST binding, PRG)
7. Admin basics (groups, BasicAuth)
8. Admin CRUD (create, edit, delete)
9. Static files & Caddy config
10. Ubuntu deployment guide

## Database

`db/blog.db` is committed with five seed posts and site settings.
The migration runner creates it fresh if it doesn't exist.

## Credits

### Theme
[Massively](https://html5up.net/massively) by HTML5 UP (@ajlkn) — licensed under the
[Creative Commons Attribution 3.0 Unported (CCA 3.0)](https://creativecommons.org/licenses/by/3.0/)
licence. Free for personal and commercial use with attribution.

### Admin UI
[Tabler](https://tabler.io/) — MIT licence.

### Photography
All post photos are from [Pexels](https://www.pexels.com/) and licensed under the
[Pexels Licence](https://www.pexels.com/license/) (free for personal and commercial use).

| Post | Photographer | URL |
|------|-------------|-----|
| The Heron's Patience | Pixabay | [pexels.com/photo/158251](https://www.pexels.com/photo/158251/) |
| Doi Inthanon in the Mist | Johannes Plenio | [pexels.com/photo/2559941](https://www.pexels.com/photo/2559941/) |
| Rain Season Macro | Pixabay | [pexels.com/photo/931177](https://www.pexels.com/photo/931177/) |
| Fireflies Over the Rice Fields | Aleksey Kuprikov | [pexels.com/photo/1108572](https://www.pexels.com/photo/1108572/) |
| The Last Light at Phi Phi | Humphrey Muleba | [pexels.com/photo/3601425](https://www.pexels.com/photo/3601425/) |

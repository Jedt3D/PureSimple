# 01 — Introduction

## What we're building

**Wild & Still** is a production-quality nature photography blog that demonstrates the complete PureSimple stack. It is the "reference application" for the framework — the equivalent of the Gin Gonic todo app or the Rails Getting Started blog, but compiled to a single native binary with zero runtime dependencies.

```
Browser → Caddy (TLS, /static/*) → PureSimple binary (dynamic routes) → SQLite
```

### Stack overview

| Layer | Technology | Role |
|-------|-----------|------|
| HTTP listener | PureSimpleHTTPServer | Accept connections, handle TLS, compression |
| Router | PureSimple Router | Radix trie, `:param`, groups |
| Templates | PureJinja | Jinja2-compatible, compiled in |
| Database | SQLite (built-in) | Posts, contacts, site settings |
| Static files | Caddy | CSS, JS, webfonts served directly from disk |
| Admin UI | Tabler (CDN) | Clean dashboard without bundlers |

### Blog identity

- **Name**: Wild & Still
- **Author**: Jedt Sitth
- **Tagline**: *One frame. One story.*
- **Theme**: HTML5 UP Massively (CCA 3.0 license)
- **Content**: Five long-form essays on nature photography in Thailand

### What this walk-through covers

| Step | Topic |
|------|-------|
| 01 | Introduction (this file) |
| 02 | Project structure |
| 03 | Database schema and migrations |
| 04 | Public routes and handlers |
| 05 | PureJinja templates |
| 06 | Contact form (POST binding, redirect) |
| 07 | Admin basics (groups, BasicAuth) |
| 08 | Admin CRUD for posts |
| 09 | Static files and Caddy config |
| 10 | Ubuntu deployment guide |
